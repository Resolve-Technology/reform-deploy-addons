import (
	"strconv"
	"strings"
)

"aws-s3": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "bucket_prefix"
		"outputs.1": "bucket_name"
		"outputs.2": "bucket_region"
		"outputs.3": "vault_root_access_key"
		"outputs.4": "vault_root_secret_key"
	}
	description: "Infrastructure component that can be deployed as a service"
	attributes: {
		workload: {
			definition: {
				apiVersion: "infra.contrib.fluxcd.io/v1alpha2"
				kind:       "Terraform"
			}
			type: "terraforms.infra.contrib.fluxcd.io"
		}
		status: {
			customStatus: #"""
				import "encoding/json"
				ready: {
					message: *"" | string
				} & {
					if context.output.status.conditions != _|_ {
						message: json.Marshal(context.output.status.conditions)
					}
				}
				message: ready.message
				"""#
			healthPolicy: #"""
				ready: {
					isHealth: *false | bool
				} & {
					if (context.output.status != _|_) && (context.output.status.conditions != _|_) {
						for condition in context.output.status.conditions {
							if condition.type == "Ready" {
								isHealth: condition.status == "True"
							}
						}
					}
				}
				isHealth: ready.isHealth
				"""#
		}
	}
}

template: {
	// define terraform resource
	output: {
		apiVersion: "infra.contrib.fluxcd.io/v1alpha2"
		kind:       "Terraform"
		metadata: {
			labels: {
				"application.deploy.reform/component": context.name
				"application.deploy.reform/componentType": "infrastructure"
				"app.kubernetes.io/managed-by": "reform-deploy"
			}
			name: context.name
			namespace: context.namespace
		}
		spec: {
			// Run on Terraform Cloud / Enterprise
			if parameter.terraformConfig.credential != _|_ && parameter.terraformConfig.organization != _|_ {
				cloud: {
					organization: parameter.terraformConfig.organization
					workspaces:
						name: context.name
				}
				cliConfigSecretRef: {
					name: parameter.terraformConfig.credential
					namespace: parameter.repositoryConfig.namespace
				}
			}
			// Run on Terraform OSS
			if parameter.terraformConfig.credential == _|_ || parameter.terraformConfig.organization == _|_ {
				storeReadablePlan: "human"
				tfstate: {
					forceUnlock: "auto"
				}
			}
			interval: "30m"
			path: parameter.repositoryConfig.directory
			approvePlan: "auto"
			refreshBeforeApply: false
			alwaysCleanupRunnerPod: true
			destroyResourcesOnDeletion: true
			suspend: false
			serviceAccountName: "deploy-vela-core" // namepsaced, if deploy to other namespace, need to create service account
			sourceRef: {
				kind: "GitRepository"
				name: parameter.repositoryConfig.name
				namespace: parameter.repositoryConfig.namespace
			}
			vars: [
				if parameter.terraformVariables != _|_ for v in parameter.terraformVariables if v.value != _|_ { 
					name: v.name
					value: v.value
				},
				{
					name: "context_name"
					value: context.name
				},
				{
					name: "context_appname"
					value: context.appName
				}
			]
			varsFrom: [
				{
					kind: "Secret"
					name: parameter.terraformProviderConfig.credential
					varsKeys: [
						"AWS_ACCESS_KEY_ID:aws_access_key",
						"AWS_SECRET_ACCESS_KEY:aws_secret_key",
						"AWS_DEFAULT_REGION:aws_region"
					]
				},
				if parameter.terraformVariables != _|_ for v in parameter.terraformVariables if v.valueFrom != _|_ { 
					if v.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: v.valueFrom.secretKeyRef.name
						varsKeys: [
							if v.name != v.valueFrom.secretKeyRef.key {
								"\(v.valueFrom.secretKeyRef.key):\(v.name)"
							}
							if v.name == v.valueFrom.secretKeyRef.key {
								v.valueFrom.secretKeyRef.key
							}
						]
					},
					if v.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: v.valueFrom.configMapKeyRef.name
						varsKeys: [
							if v.name != v.valueFrom.configMapKeyRef.key {
								"\(v.valueFrom.configMapKeyRef.key):\(v.name)"
							}
							if v.name == v.valueFrom.configMapKeyRef.key {
								v.valueFrom.configMapKeyRef.key
							}
						]
					}
				}
			]
			writeOutputsToSecret: {
				name: context.name + "-output"
				labels: {
					"app.kubernetes.io/managed-by": "reform-deploy"
					"secret.deploy.reform/type": "infra-output"
					"secret.deploy.reform/identifier": context.name
				}
			}
    	}
	}

	parameter: {
		terraformVariables?: [...{
			// +usage=Variable name
			name: string
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
		}]

		terraformConfig: {
			// +usage=The name of the Terraform Organization
			organization?: string
			// +usage=The credential for Terraform
			credential?: string
		}

		terraformProviderConfig: {
			// +usage=The credential for AWS provider
			credential: string
		}

		repositoryConfig: {
			// +usage=The name of the infrastructure repository
			name: string
			// +usage=The namespace of the infrastructure repository
			namespace: string
			// +usage=The directory for Terraform 
			directory: string
		}
	}
}
