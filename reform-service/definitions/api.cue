import (
	"strconv"
	"strings"
)

api: {
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
				import "encoding/json"
				ready: {
					message: *"" | string
				} & {
					if context.output.status.conditions != _|_ {
						message: json.Marshal(context.output.status.conditions)
					}
				}
				message: ready.message
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
	componentType: "api"

	// define Deployment resouece
	output: {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			labels: {
				"application.deploy.reform/component":     context.name
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
						"app.oam.dev/name":                        context.appName
						"app.oam.dev/component":                   context.name
						"application.deploy.reform/component":     context.name
						"application.deploy.reform/componentType": componentType
						"app.kubernetes.io/name":                  context.name
					}
				}

				spec: {
					containers: [{
						name:  context.name
						image: parameter.image

						if parameter["environmentVariables"] != _|_ {
							env: [ for ev in parameter["environmentVariables"] {
								name: ev.name
								if ev.valueFrom != _|_ {
									if ev.vsoEnabled {
										valueFrom: {
											secretKeyRef: {
												name: strings.Join(["vso", ev.valueFrom.secretKeyRef.name], "-")
												key: ev.name
											}
										}
									}
									if !ev.vsoEnabled {
										valueFrom: ev.valueFrom
									}
								}
								if ev.valueFrom == _|_ && ev.value != _|_ {
									value: ev.value
								}
							}]
						}

						if parameter.containers != _|_ {
							ports: [ for s in parameter.containers {
								{
									containerPort: s.port
									protocol:      s.protocol
									_name:         "port-" + strconv.FormatInt(s.port, 10)
									name:          _name + "-" + strings.ToLower(s.protocol)
								}}]
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

						livenessProbe: {
							if parameter.livenessProbe.handler == "CMD" {
								exec: parameter.livenessProbe.exec
							}
							if parameter.livenessProbe.handler == "HTTP" {
								httpGet: parameter.livenessProbe.httpGet
							}
							if parameter.livenessProbe.handler == "TCPSocket" {
								tcpSocket: parameter.livenessProbe.tcpSocket
							}
							initialDelaySeconds: parameter.livenessProbe.initialDelaySeconds
							periodSeconds:       parameter.livenessProbe.periodSeconds
							timeoutSeconds:      parameter.livenessProbe.timeoutSeconds
							successThreshold:    parameter.livenessProbe.successThreshold
							failureThreshold:    parameter.livenessProbe.failureThreshold
						}
						readinessProbe: {
							if parameter.livenessProbe.handler == "CMD" {
								exec: parameter.livenessProbe.exec
							}
							if parameter.livenessProbe.handler == "HTTP" {
								httpGet: parameter.livenessProbe.httpGet
							}
							if parameter.livenessProbe.handler == "TCPSocket" {
								tcpSocket: parameter.livenessProbe.tcpSocket
							}
							initialDelaySeconds: parameter.livenessProbe.initialDelaySeconds
							periodSeconds:       parameter.livenessProbe.periodSeconds
							timeoutSeconds:      parameter.livenessProbe.timeoutSeconds
							successThreshold:    parameter.livenessProbe.successThreshold
							failureThreshold:    parameter.livenessProbe.failureThreshold
						}

						// securityContext: {
						// 	readOnlyRootFilesystem: true
						// 	capabilities: {
						// 		drop: ["ALL", "CAP_NET_RAW"]
						// 	}
						// }
					}]
				}
			}
		}
	}

	// define Service resource
	exposePorts: [
		if parameter.containers != _|_ for s in parameter.containers {
			port:       s.port
			targetPort: s.port
			_name:      "port-" + strconv.FormatInt(s.port, 10)
			name:       _name + "-" + strings.ToLower(s.protocol)
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
						"application.deploy.reform/component":     context.name
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

	define Ingress resource
	outputs: {
		if parameter.containers != _|_ for s in parameter.containers {
			ingress: {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name: context.name
					annotations: {
						kubernetes.io/tls-acme: 'true'
					}
					labels: {
						"application.deploy.reform/component":     context.name
						"application.deploy.reform/componentType": componentType
					}
				}
				spec: {
					rules: [{
						host: s.domainHost
						http: {
							paths: [{
								path:     s.path
								pathType: s.pathType
								backend: {
									service: {
										name: context.name
										port: number: s.port
									}
								}
							}]
						}
					}]
					tls: [{
						hosts: [
							s.domainHost
						]
						secretName: strings.Join([context.name, "tls"], "-")
					}]
				}
			}
		}
	}

	parameter: {
		// +usage=Which image would you like to use for your service
		// +short=i
		image: string

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
			vsoEnabled: bool
		}]

		// +usage=Number of CPU units for the service, like `0.5` (0.5 CPU core), `1` (1 CPU core)
		cpu?: string

		// +usage=Specifies the attributes of the memory resource required for the container.
		memory?: string

		// +usage=Define the services you want to expose from your container
		containers: [...{
			// +usage=Which port would you like the service to expose
			port: int
			// +usage=Which protocol would you like the service to expose
			protocol: *"TCP" | "UDP" | "SCTP"
			// +usage=Domain host name for exposed service
			domainHost?: string
			// +usage=The URL path you want customer traffic sent to
			path?: string
			// +usage=The type of path matching you want
			pathType?: *"Prefix" | "Exact" | "ImplementationSpecific"
		}]

		// +usage=Instructions for assessing whether the container is alive.
		livenessProbe: #HealthProbe

		// +usage=Instructions for assessing whether the container is in a suitable state to serve traffic.
		readinessProbe: #HealthProbe
	}

	#HealthProbe: {

		handler: *"TCPSocket" | "CMD" | "HTTP"

		// +usage=Instructions for assessing container health by executing a command. Either this attribute or the httpGet attribute or the tcpSocket attribute MUST be specified. This attribute is mutually exclusive with both the httpGet attribute and the tcpSocket attribute.
		exec?: {
			// +usage=A command to be executed inside the container to assess its health. Each space delimited token of the command is a separate array element. Commands exiting 0 are considered to be successful probes, whilst all other exit codes are considered failures.
			command: [...string]
		}

		// +usage=Instructions for assessing container health by executing an HTTP GET request. Either this attribute or the exec attribute or the tcpSocket attribute MUST be specified. This attribute is mutually exclusive with both the exec attribute and the tcpSocket attribute.
		httpGet?: {
			// +usage=The endpoint, relative to the port, to which the HTTP GET request should be directed.
			path: string
			// +usage=The TCP socket within the container to which the HTTP GET request should be directed.
			port:    int
			host?:   string
			scheme?: *"HTTP" | string
			httpHeaders?: [...{
				name:  string
				value: string
			}]
		}

		// +usage=Instructions for assessing container health by probing a TCP socket. Either this attribute or the exec attribute or the httpGet attribute MUST be specified. This attribute is mutually exclusive with both the exec attribute and the httpGet attribute.
		tcpSocket?: {
			// +usage=The TCP socket within the container that should be probed to assess container health.
			port: int
		}

		// +usage=Number of seconds after the container is started before the first probe is initiated.
		initialDelaySeconds: *0 | int

		// +usage=How often, in seconds, to execute the probe.
		periodSeconds: *10 | int

		// +usage=Number of seconds after which the probe times out.
		timeoutSeconds: *1 | int

		// +usage=Minimum consecutive successes for the probe to be considered successful after having failed.
		successThreshold: *1 | int

		// +usage=Number of consecutive failures required to determine the container is not alive (liveness probe) or not ready (readiness probe).
		failureThreshold: *3 | int
	}
}
