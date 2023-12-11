import (
	"strconv"
	"strings"
	"encoding/json"
)

"config-mgmt": {
	type: "component"
	annotations: {}
	labels: {}
	description: "Configuration Management"
	attributes: {
		workload: {
			definition: {
				apiVersion: "v1"
				kind:       "Secret"
			}
			type: "secrets.core"
		}
		status: {
			healthPolicy: #"""
				isHealth: true
				"""#
		}
	}
}

template: {
	componentType: "config-mgmt"

	output: {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      strings.Join([parameter.type, parameter.name], "-")
			namespace: deploy
			labels: {
				"app.oam.dev/name":                        context.appName
				"app.oam.dev/component":                   context.name
				"application.deploy.reform/component":     context.name
				"application.deploy.reform/componentType": componentType
				"app.kubernetes.io/name":                  context.name
			}
		}
		data: {
			// Git Repository
			if parameter.type == "addon-repository" || parameter.type == "policy-repository" || parameter.type == "infrastructure-repository" || parameter.type == "application-repository" {
				provider:   parameter.data.provider
				repository: parameter.data.repository
			}

			// Helm | Docker Registry
			if parameter.type == "helm-registry" || parameter.type == "image-registry" {
				registry: parameter.secretData.registry
			}

			// AWS
			if parameter.type == "terraform-aws-provider" {
				AWS_ACCESS_KEY_ID:  parameter.secretData.AWS_ACCESS_KEY_ID
				AWS_DEFAULT_REGION: parameter.secretData.AWS_DEFAULT_REGION
			}

			// Custom Data
			if parameter.type == "custom" {
				custom_data: parameter.secretData.customData
			}

			// Secret Name of Configuration Secret Data
			secretData: parameter.name
		}
	}

	outputs: {
		secretData: {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      parameter.name
				namespace: deploy
				labels: {
					"app.oam.dev/name":                        context.appName
					"app.oam.dev/component":                   context.name
					"application.deploy.reform/component":     context.name
					"application.deploy.reform/componentType": componentType
					"app.kubernetes.io/name":                  context.name
				}
			}
			data: {
				// Username & Password
				if parameter.type == "addon-repository" || parameter.type == "policy-repository" || parameter.type == "infrastructure-repository" || parameter.type == "application-repository" || parameter.type == "helm-registry" {
					username: parameter.secretData.username
					password: parameter.secretData.username
				}

				// JSON Content
				if parameter.type == "image-registry" {
					".dockerconfigjson": parameter.secretData.jsonContent
				}
				if parameter.type == "terraform-cloud-credential" {
					"terraform.tfrc": parameter.secretData.jsonContent
				}

				// AWS
				if parameter.type == "terraform-aws-provider" {
					AWS_SECRET_ACCESS_KEY: parameter.secretData.AWS_SECRET_ACCESS_KEY
				}

				// Custom Secrets
				if parameter.type == "custom" {
					custom_data: parameter.secretData.customSecretData
				}
			}
		}
	}

	parameter: {
		// Name of Configuration
		name: string

		// Configuration Type
		type: string

		data?: {
			// Git | Helm | Docker
			provider?:   string
			repository?: string
			registry?:   string

			// Custom Data
			customData?: [string]: string

			// AWS
			AWS_ACCESS_KEY_ID?:  string
			AWS_DEFAULT_REGION?: string
		}

		secretData?: {
			// Username & Password
			username?: string
			password?: string

			// JSON Content
			jsonContent?: {}

			// Custom Secrets
			customSecretData?: [string]: string

			// AWS
			AWS_SECRET_ACCESS_KEY?: string
		}
	}
}
