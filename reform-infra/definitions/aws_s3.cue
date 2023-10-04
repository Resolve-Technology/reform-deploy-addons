import (
	"strconv"
	"strings"
)

"aws-s3": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "bucket_arn"
		"outputs.1": "bucket_id"
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
	pathToTemplate: "./aws/s3"

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
			serviceAccountName: "deploy-vela-core" // namepsaced, if deploy to other namespace, need to create service account
			sourceRef: {
			kind: "GitRepository"
			name: parameter.repoName
			namespace: parameter.repoNamespace
			}
			vars: [
				if parameter.bucketName != _|_ && parameter.bucketName.valueFrom == _|_ { 
					name: parameter.bucketName.name
					value: parameter.bucketName.value
				}
			]
			varsFrom: [
				if parameter.bucketName != _|_ && parameter.bucketName.valueFrom != _|_ { 
					if parameter.bucketName.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: parameter.bucketName.valueFrom.secretKeyRef.name
						varsKeys: [
							parameter.bucketName.valueFrom.secretKeyRef.key
						]
					},
					if parameter.bucketName.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: parameter.bucketName.valueFrom.configMapKeyRef.name
						varsKeys: [
							parameter.bucketName.valueFrom.configMapKeyRef.key
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
		// +usage=The name of the bucket
		bucketName: {
			// +usage=Environment variable name
			name: "bucket_name"
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
