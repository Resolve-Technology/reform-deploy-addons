import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "infrastructure-repository"
	alias:       "Infrastructure Repository"
	scope:       "project"
	description: "The repository for the infrastructure configuration"
	sensitive:   false
}

template: {
	templateType: "infrastructure-repository"

	output: {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      templateType + "-" + context.name
			namespace: context.namespace
			labels: {
				"configuration.deploy.reform/type": templateType
				"configuration.deploy.reform/identifier": context.name
				"app.kubernetes.io/managed-by": "reform-deploy"
			}
		}
		type: "Opaque"
		stringData: {
		}
	}
	outputs: {
		{
			vaultsecret: {
				apiVersion: "secrets.hashicorp.com/v1beta1"
				kind:       "VaultStaticSecret"
				metadata: {
					name:      context.name
					namespace: context.namespace
					labels: {
						"app.kubernetes.io/managed-by": "reform-deploy"
					}
				}
				spec: {
					mount: "kvv2"
					type: "kv-v2"
					path: "configurations/" + templateType + "/" + context.name
					hmacSecretData: true
					refreshAfter: "60s"
					destination: {
						annotations: {
							"repository.deploy.reform/name": context.name
						}
						labels: {
							"configuration.deploy.reform/type": templateType + "-data"
							"configuration.deploy.reform/identifier": context.name
						}
						create: true
						name: context.name
						type: "Opaque"
					}
				}
			},
		}
	}

	parameter: {
		secretData?: {
			// +usage=The token to authenticate with Terraform Cloud
			"terraform.tfrc": string
		}
	}
}