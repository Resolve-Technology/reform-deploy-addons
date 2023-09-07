import (
	"encoding/base64"
	"encoding/json"
	"strconv"
)

metadata: {
	name:        "cluster"
	alias:       "Cluster"
	scope:       "project"
	description: "Config information to connect cluster"
	sensitive:   false
}

template: {
  templateType: "cluster"

	output: {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:       templateType + "-" + context.name
			namespace: context.namespace
      labels: {
        "configuration.deploy.reform/type": templateType
        "configuration.deploy.reform/identifier": context.name
        "app.kubernetes.io/managed-by": "reform-deploy"
      }
		}
		type: "Opaque"
		stringData: {
			secretName: context.name
			clusterType: parameter.clusterType
		}
	}
	outputs: {
		{
			vaultsecret: {
				apiVersion: "secrets.hashicorp.com/v1beta1"
				kind:       "VaultStaticSecret"
				metadata: {
					name:      context.name
					namespace: context.namespace
					labels: {
						"app.kubernetes.io/managed-by": "reform-deploy"
					}
				}
				spec: {
					mount: "kvv2"
					type: "kv-v2"
					path: "configurations/" + templateType + "/" + context.name
					hmacSecretData: true
					refreshAfter: "60s"
					destination: {
						labels: {
							"configuration.deploy.reform/type":  templateType + "-data"
							"configuration.deploy.reform/identifier": context.name
              // oam cluster gateway uses this label to find the joined cluster
              "cluster.core.oam.dev/cluster-credential-type": parameter.clusterType
						}
						create: true
						name: context.name
            type: "Opaque"
					}
				}
			}
		}
	}

	parameter: {
		// +usage=The type of cluster
		clusterType: string
	}
}