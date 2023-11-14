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
	output: yaml.Unmarshal(parameter.object)
	
	parameter: {
		object: [string]
	}
}
