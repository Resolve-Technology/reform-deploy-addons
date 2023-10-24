import (
	"strconv"
	"strings"
)

"aws-rds": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "db_endpoint"
		"outputs.1": "db_name",
		"outputs.2": "db_username",
		"outputs.3": "db_password"
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
	pathToTemplate: "./aws/rds"

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
			interval: "5m"
			path: pathToTemplate
			approvePlan: "auto"
			refreshBeforeApply: false
			alwaysCleanupRunnerPod: true
			destroyResourcesOnDeletion: true
			suspend: false
			serviceAccountName: "deploy-vela-core" // namepsaced, if deploy to other namespace, need to create service account
			cloud: {
				organization: parameter.terraformOrganization
				workspaces:
					name: "xxxxx"
			}
			sourceRef: {
				kind: "GitRepository"
				name: parameter.repoName
				namespace: parameter.repoNamespace
			}
			cliConfigSecretRef: {
				name: parameter.terraformCredential
				namespace: parameter.repoNamespace
			}
			vars: [
				if parameter.rdsName != _|_ && parameter.rdsName.valueFrom == _|_ { 
					name: parameter.rdsName.name
					value: parameter.rdsName.value
				}
			]
			varsFrom: [
				{
					kind: "Secret"
					name: parameter.terraformProviderCredential
				},
				if parameter.rdsName != _|_ && parameter.rdsName.valueFrom != _|_ { 
					if parameter.rdsName.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.rdsName.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.rdsName.valueFrom.secretKeyRef.key
						]
					},
					if parameter.rdsName.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.rdsName.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.rdsName.valueFrom.configMapKeyRef.key
						]
					}
				}
			]
    	}
	}

	parameter: {
		// +usage=The name of the rds
		rdsName: {
			// +usage=Environment variable name
			name: "rds_name"
			// +usage=The value of the environment variable
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
		// +usage=The name of the Terraform Organization
		terraformOrganization: *"ResolveTechnology" | string
		// +usage=The name of the infrastructure repository
		repoName: *"default-terraform" | string
		// +usage=The namespace of the infrastructure repository
		repoNamespace: *"deploy" | string
		// +usage=The credential for terraform
		terraformCredential: *"reslv-tfc" | string
		// +usage=The credential for terraform provider
		terraformProviderCredential: *"aws" | string
	}
}
