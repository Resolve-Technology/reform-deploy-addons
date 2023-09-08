import (
	"strconv"
	"strings"
)

"aws-subnet": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "subnet_arn"
		"outputs.1": "subnet_id"
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
	pathToTemplate: "./aws/subnet"

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
				if parameter.vpcId != _|_ && parameter.vpcId.valueFrom == _|_ { 
					name: parameter.vpcId.name
					value: parameter.vpcId.value
				},
				if parameter.subnetCidrBlock != _|_ && parameter.subnetCidrBlock.valueFrom == _|_ { 
					name: parameter.subnetCidrBlock.name
					value: parameter.subnetCidrBlock.value
				},
				if parameter.subnetName != _|_ && parameter.subnetName.valueFrom == _|_ { 
					name: parameter.subnetName.name
					value: parameter.subnetName.value
				}
			]
			varsFrom: [
				if parameter.vpcId != _|_ && parameter.vpcId.valueFrom != _|_ { 
					if parameter.vpcId.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.vpcId.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.vpcId.valueFrom.secretKeyRef.key
						]
					},
					if parameter.vpcId.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.vpcId.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.vpcId.valueFrom.configMapKeyRef.key
						]
					}
				},
				if parameter.subnetCidrBlock != _|_ && parameter.subnetCidrBlock.valueFrom != _|_ { 
					if parameter.subnetCidrBlock.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.subnetCidrBlock.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.subnetCidrBlock.valueFrom.secretKeyRef.key
						]
					},
					if parameter.subnetCidrBlock.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.subnetCidrBlock.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.subnetCidrBlock.valueFrom.configMapKeyRef.key
						]
					}
				},
				if parameter.subnetName != _|_ && parameter.subnetName.valueFrom != _|_ { 
					if parameter.subnetName.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.subnetName.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.subnetName.valueFrom.secretKeyRef.key
						]
					},
					if parameter.subnetName.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.subnetName.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.subnetName.valueFrom.configMapKeyRef.key
						]
					}
				},
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
		// +usage=The ID of the vpc
		vpcId: {
			// +usage=Environment variable name
			name: "vpc_id"
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
		// +usage=The cidr block of the subnet
		subnetCidrBlock: {
			// +usage=Environment variable name
			name: "subnet_cidr_block"
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
		subnetName: {
			// +usage=Environment variable name
			name: "subnet_name"
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
