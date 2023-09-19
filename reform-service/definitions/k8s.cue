import "encoding/yaml"

"k8s": {
	type: "component"
	annotations: {}
	labels: {}
	description: "K8S Object."
	attributes: {}
}
template: {
	output: yaml.Unmarshal(parameter.objects)
	
	parameter: {
		objects: {}
	}
}
