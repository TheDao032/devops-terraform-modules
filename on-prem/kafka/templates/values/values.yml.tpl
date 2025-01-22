global:
  storageClass: ${storage_class_name}

heapOpts: -XX:InitialRAMPercentage=75 -XX:MaxRAMPercentage=75

sasl:
  client:
    users:
      - admin
    passwords: ${sasl_conf.client.password}

controller:
  # Kafka resource requests and limits
  # ref: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/
  # @param controller.resourcesPreset Set container resources according to one common preset (allowed values: none, nano, micro, small, medium, large, xlarge, 2xlarge). This is ignored if controller.resources is set (controller.resources is recommended for production).
  # More information: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_resources.tpl#L15
  resourcesPreset: "medium"
  # resources:
  #   requests:
  #     cpu: 2
  #     memory: 512Mi
  #   limits:
  #     cpu: 3
  #     memory: 1024Mi
  replicaCount: ${controller_conf.replica_count}
  automountServiceAccountToken: true
  controllerOnly: false
  heapOpts: -Xmx1024m -Xms1024m
  persistence:
    enabled: true
    storageClass: ${storage_class_name}
    mountPath: ${controller_conf.mount_path}
    size: ${controller_conf.size}
  autoscaling:
    hpa:
      enabled: ${controller_conf.hpa_active}
      minReplicas: ${controller_conf.min_replicas}
      maxReplicas: ${controller_conf.max_replicas}

#broker:
#  replicaCount: ${broker_conf.replica_count}
#  automountServiceAccountToken: true
#  heapOpts: -Xmx1024m -Xms1024m
#  persistence:
#    enabled: true
#    storageClass: ${storage_class_name}
#    mountPath: ${broker_conf.mount_path}
#    size: ${broker_conf.size}
#  autoscaling:
#    hpa:
#      enabled: ${broker_conf.hpa_active}
#      minReplicas: ${broker_conf.min_replicas}
#      maxReplicas: ${broker_conf.max_replicas}

externalAccess:
  autoDiscovery:
    enabled: true
  enabled: true
  controller:
    service:
      type: LoadBalancer

serviceAccount:
  create: true

rbac:
  create: true

metrics:
  jmx:
    enabled: true

kraft:
  enabled: true
  clusterId: kraft_cluster

zookeeper:
  enabled: false
