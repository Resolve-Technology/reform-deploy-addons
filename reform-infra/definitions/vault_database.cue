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
	pathToTemplate: "./vault/database"

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
				if parameter.k8sNamespace != _|_ { 
					name: "k8s_namespace"
					value: parameter.k8sNamespace
				}
			]
			varsFrom: [
				{
					kind: "Secret"
					name: parameter.vaultCredential
					varsKeys: [
						"vault_address",
						"vault_auth_namespace",
						"vault_auth_mount",
						"vault_auth_username",
						"vault_auth_password"
					]
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
		rdsEndpoint: string
		// +usage=The database name of AWS RDS 
		rdsDatabase: string
		// +usage=The username of AWS RDS 
		rdsUsername: string
		// +usage=The password of AWS RDS 
		rdsPassword: string
		// +usage=The namespace for the application
		k8sNamespace: string
		// +usage=The name of the Terraform Organization
		terraformOrganization: *"ResolveTechnology" | string
		// +usage=The name of the infrastructure repository
		repoName: *"default-terraform" | string
		// +usage=The namespace of the infrastructure repository
		repoNamespace: *"deploy" | string
		// +usage=The credential for HashiCorp Vault
		vaultCredential: *"reslv-hashi-vault" | string
	}
}
