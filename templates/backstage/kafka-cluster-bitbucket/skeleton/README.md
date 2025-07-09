# Kafka Cluster: ${{ values.clusterName }}

This repository contains the configuration for the Kafka cluster **${{ values.clusterName }}** deployed in the **${{ values.envName }}** environment.

## Cluster Information

- **Cluster Name**: ${{ values.clusterName }}
- **Environment**: ${{ values.envName }}
- **Namespace**: ${{ values.namespace }}
- **Kafka Version**: ${{ values.kafkaVersion }}
- **Kafka Brokers**: ${{ values.kafkaReplicas }}
- **ZooKeeper Nodes**: ${{ values.zookeeperReplicas }}

## Configuration

### Storage
- **Kafka Storage per Broker**: ${{ values.kafkaStorageSize }}
- **ZooKeeper Storage per Node**: ${{ values.zookeeperStorageSize }}
- **Storage Class**: ${{ values.storageClass }}

### Security
- **TLS Encryption**: {% if values.enableTLS %}✅ Enabled{% else %}❌ Disabled{% endif %}
- **SASL Authentication**: {% if values.enableAuthentication %}✅ Enabled{% else %}❌ Disabled{% endif %}

### Monitoring
- **Prometheus Metrics**: {% if values.enableMonitoring %}✅ Enabled{% else %}❌ Disabled{% endif %}

### Data Durability
- **Replication Factor**: ${{ values.replicationFactor }}
- **Min In-Sync Replicas**: ${{ values.minInSyncReplicas }}

## Connection Information

### Bootstrap Servers
```
# Plain connection (internal)
${{ values.clusterName }}-kafka-bootstrap.${{ values.namespace }}.svc.cluster.local:9092
```

{% if values.enableTLS %}
### TLS Connection
```
# TLS connection (internal)
${{ values.clusterName }}-kafka-bootstrap.${{ values.namespace }}.svc.cluster.local:9093
```
{% endif %}

## Usage Examples

### Creating a Topic
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: my-topic
  namespace: ${{ values.namespace }}
  labels:
    strimzi.io/cluster: ${{ values.clusterName }}
spec:
  partitions: 3
  replicas: ${{ values.replicationFactor }}
  config:
    retention.ms: 604800000  # 7 days
    segment.ms: 86400000     # 1 day
```

### Creating a User
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaUser
metadata:
  name: my-user
  namespace: ${{ values.namespace }}
  labels:
    strimzi.io/cluster: ${{ values.clusterName }}
spec:
  authentication:
    type: {% if values.enableAuthentication %}scram-sha-512{% else %}tls{% endif %}
  authorization:
    type: simple
    acls:
      - resource:
          type: topic
          name: my-topic
        operation: All
      - resource:
          type: group
          name: my-consumer-group
        operation: All
```

### Producer Example (Java)
```properties
bootstrap.servers=${{ values.clusterName }}-kafka-bootstrap.${{ values.namespace }}.svc.cluster.local:9092
key.serializer=org.apache.kafka.common.serialization.StringSerializer
value.serializer=org.apache.kafka.common.serialization.StringSerializer
acks=all
retries=2147483647
max.in.flight.requests.per.connection=5
enable.idempotence=true
{% if values.enableTLS %}
security.protocol=SSL
ssl.truststore.location=/path/to/kafka.client.truststore.jks
ssl.truststore.password=password
{% endif %}
```

### Consumer Example (Java)
```properties
bootstrap.servers=${{ values.clusterName }}-kafka-bootstrap.${{ values.namespace }}.svc.cluster.local:9092
key.deserializer=org.apache.kafka.common.serialization.StringDeserializer
value.deserializer=org.apache.kafka.common.serialization.StringDeserializer
group.id=my-consumer-group
auto.offset.reset=earliest
enable.auto.commit=false
{% if values.enableTLS %}
security.protocol=SSL
ssl.truststore.location=/path/to/kafka.client.truststore.jks
ssl.truststore.password=password
{% endif %}
```

## Monitoring

{% if values.enableMonitoring %}
### Prometheus Metrics
The cluster exposes JMX metrics via Prometheus exporters on:
- Kafka brokers: Port 9308
- ZooKeeper nodes: Port 9308
- Kafka Exporter: Port 9308

### Available Metrics
- `kafka_server_*` - Kafka broker metrics
- `zookeeper_*` - ZooKeeper metrics
- `kafka_*` - Topic and partition metrics

### Grafana Dashboards
Recommended dashboards for monitoring:
- Strimzi Kafka Dashboard
- ZooKeeper Dashboard
- Kafka Exporter Dashboard
{% endif %}

## Management

### Check Cluster Status
```bash
kubectl get kafka ${{ values.clusterName }} -n ${{ values.namespace }}
kubectl get pods -n ${{ values.namespace }}
```

### View Kafka Logs
```bash
kubectl logs ${{ values.clusterName }}-kafka-0 -n ${{ values.namespace }}
```

### View ZooKeeper Logs
```bash
kubectl logs ${{ values.clusterName }}-zookeeper-0 -n ${{ values.namespace }}
```

### Scale Cluster
```bash
# Edit the Kafka resource to change replicas
kubectl edit kafka ${{ values.clusterName }} -n ${{ values.namespace }}
```

## Troubleshooting

### Common Issues

1. **Cluster not ready**
   - Check operator status: `kubectl get pods -n strimzi-system`
   - Check cluster status: `kubectl describe kafka ${{ values.clusterName }} -n ${{ values.namespace }}`

2. **Storage issues**
   - Check PVC status: `kubectl get pvc -n ${{ values.namespace }}`
   - Verify storage class exists: `kubectl get storageclass`

3. **Network connectivity**
   - Verify service exists: `kubectl get svc -n ${{ values.namespace }}`
   - Check network policies if applicable

4. **Authentication failures**
   {% if values.enableAuthentication %}
   - Verify user credentials are correct
   - Check user resource status: `kubectl get kafkauser -n ${{ values.namespace }}`
   {% else %}
   - Check TLS certificates if using TLS
   {% endif %}

### Getting Help
- Check ArgoCD application: [Kafka Cluster App](https://cnoe.localtest.me:8443/argocd/applications/argocd/kafka-${{ values.clusterName }}-${{ values.envName }})
- View configuration: [Repository](https://cnoe.localtest.me:8443/gitea/giteaAdmin/kafka-${{ values.clusterName }}-${{ values.envName }})
- Contact platform team for support

## References

- [Strimzi Documentation](https://strimzi.io/docs/operators/latest/overview.html)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Kafka Configuration Reference](https://kafka.apache.org/documentation/#configuration)
- [Kubernetes Documentation](https://kubernetes.io/docs/)