import (
	"strconv"
	"strings"
	"encoding/json"
)

"vault-vso-auth": {
	type: "component"
	annotations: {}
	labels: {}
	description: "HashiCorp Vault Secrets Operator - Vault Auth API"
	attributes: {
		workload: {
			definition: {
				apiVersion: "secrets.hashicorp.com/v1beta1"
				kind:       "VaultAuth"
			}
			type: "vaultauths.secrets.hashicorp.com"
		}
		status: {
			healthPolicy: #"""
				isHealth: context.output.status.valid
				"""#
		}
	}
}
template: {
	componentType: "vault-vso-auth"

	// define Deployment resouece
	output: {
		apiVersion: "secrets.hashicorp.com/v1beta1"
		kind:       "VaultAuth"
		metadata: {
			name: context.appName
			labels: {
				"app.oam.dev/name":                        context.appName
				"app.oam.dev/component":                   context.name
				"application.deploy.reform/component":     context.name
				"application.deploy.reform/componentType": componentType
				"app.kubernetes.io/name":                  context.name
			}
		}
		spec: {
			vaultConnectionRef: parameter.vaultConnectionRef
			method: parameter.method
			if parameter.headers != _|_ {
				headers: [ for v in parameter.headers {
					name:  v.name
					value: v.value
				}]
			}
		}
	}

	parameter: {
		vaultConnectionRef: string

		authMethod: {
			method: *"kubernetes" | "appRole" | "jwt" | "aws"
			mount: {
				// +usage=The value of the variable
				value?: string
				// +usage=Specifies a source the value of this var should come from
				valueFrom?: {
					// +usage=Selects a key of a secret in the pod's namespace
					secretKeyRef?: {
						// +usage=The name of the secret in the pod's namespace to select from
						name: string
						// +usage=The key of the secret to select from. Must be a valid secret key
						key: string
					}
					// +usage=Selects a key of a config map in the pod's namespace
					configMapKeyRef?: {
						// +usage=The name of the config map in the pod's namespace to select from
						name: string
						// +usage=The key of the config map to select from. Must be a valid secret key
						key: string
					}
				}
			}
			kubernetes?: {
				role: string
				serviceAccount: string
				audiences?: [...string]
				tokenExpirationSeconds?: int
			}
		}

		headers?: [string]: string
	}
}
