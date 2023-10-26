import (
	"strconv"
	"strings"
)

"vault-database": {
	type: "component"
	annotations: {}
	labels: {
		"outputs.0": "vault_address"
		"outputs.1": "vault_namespace",
		"outputs.2": "vso_auth_method",
		"outputs.3": "vso_auth_mount",
		"outputs.4": "vso_auth_role",
		"outputs.5": "vso_auth_sa",
		"outputs.6": "vso_secret_mount",
		"outputs.7": "vso_secret_path"
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
			interval: "5m"
			path: parameter.repoDir
			approvePlan: "auto"
			refreshBeforeApply: false
			alwaysCleanupRunnerPod: true
			runnerTerminationGracePeriodSeconds: 300
			destroyResourcesOnDeletion: true
			suspend: false
			serviceAccountName: "deploy-vela-core" // namepsaced, if deploy to other namespace, need to create service account
			cloud: {
				organization: parameter.terraformOrganization
				workspaces:
					name: context.name
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
				if parameter.terraformVariables != _|_ for v in parameter.terraformVariables if v.value != _|_ { 
					name: v.name
					value: v.value
				}
			]
			varsFrom: [
				{
					kind: "Secret"
					name: parameter.vaultCredential
				},
				if parameter.terraformVariables != _|_ for v in parameter.terraformVariables if v.valueFrom != _|_ { 
					if v.valueFrom.secretKeyRef != _|_ {
						kind: "Secret"
						name: v.valueFrom.secretKeyRef.name
						varsKeys: [
							v.valueFrom.secretKeyRef.key
						]
					},
					if v.valueFrom.configMapKeyRef != _|_ {
						kind: "ConfigMap"
						name: v.valueFrom.configMapKeyRef.name
						varsKeys: [
							v.valueFrom.configMapKeyRef.key
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
		// +usage=The endpoint of AWS RDS 
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
		// +usage=The name of the Terraform Organization
		terraformOrganization: *"ResolveTechnology" | string
		// +usage=The credential for Terraform
		terraformCredential: *"reslv-tfc-token" | string
		// +usage=The name of the infrastructure repository
		repoName: *"default-terraform" | string
		// +usage=The namespace of the infrastructure repository
		repoNamespace: *"deploy" | string
		// +usage=The credential for HashiCorp Vault
		// +usage=The directory for Terraform 
		repoDir: *"./vault/database" | string
		vaultCredential: *"reslv-hashi-vault" | string
	}
}
