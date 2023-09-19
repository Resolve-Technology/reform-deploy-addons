"k8s": {
	type: "component"
	annotations: {}
	labels: {}
	description: "K8S Object."
	attributes: {}
}
template: {
	output: parameter.objects[0]

	outputs: {
		for i, v in parameter.objects {
			if i > 0 {
				"objects-\(i)": v
			}
		}
	}
	parameter: {
		objects: [...{}]
	}
}
