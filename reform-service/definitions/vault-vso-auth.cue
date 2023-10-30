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
			if type == "kubernetes" {
				mountValue?: string
				mountValueFrom?: {
					secretKeyRef?: {
						name: string
						key: string
					}
					configMapKeyRef?: {
						name: string
						key: string
					}
				}
				roleValue?: string
				roleValueFrom?: {
					secretKeyRef?: {
						name: string
						key: string
					}
					configMapKeyRef?: {
						name: string
						key: string
					}
				}
				serviceAccountValue?: string
				serviceAccountValueFrom?: {
					secretKeyRef?: {
						name: string
						key: string
					}
					configMapKeyRef?: {
						name: string
						key: string
					}
				}
			}
		}

		headers?: [string]: string
	}
}
