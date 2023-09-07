import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "image-registry-secret"
	alias:       "Image Registry Secret"
	scope:       "project"
	description: "Config information to authenticate image registry"
	sensitive:   false
}

template: {
	templateType: "image-registry-secret"

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
			registry:   parameter.registry
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
						type: "kubernetes.io/dockerconfigjson"
					}
				}
			}
		}
	}

	parameter: {
		// +usage=The registry URL
		registry: string
		secretData?: {
			".dockerconfigjson": string
		}
	}
}