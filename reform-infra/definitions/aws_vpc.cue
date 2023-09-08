import (
	"strconv"
	"strings"
)

"aws-vpc": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "vpc_arn"
		"outputs.1": "vpc_id"
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
				ready: {
					message: *"" | string
				} & {
					if (context.output.status != _|_ && context.output.status.conditions != _|_ && len(context.output.status.conditions) > 0) {
						message: context.output.status.conditions[0].message
					}
				} & {
					if (context.output.status != _|_ && context.output.status.conditions != _|_) {
						for condition in context.output.status.conditions {
							if condition.type == "Ready" {
								_ready_message: condition.message
							}
						}
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
	pathToTemplate: "./aws/vpc"

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
			storeReadablePlan: "human"
			suspend: false
			serviceAccountName: "kubevela-vela-core" // namepsaced, if deploy to other namespace, need to create service account
			sourceRef: {
			kind: "GitRepository"
			name: parameter.repoName
			namespace: parameter.repoNamespace
			}
			vars: [
				if parameter.cidrBlock != _|_ && parameter.cidrBlock.valueFrom == _|_ { 
					name: parameter.cidrBlock.name
					value: parameter.cidrBlock.value
				},
				if parameter.vpcName != _|_ && parameter.vpcName.valueFrom == _|_ { 
					name: parameter.vpcName.name
					value: parameter.vpcName.value
				}
			]
			varsFrom: [
				if parameter.cidrBlock != _|_ && parameter.cidrBlock.valueFrom != _|_ { 
					if parameter.cidrBlock.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.cidrBlock.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.cidrBlock.valueFrom.secretKeyRef.key
						]
					},
					if parameter.cidrBlock.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.cidrBlock.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.cidrBlock.valueFrom.configMapKeyRef.key
						]
					}
				},
				if parameter.vpcName != _|_ && parameter.vpcName.valueFrom != _|_ { 
					if parameter.vpcName.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.vpcName.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.vpcName.valueFrom.secretKeyRef.key
						]
					},
					if parameter.vpcName.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.vpcName.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.vpcName.valueFrom.configMapKeyRef.key
						]
					}
				}
			]
			runnerPodTemplate: {
				spec: {
					envFrom: [
						{
							secretRef: {
								name: parameter.terraformProviderName
							}
						}
					]
				}
			}
			writeOutputsToSecret: {
				name: context.name + "-output"
				labels: {
					"app.kubernetes.io/managed-by": "reform-deploy"
					"secret.deploy.reform/type": "infra-output"
					"secret.deploy.reform/identifier": context.name
				}
			}
			tfstate: {
				forceUnlock: "auto"
			}
    }
	}

	parameter: {
		// +usage=The name of the infrastructure repository
		repoName: *"default-terraform" | string
		// +usage=The namespace of the infrastructure repository
		repoNamespace: *"deploy" | string
		// +usage=The name of the terraform provider
		terraformProviderName: *"aws" | string
		// +usage=The cidr block of the vpc
		cidrBlock: {
			// +usage=Environment variable name
			name: "cidr_block"
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
		// +usage=The name of the vpc
		vpcName: {
			// +usage=Environment variable name
			name: "vpc_name"
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
	}
}
