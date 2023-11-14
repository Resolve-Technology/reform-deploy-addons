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
	// o: parameter.object
	output: parameter.object
	
	parameter: {
		object: {
        ...
      }
	}
}
