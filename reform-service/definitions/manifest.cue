import "encoding/yaml"
import "strings"

"manifest": {
	type: "component"
	annotations: {}
	labels: {}
	description: "K8S Object."
	attributes: {}
}
template: {
	o: strings.Replace(parameter.object, "\r", " ", -1)
	output: yaml.Unmarshal(o)
	
	parameter: {
		object: string
	}
}
