# CloudNativePG Operator

This directory contains the CloudNativePG operator deployment for managing PostgreSQL clusters in Kubernetes, following the same operator pattern used by HDFS, Strimzi, and Cassandra operators in this repository.

## Overview

CloudNativePG is a comprehensive, open-source Kubernetes operator for PostgreSQL designed to provide high availability, automated backup/recovery, and seamless operations for PostgreSQL databases in cloud-native environments.

## Features

- **High Availability**: Streaming replication with automated failover
- **Zero-Downtime Operations**: Rolling updates and maintenance
- **Point-in-Time Recovery**: Continuous backup with WAL archiving
- **Connection Pooling**: Built-in PgBouncer integration
- **Monitoring**: Prometheus metrics and alerting
- **Security**: TLS encryption and RBAC integration

## Deployment

### Operator Installation

The operator is deployed using ArgoCD with the following structure:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudnative-postgres-operator
  namespace: argocd
spec:
  destination:
    namespace: cnpg-system
    server: "https://kubernetes.default.svc"
  sources:
    - repoURL: 'https://cloudnative-pg.github.io/charts'
      targetRevision: 0.22.1
      chart: cloudnative-pg
      helm:
        valueFiles:
          - $values/values.yaml
    - repoURL: cnoe://cloudnative-postgres-operator/manifests
      targetRevision: HEAD
      ref: values
```

### Manual Installation

```bash
# Add Helm repository
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

# Install operator
kubectl create namespace cnpg-system
helm install cloudnative-pg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --values manifests/values.yaml
```

## Usage

### Via Backstage Template

Use the "Request PostgreSQL Cluster" template in Backstage to create new PostgreSQL clusters with a self-service interface:

1. Navigate to Backstage → Create Component
2. Select "Request PostgreSQL Cluster"
3. Fill in cluster configuration
4. Submit to create GitOps repository and ArgoCD application

### Manual Cluster Creation

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-postgres
  namespace: my-app
spec:
  instances: 3
  
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"

  bootstrap:
    initdb:
      database: myapp
      owner: myuser
      secret:
        name: postgres-credentials

  storage:
    size: 10Gi
    storageClass: standard

  monitoring:
    enabled: true

  backup:
    retentionPolicy: "30d"
    barmanObjectStore:
      destinationPath: "s3://postgres-backups/my-postgres"
      # ... backup configuration
```

## Examples

See the `examples/` directory for sample PostgreSQL cluster configurations:

- **examples/postgres-cluster.yaml**: Basic 3-node HA cluster with backup
- **Backstage templates**: Complete self-service templates with all options

## Backstage Integration

The operator integrates with Backstage through:

1. **Component Template**: `postgres-cluster/template.yaml`
2. **Catalog Integration**: Auto-registration of cluster components
3. **ArgoCD Integration**: Automatic GitOps deployment
4. **Monitoring Dashboard**: Links to cluster status and metrics

## Configuration

### Operator Configuration

Key operator settings in `manifests/values.yaml`:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

monitoring:
  enabled: true

webhook:
  port: 9443
```

### Cluster Configuration Options

- **Instances**: 1-9 PostgreSQL instances
- **PostgreSQL Versions**: 14, 15, 16, 17
- **Storage**: Configurable size and storage class
- **High Availability**: Streaming replication and failover
- **Backup**: S3-compatible object storage integration
- **Monitoring**: Prometheus metrics and alerting
- **Connection Pooling**: PgBouncer integration
- **Security**: TLS encryption and authentication

## Monitoring

PostgreSQL clusters include:

- **Prometheus Metrics**: Database and cluster metrics
- **Service Monitors**: Automatic Prometheus discovery
- **Alerting Rules**: Pre-configured alerts for common issues
- **Grafana Dashboards**: (requires separate configuration)

## Backup and Recovery

CloudNativePG provides:

- **Continuous Backup**: WAL streaming to object storage
- **Point-in-Time Recovery**: Restore to any point in time
- **Scheduled Backups**: Automated backup scheduling
- **Cross-Region Replication**: Disaster recovery capabilities

## Security

- **TLS Encryption**: All communications encrypted by default
- **RBAC Integration**: Kubernetes role-based access control
- **Secret Management**: Automatic credential rotation
- **Network Policies**: Pod-to-pod communication control

## Troubleshooting

### Common Issues

1. **Operator Not Ready**
   ```bash
   kubectl get pods -n cnpg-system
   kubectl logs -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
   ```

2. **Cluster Stuck in Setup**
   ```bash
   kubectl get cluster -A
   kubectl describe cluster <cluster-name> -n <namespace>
   ```

3. **Storage Issues**
   ```bash
   kubectl get pvc -n <namespace>
   kubectl describe pvc <pvc-name> -n <namespace>
   ```

### Useful Commands

```bash
# Check operator status
kubectl get pods -n cnpg-system

# List all PostgreSQL clusters
kubectl get cluster -A

# Check cluster status
kubectl get cluster <name> -n <namespace>

# View cluster details
kubectl describe cluster <name> -n <namespace>

# Connect to PostgreSQL
kubectl exec -it <pod-name> -n <namespace> -- psql -U <user> -d <database>

# Check backup status
kubectl get backup -A
```

## References

- [CloudNativePG Official Documentation](https://cloudnative-pg.io/documentation/)
- [CloudNativePG GitHub Repository](https://github.com/cloudnative-pg/cloudnative-pg)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Kubernetes Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

## Support

For issues related to:
- **Operator Deployment**: Check ArgoCD application status
- **Cluster Creation**: Review Backstage template parameters
- **PostgreSQL Issues**: Consult CloudNativePG documentation
- **Platform Issues**: Contact platform team