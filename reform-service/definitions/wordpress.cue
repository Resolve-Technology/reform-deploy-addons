import (
	"strconv"
	"strings"
)

"wordpress": {
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
				"""#
		}
	}
}
template: {
	componentType: "wordpress"

	mountsArray: [
		if parameter.volumeMounts != _|_ && parameter.volumeMounts.pvc != _|_ for v in parameter.volumeMounts.pvc {
			{
				mountPath: v.mountPath
				if v.subPath != _|_ {
					subPath: v.subPath
				}
				name: v.name
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.configMap != _|_ for v in parameter.volumeMounts.configMap {
			{
				mountPath: v.mountPath
				if v.subPath != _|_ {
					subPath: v.subPath
				}
				name: v.name
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.secret != _|_ for v in parameter.volumeMounts.secret {
			{
				mountPath: v.mountPath
				if v.subPath != _|_ {
					subPath: v.subPath
				}
				name: v.name
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.emptyDir != _|_ for v in parameter.volumeMounts.emptyDir {
			{
				mountPath: v.mountPath
				if v.subPath != _|_ {
					subPath: v.subPath
				}
				name: v.name
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.hostPath != _|_ for v in parameter.volumeMounts.hostPath {
			{
				mountPath: v.mountPath
				if v.subPath != _|_ {
					subPath: v.subPath
				}
				name: v.name
			}
		},
	]

	volumesList: [
		if parameter.volumeMounts != _|_ && parameter.volumeMounts.pvc != _|_ for v in parameter.volumeMounts.pvc {
			{
				name: v.name
				persistentVolumeClaim: claimName: v.claimName
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.configMap != _|_ for v in parameter.volumeMounts.configMap {
			{
				name: v.name
				configMap: {
					defaultMode: v.defaultMode
					name:        v.cmName
					if v.items != _|_ {
						items: v.items
					}
				}
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.secret != _|_ for v in parameter.volumeMounts.secret {
			{
				name: v.name
				secret: {
					defaultMode: v.defaultMode
					secretName:  v.secretName
					if v.items != _|_ {
						items: v.items
					}
				}
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.emptyDir != _|_ for v in parameter.volumeMounts.emptyDir {
			{
				name: v.name
				emptyDir: medium: v.medium
			}
		},

		if parameter.volumeMounts != _|_ && parameter.volumeMounts.hostPath != _|_ for v in parameter.volumeMounts.hostPath {
			{
				name: v.name
				hostPath: {
					path: v.path
				}
			}
		},
	]

	deDupVolumesArray: [
		for val in [
			for i, vi in volumesList {
				for j, vj in volumesList if j < i && vi.name == vj.name {
					_ignore: true
				}
				vi
			},
		] if val._ignore == _|_ {
			val
		},
	]

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
					if parameter.annotations != _|_ {
						annotations: parameter.annotations
					}
				}

				spec: {
					containers: [{
						name:  context.name
						image: parameter.image
						if parameter["ports"] != _|_ {
							ports: [ for v in parameter.ports {
								{
									containerPort: v.port
									protocol:      v.protocol
									if v.name != _|_ {
										name: v.name
									}
									if v.name == _|_ {
										_name: "port-" + strconv.FormatInt(v.port, 10)
										name:  *_name | string
										if v.protocol != "TCP" {
											name: _name + "-" + strings.ToLower(v.protocol)
										}
									}
								}}]
						}

						if parameter["environmentVariables"] != _|_ {
							env: [ for ev in parameter["environmentVariables"] {
								name: ev.name
								if ev.valueFrom != _|_ {
									valueFrom: ev.valueFrom
								} 
								if ev.valueFrom == _|_ && ev.value != _|_ {
									value: ev.value
								}
							}]
						}

						if parameter["volumes"] != _|_ && parameter["volumeMounts"] == _|_ {
							volumeMounts: [ for v in parameter.volumes {
								{
									mountPath: v.mountPath
									name:      v.name
								}}]
						}

						if parameter["volumeMounts"] != _|_ {
							volumeMounts: mountsArray
						}

					}]

					if parameter["imagePullSecrets"] != _|_ {
						imagePullSecrets: [ for v in parameter.imagePullSecrets {
							name: v
						},
						]
					}

					if parameter["volumes"] != _|_ && parameter["volumeMounts"] == _|_ {
						volumes: [ for v in parameter.volumes {
							{
								name: v.name
								if v.type == "pvc" {
									persistentVolumeClaim: claimName: v.claimName
								}
								if v.type == "configMap" {
									configMap: {
										defaultMode: v.defaultMode
										name:        v.cmName
										if v.items != _|_ {
											items: v.items
										}
									}
								}
								if v.type == "secret" {
									secret: {
										defaultMode: v.defaultMode
										secretName:  v.secretName
										if v.items != _|_ {
											items: v.items
										}
									}
								}
								if v.type == "emptyDir" {
									emptyDir: medium: v.medium
								}
							}
						}]
					}

					if parameter["volumeMounts"] != _|_ {
						volumes: deDupVolumesArray
					}
				}
			}
		}
	}

	exposePorts: [
		if parameter.ports != _|_ for v in parameter.ports if v.expose == true {
			port:       v.port
			targetPort: v.port
			if v.name != _|_ {
				name: v.name
			}
			if v.name == _|_ {
				_name: "port-" + strconv.FormatInt(v.port, 10)
				name:  *_name | string
				if v.protocol != "TCP" {
					name: _name + "-" + strings.ToLower(v.protocol)
				}
			}
			// if parameter.exposeType == "NodePort" {
			// 	nodePort: v.nodePort
			// }
			if v.protocol != _|_ {
				protocol: v.protocol
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
					selector: "app.oam.dev/component": context.name
					ports: exposePorts
					type:  parameter.exposeType
				}
			}
		}
	}

	parameter: {
		// +usage=Specify the annotations in the workload
		annotations?: [string]: string

		// +usage=Which image would you like to use for your service
		// +short=i
		image: string

		// +usage=Which ports do you want customer traffic sent to, defaults to 80
		ports?: [...{
			// +usage=Number of port to expose on the pod's IP address
			port: int
			// +usage=Name of the port
			name?: string
			// +usage=Protocol for port. Must be UDP, TCP, or SCTP
			protocol: *"TCP" | "UDP" | "SCTP"
			// +usage=Specify if the port should be exposed
			expose: *false | bool
			// // +usage=exposed node port. Only Valid when exposeType is NodePort
			// nodePort: int
		}]

		// +ignore
		// +usage=Specify what kind of Service you want. options: "ClusterIP", "NodePort", "LoadBalancer"
		exposeType: *"ClusterIP" | "LoadBalancer"

		// +usage=Define arguments by using environment variables
		environmentVariables?: [...{
			// +usage=Environment variable name
			name: string
			// +usage=The value of the environment variable
			value?: string
			// +usage=Specifies whether it is a secret value
			isSecret: *false | bool
			// +usage=Specifies whether it should be updated
			isUpdate: *false | bool
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

		volumeMounts?: {
			// +usage=Mount PVC type volume
			pvc?: [...{
				name:      string
				mountPath: string
				subPath?:  string
				// +usage=The name of the PVC
				claimName: string
			}]
			// +usage=Mount ConfigMap type volume
			configMap?: [...{
				name:        string
				mountPath:   string
				subPath?:    string
				defaultMode: *420 | int
				cmName:      string
				items?: [...{
					key:  string
					path: string
					mode: *511 | int
				}]
			}]
			// +usage=Mount Secret type volume
			secret?: [...{
				name:        string
				mountPath:   string
				subPath?:    string
				defaultMode: *420 | int
				secretName:  string
				items?: [...{
					key:  string
					path: string
					mode: *511 | int
				}]
			}]
			// +usage=Mount EmptyDir type volume
			emptyDir?: [...{
				name:      string
				mountPath: string
				subPath?:  string
				medium:    *"" | "Memory"
			}]
			// +usage=Mount HostPath type volume
			hostPath?: [...{
				name:      string
				mountPath: string
				subPath?:  string
				path:      string
			}]
		}
	}
}
