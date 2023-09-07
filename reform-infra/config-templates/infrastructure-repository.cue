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
			},
      terraformrepo: {
        apiVersion: "source.toolkit.fluxcd.io/v1"
        kind:       "GitRepository"
        metadata: {
          name:      context.name
          namespace: context.namespace
          labels: {
            "app.kubernetes.io/managed-by": "reform-deploy"
            "configuration.deploy.reform/type": templateType + "-git"
            "configuration.deploy.reform/identifier": context.name
          }
        }
        spec: {
          interval: "1m"
          url: parameter.repository
          secretRef: {
            name: context.name
          }
        }
      }
		}
	}

	parameter: {
		// +usage=The repository URL
		repository: string
		// +usage=The provider of the repository
		provider: string

		secretData?: {
			// +usage=The username to authenticate with
			username: string
			// +usage=The password to authenticate with
			password: string
		}
	}
}