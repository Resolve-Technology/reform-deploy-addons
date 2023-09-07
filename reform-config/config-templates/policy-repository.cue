import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "policy-repository"
	alias:       "Policy repository"
	scope:       "project"
	description: "Config information to authenticate policy repository"
	sensitive:   false
}

template: {
	templateType: "policy-repository"

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
			repository: parameter.repository
			provider: parameter.provider
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
              "repository.deploy.reform/url": parameter.repository
              "repository.deploy.reform/name": context.name
              "repository.deploy.reform/provider": parameter.provider
            }
						labels: {
							"configuration.deploy.reform/type": templateType + "-data"
							"configuration.deploy.reform/identifier": context.name
						}
						create: true
						name: context.name
						type: "kubernetes.io/basic-auth"
					}
				}
			}
		}
	}

	parameter: {
		// +usage=The repository URL
		repository: string
    // +usage=The repository provider
    provider: string

		secretData?: {
			// +usage=The username to authenticate with
			username: string
			// +usage=The password to authenticate with
			password: string
		}
	}
}