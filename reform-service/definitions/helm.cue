import (
	"strconv"
	"strings"
)

helm: {
  type: "component"
	annotations: {}
	labels: {}
	description: "Describes services deployed via Helm"
  attributes: {
		workload: {
			definition: {
				apiVersion: "helm.toolkit.fluxcd.io/v2beta1"
				kind:       "HelmRelease"
			}
			type: "helmreleases.helm.toolkit.fluxcd.io"
		}
		status: {
			healthPolicy: #"""
				isHealth: len(context.output.status.conditions) != 0 && context.output.status.conditions[0]["status"]=="True"
				"""#
		}
	}
}

template: {
  // define helm release
  output: {
    apiVersion: "helm.toolkit.fluxcd.io/v2beta1"
    kind:       "HelmRelease"
    metadata: {
      name:      context.name
      namespace: context.namespace
      labels: {
        "application.deploy.reform/component": context.name
				"application.deploy.reform/componentType": "helm"
        "app.kubernetes.io/name": context.name
        "app.kubernetes.io/managed-by": "reform-deploy"
      }
    }
    spec: {
      chart: {
        spec: {
          chart:    parameter.helm.chart
          version:  parameter.helm.version
          sourceRef: {
            kind:      "HelmRepository"
            name:      parameter.helm.repository.name
            namespace: parameter.helm.repository.namespace
          }
        }
      }
      interval: parameter.helm.interval
      if parameter.helm.values != _|_ {
				values: parameter.helm.values
			}
      timeout: "10m0s"
      install: {
        remediation: {
          retries: 3
        }
      }
      upgrade: {
        remediation: {
          retries: 3
          remediateLastFailure: false
        }
      }
    }
  }

  parameter: {
    helm: {
      // +usage=The Repository URL for the Helm chart
      url: string
      // +usage=The Helm chart to deploy
      chart: string
      // +usage=The version of the Helm chart to deploy
      version: *"*" | string
      // +usage=The interval at which to check for updates
      interval: *"30s" | string
      // +usage=The values to pass to the Helm chart
      values?: {
        ...
      }
      // +usage=The Helm repository to use
      repository: {
        // +usage=The name of the Helm repository to use
        name: string
        // +usage=The namespace of the Helm repository to use
        namespace: string
      }
    }
  }
}