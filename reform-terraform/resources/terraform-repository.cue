package main

// Terraform Repository
terraformRepo: {
	apiVersion: "source.toolkit.fluxcd.io/v1beta2"
	kind: 		 "HelmRepository"
	metadata: {
		name:      "terraform-repository"
		namespace: "flux-system"
	}
	spec: {
    interval: "5m"
		url: "https://weaveworks.github.io/tf-controller"
	}
}
