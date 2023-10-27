import (
	"strconv"
	"strings"
	"encoding/json"
)

"vault-vso-connection": {
	type: "component"
	annotations: {}
	labels: {}
	description: "HashiCorp Vault Secrets Operator - Vault Connection API"
	attributes: {
		workload: {
			definition: {
				apiVersion: "secrets.hashicorp.com/v1beta1"
				kind:       "VaultConnection"
			}
			type: "vaultconnections.secrets.hashicorp.com"
		}
		status: {
			healthPolicy: #"""
				isHealth: context.output.status.valid=="true"
				"""#
		}
	}
}
template: {
	componentType: "vault-vso-connection"

	// define Deployment resouece
	output: {
		apiVersion: "secrets.hashicorp.com/v1beta1"
		kind:       "VaultConnection"
		metadata: {
			labels: {
				"app.oam.dev/name":                        context.appName
				"app.oam.dev/component":                   context.name
				"application.deploy.reform/component":     context.name
				"application.deploy.reform/componentType": componentType
				"app.kubernetes.io/name":                  context.name
			}
		}
		spec: {
			address: parameter.address
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
		address: string

		headers?: [string]: string

		tlsServerName?: string

		skipTLSVerify?: bool

		// caCert?: string
	}
}
