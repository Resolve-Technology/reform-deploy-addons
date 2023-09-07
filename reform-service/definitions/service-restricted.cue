
import (
	"strconv"
	"strings"
)

"service-restricted": {
	type: "component"
	annotations: {}
	labels: {}
	description: "Describes long-running, scalable, containerized services that have a stable network endpoint to receive external network traffic from customers."
	attributes: {
		workload: {
			definition: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
			}
			type: "deployments.apps"
		}
		status: {
			customStatus: #"""
				ready: {
					readyReplicas: *0 | int
				} & {
					if context.output.status.readyReplicas != _|_ {
						readyReplicas: context.output.status.readyReplicas
					}
				}
				message: "Ready:\(ready.readyReplicas)/\(context.output.spec.replicas)"
				"""#
			healthPolicy: #"""
				ready: {
					updatedReplicas:    *0 | int
					readyReplicas:      *0 | int
					replicas:           *0 | int
					observedGeneration: *0 | int
				} & {
					if context.output.status.updatedReplicas != _|_ {
						updatedReplicas: context.output.status.updatedReplicas
					}
					if context.output.status.readyReplicas != _|_ {
						readyReplicas: context.output.status.readyReplicas
					}
					if context.output.status.replicas != _|_ {
						replicas: context.output.status.replicas
					}
					if context.output.status.observedGeneration != _|_ {
						observedGeneration: context.output.status.observedGeneration
					}
				}
				_isHealth: (context.output.spec.replicas == ready.readyReplicas) && (context.output.spec.replicas == ready.updatedReplicas) && (context.output.spec.replicas == ready.replicas) && (ready.observedGeneration == context.output.metadata.generation || ready.observedGeneration > context.output.metadata.generation)
				isHealth: *_isHealth | bool
				if context.output.metadata.annotations != _|_ {
					if context.output.metadata.annotations["app.oam.dev/disable-health-check"] != _|_ {
						isHealth: true
					}
				}
				"""#
		}
	}
}
template: {
	componentType: "service-restricted"

  // define Deployment resouece
	output: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			labels: {
				"application.deploy.reform/component": context.name
				"application.deploy.reform/componentType": componentType
			}
		}
		spec: {	
			selector: matchLabels: {
				"app.oam.dev/component": context.name
			}

			template: {
				metadata: {
					labels: {
						"app.oam.dev/name":      context.appName
						"app.oam.dev/component": context.name
						"application.deploy.reform/component": context.name
						"application.deploy.reform/componentType": componentType
						"app.kubernetes.io/name": context.name
					}
				}

				spec: {
					containers: [{
						name:  context.name
						image: parameter.image
						if parameter["services"] != _|_ {
							ports: [ for s in parameter.containers {
								{
									containerPort: s.port
									protocol:      s.protocol
                  _name: "port-" + strconv.FormatInt(s.port, 10)
                  name: _name + "-" + strings.ToLower(s.protocol)
								}}]
						}

						if parameter["environmentVariables"] != _|_ {
							env: parameter.environmentVariables
						}

						if parameter["cpu"] != _|_ {
							resources: {
								limits: cpu:   parameter.cpu
								requests: cpu: parameter.cpu
							}
						}

						if parameter["memory"] != _|_ {
							resources: {
								limits: memory:   parameter.memory
								requests: memory: parameter.memory
							}
						}

						// policy for securityContext
						securityContext: {
							readOnlyRootFilesystem: true
							capabilities: {
								drop: ["ALL", "CAP_NET_RAW"]
							}
						}

						// policy for probe
						livenessProbe: {
							exec: {
								command: ["cat"]
							}
							initialDelaySeconds: 5
							periodSeconds: 5
						}
						readinessProbe: {
							exec: {
								command: ["cat"]
							}
							initialDelaySeconds: 5
							periodSeconds: 5
						}

					}]

					if parameter["imagePullSecrets"] != _|_ {
						imagePullSecrets: [ for v in parameter.imagePullSecrets {
							name: v
						},
						]
					}
				}
			}
		}
	}

  // define Service resource
	exposePorts: [
		if parameter.containers != _|_ for s in parameter.containers {
			port:       s.port
			targetPort: s.port
      _name: "port-" + strconv.FormatInt(s.port, 10)
      name: _name + "-" + strings.ToLower(s.protocol)
			if s.protocol != _|_ {
				protocol: s.protocol
			}
		},
	]
	outputs: {
		if len(exposePorts) != 0 {
			webserviceExpose: {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: context.name
					labels: {
						"application.deploy.reform/component": context.name
						"application.deploy.reform/componentType": componentType
					}
				}
				spec: {
					selector: "application.deploy.reform/component": context.name
					ports: exposePorts
					type:  "ClusterIP"
				}
			}
		}
	}

  // define Ingress resource
  outputs: {
    if parameter.containers != _|_ for s in parameter.containers {
			if s.expose != _|_ {
				ingress: {
					apiVersion: "networking.k8s.io/v1"
					kind:       "Ingress"
					metadata: {
						name: context.name
						labels: {
							"application.deploy.reform/component": context.name
							"application.deploy.reform/componentType": componentType
						}
					}
					spec: {
						rules: [{
							host: s.expose.domainHost
							http: {
								paths: [{
									path: s.expose.path
									pathType: s.expose.pathType
									backend: {
										service: {
											name: context.name
											port: number: s.port
										}
									}
								}]
							}
						}]
					}
				}
      }
    }
  }

	parameter: {
		// +usage=Which image would you like to use for your service
		// +short=i
		image: string

		// +usage=Specify image pull secrets for your service
		imagePullSecrets?: [...string]

		// +usage=Number of CPU units for the service, like `0.5` (0.5 CPU core), `1` (1 CPU core)
		cpu?: string

		// +usage=Specifies the attributes of the memory resource required for the container.
		memory?: string

		// +usage=Define arguments by using environment variables
		environmentVariables?: [...{
			// +usage=Environment variable name
			name: string
			// +usage=The value of the environment variable
			value?: string
			// +usage=Specifies a source the value of this var should come from
			valueFrom?: {
				// +usage=Selects a key of a secret in the pod's namespace
				secretKeyRef?: {
					// +usage=The name of the secret in the pod's namespace to select from
					name: string
					// +usage=The key of the secret to select from. Must be a valid secret key
					key: string
				}
				// +usage=Selects a key of a config map in the pod's namespace
				configMapKeyRef?: {
					// +usage=The name of the config map in the pod's namespace to select from
					name: string
					// +usage=The key of the config map to select from. Must be a valid secret key
					key: string
				}
			}
		}]

    // +usage=Define the services you want to expose from your container
    containers: [...{
      // +usage=Which port would you like the service to expose
      port: int
      // +usage=Which protocol would you like the service to expose
      protocol: *"TCP" | "UDP" | "SCTP"
			// +usage=Determine whether to expose the service
			expose?: {
				// +usage=Domain host name for exposed service
				domainHost?: string
				// +usage=The URL path you want customer traffic sent to
				path?: string
				// +usage=The type of path matching you want
				pathType?: *"Prefix" | "Exact" | "ImplementationSpecific"
			}
    }]
	}
}