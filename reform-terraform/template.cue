package main

output: {
	apiVersion: "core.oam.dev/v1beta1"
	kind:       "Application"
	metadata: {
		name: "reform-terraform"
		namespace: "vela-system"
	}
	spec: {
		components: [
			{
				type: "k8s-objects"
				name: "terraform-repository"
				properties: objects: [terraformRepo]
			},
			{
				type: "k8s-objects"
				name: "terraform-controller"
				properties: objects: [terraformController]
			}
		],
		workflow: steps: [
			{
				type: "apply-component"
				name: "deploy-terraform-repository"
				properties: component: "terraform-repository"
			},
			{
				type: "apply-component"
				name: "deploy-terraform-controller"
				properties: component: "terraform-controller"
				dependsOn: ["terraform-repository"]
			}
		]
	}
}
