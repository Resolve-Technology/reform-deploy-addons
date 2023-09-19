import "encoding/yaml"
import "strings"

"k8s": {
	type: "component"
	annotations: {}
	labels: {}
	description: "K8S Object."
	attributes: {}
}
template: {
	o: strings.Replace(parameter.objects, "\r", " ", -1)
	output: yaml.Unmarshal(o)
	
	parameter: {
		objects: ""
	}
}
