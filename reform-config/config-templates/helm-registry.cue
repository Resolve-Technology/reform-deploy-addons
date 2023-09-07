import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "helm-registry"
	alias:       "Helm Registry"
	scope:       "project"
	description: "Config information to authenticate Helm registry"
	sensitive:   false
}

template: {
  templateType: "helm-registry"

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
			registry:   parameter.registry
		}
	}

  outputs: {
    helmRepo: {
      apiVersion: "source.toolkit.fluxcd.io/v1beta2"
      kind:       "HelmRepository"
      metadata: {
        name:      context.name
        namespace: context.namespace
        labels: {
          "configuration.deploy.reform/type": templateType + "-repo"
          "configuration.deploy.reform/identifier": context.name
          "app.kubernetes.io/managed-by": "reform-deploy"
        }
      }
      spec: {
        interval: "1m"
        url:      parameter.registry
				secretRef: {
					name: context.name
				}
      }
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
              "repository.deploy.reform/url": parameter.registry
              "repository.deploy.reform/name": context.name
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
		// +usage=The registry URL
		registry: string

		secretData?: {
			// +usage=The username to authenticate with
			username: string
			// +usage=The password to authenticate with
			password: string
		}
	}
}