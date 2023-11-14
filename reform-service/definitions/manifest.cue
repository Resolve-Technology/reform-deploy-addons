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
	output: strings.Replace(yaml.Unmarshal(parameter.object), "\r", " ", -1)
	
	parameter: {
		object: Structs
	}
}
