package main

// Terraform Controller
terraformController: {
	apiVersion: "helm.toolkit.fluxcd.io/v2beta1"
	kind:       "HelmRelease"
	metadata: {
		name:      "terraform-controller"
	}
	spec: {
		interval: "5m"
		chart: {
			spec: {
				chart: "tf-controller"
				version: "0.15.1"
				sourceRef: {
					kind: "HelmRepository"
					name: "terraform-repository"
				}
				interval: "5m"
			}
		}
	}
}

