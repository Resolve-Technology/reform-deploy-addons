import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "terraform-aws-provider"
	alias:       "Terraform AWS Provider"
	scope:       "project"
	description: "The AWS provider connection for the infrastructure configuration"
	sensitive:   false
}

template: {
	templateType: "terraform-aws-provider"

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
			secretName: context.name
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
						labels: {
							"configuration.deploy.reform/type": templateType + "-data"
							"configuration.deploy.reform/identifier": context.name
						}
						create: true
						name: context.name
						type: "Opaque"
            // secret data 
            // AWS_ACCESS_KEY_ID: string
            // AWS_DEFAULT_REGION: string
            // AWS_SECRET_ACCESS_KEY: string
					}
				}
			}
		}
	}

	parameter: {
		secretData?: {
			AWS_ACCESS_KEY_ID: string
			AWS_DEFAULT_REGION: string
			AWS_SECRET_ACCESS_KEY: string
		}
	}
}