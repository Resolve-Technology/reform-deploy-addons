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
			vaultConnectionRef: parameter.address
			if parameter.tlsServerName != _|_ {
				tlsServerName: parameter.tlsServerName
			}
			if parameter.headers != _|_ {
				headers: [ for v in parameter.headers {
					name:  v.name
					value: v.value
				}]
			}
			if parameter.skipTLSVerify != false {
				skipTLSVerify: parameter.skipTLSVerify
			}
		}
	}

	parameter: {
		vaultConnectionRef: *parameter.appName | string

		method: *kubernetes

		headers?: [string]: string
	}
}
