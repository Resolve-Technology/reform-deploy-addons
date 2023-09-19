import "encoding/yaml"

"k8s": {
	type: "component"
	annotations: {}
	labels: {}
	description: "K8S Object."
	attributes: {}
}
template: {
	output: yaml.Unmarshal(strings.Replace(parameter.objects, "\r", "", -1))
	
	parameter: {
		objects: {}
	}
}
