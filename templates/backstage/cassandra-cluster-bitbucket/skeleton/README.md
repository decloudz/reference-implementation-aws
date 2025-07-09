# Cassandra Cluster: ${{ values.clusterName }}

This repository contains the configuration for the Cassandra cluster **${{ values.clusterName }}** deployed in the **${{ values.envName }}** environment.

## Cluster Information

- **Cluster Name**: ${{ values.clusterName }}
- **Environment**: ${{ values.envName }}
- **Namespace**: ${{ values.namespace }}
- **Cassandra Version**: ${{ values.cassandraVersion }}
- **Datacenter**: ${{ values.datacenterName }}
- **Nodes**: ${{ values.clusterSize }}

## Configuration

### Storage
- **Storage per Node**: ${{ values.storageSize }}
- **Storage Class**: ${{ values.storageClass }}

### Resources
- **Heap Size**: ${{ values.heapSize }}
- **CPU Requests**: ${{ values.cpuRequests }}
- **Memory Requests**: ${{ values.memoryRequests }}

### Features
- **Authentication**: {% if values.enableAuthentication %}✅ Enabled (PasswordAuthenticator){% else %}❌ Disabled{% endif %}
- **Stargate API**: {% if values.enableStargate %}✅ Enabled{% else %}❌ Disabled{% endif %}
- **Reaper**: {% if values.enableReaper %}✅ Enabled{% else %}❌ Disabled{% endif %}
- **Medusa Backup**: {% if values.enableMedusa %}✅ Enabled{% else %}❌ Disabled{% endif %}

## Connection Information

### CQL Native Protocol
```
# Native CQL connection (internal)
${{ values.clusterName }}-${{ values.datacenterName }}-service.${{ values.namespace }}.svc.cluster.local:9042
```

{% if values.enableStargate %}
### Stargate API Gateway
```
# REST API
${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8082

# GraphQL API
${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8080
```
{% endif %}

## Usage Examples

### Creating a Keyspace
```sql
CREATE KEYSPACE IF NOT EXISTS my_app 
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  '${{ values.datacenterName }}': 3
};
```

### Creating a Table
```sql
USE my_app;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS users_username_idx ON users (username);
CREATE INDEX IF NOT EXISTS users_email_idx ON users (email);
```

{% if values.enableStargate %}
### REST API Examples

#### Create a Keyspace (REST)
```bash
curl -X POST \
  http://${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8082/v2/schemas/keyspaces \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "my_app",
    "replicas": 3
  }'
```

#### Insert Data (REST)
```bash
curl -X POST \
  http://${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8082/v2/keyspaces/my_app/users \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "email": "john@example.com",
    "created_at": "2024-01-01T00:00:00Z"
  }'
```

#### Query Data (REST)
```bash
curl -X GET \
  "http://${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8082/v2/keyspaces/my_app/users/550e8400-e29b-41d4-a716-446655440000"
```

### GraphQL API Examples

#### GraphQL Endpoint
```
http://${{ values.clusterName }}-${{ values.datacenterName }}-stargate-service.${{ values.namespace }}.svc.cluster.local:8080/graphql/my_app
```

#### Query Example
```graphql
query {
  users(value: {id: "550e8400-e29b-41d4-a716-446655440000"}) {
    values {
      id
      username
      email
      created_at
    }
  }
}
```

#### Mutation Example
```graphql
mutation {
  insertUsers(value: {
    id: "550e8400-e29b-41d4-a716-446655440001",
    username: "jane_doe",
    email: "jane@example.com",
    created_at: "2024-01-01T00:00:00Z"
  }) {
    value {
      id
      username
    }
  }
}
```
{% endif %}

### Java Driver Example
```java
// Add dependency: com.datastax.oss:java-driver-core:4.15.0

import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.cql.ResultSet;
import com.datastax.oss.driver.api.core.cql.Row;
import java.net.InetSocketAddress;

CqlSession session = CqlSession.builder()
    .addContactPoint(new InetSocketAddress("${{ values.clusterName }}-${{ values.datacenterName }}-service.${{ values.namespace }}.svc.cluster.local", 9042))
    .withLocalDatacenter("${{ values.datacenterName }}")
    {% if values.enableAuthentication %}
    .withAuthCredentials("cassandra", "cassandra")  // Change default password!
    {% endif %}
    .build();

// Execute queries
ResultSet rs = session.execute("SELECT * FROM my_app.users;");
for (Row row : rs) {
    System.out.println(row.getString("username"));
}

session.close();
```

### Python Driver Example
```python
# pip install cassandra-driver

from cassandra.cluster import Cluster
{% if values.enableAuthentication %}
from cassandra.auth import PlainTextAuthProvider
{% endif %}

{% if values.enableAuthentication %}
auth_provider = PlainTextAuthProvider(username='cassandra', password='cassandra')
cluster = Cluster(['${{ values.clusterName }}-${{ values.datacenterName }}-service.${{ values.namespace }}.svc.cluster.local'], 
                  auth_provider=auth_provider)
{% else %}
cluster = Cluster(['${{ values.clusterName }}-${{ values.datacenterName }}-service.${{ values.namespace }}.svc.cluster.local'])
{% endif %}

session = cluster.connect()

# Execute queries
rows = session.execute("SELECT * FROM my_app.users")
for row in rows:
    print(row.username)

cluster.shutdown()
```

## Management

### Check Cluster Status
```bash
kubectl get k8ssandracluster ${{ values.clusterName }} -n ${{ values.namespace }}
kubectl get pods -n ${{ values.namespace }}
```

### View Cassandra Logs
```bash
kubectl logs ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }}
```

{% if values.enableStargate %}
### View Stargate Logs
```bash
kubectl logs deployment/${{ values.clusterName }}-${{ values.datacenterName }}-stargate -n ${{ values.namespace }}
```
{% endif %}

{% if values.enableReaper %}
### View Reaper Logs
```bash
kubectl logs deployment/${{ values.clusterName }}-reaper -n ${{ values.namespace }}
```

### Access Reaper UI
```bash
kubectl port-forward service/${{ values.clusterName }}-reaper-service 8080:8080 -n ${{ values.namespace }}
# Access at http://localhost:8080/webui/
```
{% endif %}

{% if values.enableMedusa %}
### Backup Operations

#### Create a Backup
```bash
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- \
  medusa backup --backup-name my-backup-$(date +%Y%m%d-%H%M%S)
```

#### List Backups
```bash
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- \
  medusa list-backups
```

#### Restore from Backup
```bash
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- \
  medusa restore --backup-name my-backup-20240101-120000
```
{% endif %}

### Scale Cluster
```bash
# Edit the K8ssandraCluster resource to change size
kubectl edit k8ssandracluster ${{ values.clusterName }} -n ${{ values.namespace }}
```

### Monitor Cluster Health
```bash
# Check cluster status
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool status

# Check cluster info
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool info

# Check ring status
kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool describering
```

## Troubleshooting

### Common Issues

1. **Cluster not ready**
   - Check operator status: `kubectl get pods -n k8ssandra-operator`
   - Check cluster status: `kubectl describe k8ssandracluster ${{ values.clusterName }} -n ${{ values.namespace }}`

2. **Storage issues**
   - Check PVC status: `kubectl get pvc -n ${{ values.namespace }}`
   - Verify storage class exists: `kubectl get storageclass`

3. **Network connectivity**
   - Verify service exists: `kubectl get svc -n ${{ values.namespace }}`
   - Check network policies if applicable

4. **Authentication failures**
   {% if values.enableAuthentication %}
   - Default credentials are cassandra/cassandra - change immediately!
   - Create new users: `CREATE ROLE my_user WITH PASSWORD = 'secure_password' AND LOGIN = true;`
   {% else %}
   - Authentication is disabled - connections don't require credentials
   {% endif %}

{% if values.enableMedusa %}
5. **Backup failures**
   - Check S3 credentials: `kubectl get secret ${{ values.clusterName }}-medusa-s3-credentials -n ${{ values.namespace }} -o yaml`
   - Verify S3 endpoint connectivity from pods
   - Check Medusa logs: `kubectl logs ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -c medusa -n ${{ values.namespace }}`
{% endif %}

### Performance Tuning

#### Memory and CPU
- Monitor heap usage: `kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool info`
- Adjust heap size if needed by updating the K8ssandraCluster resource

#### Compaction
- Monitor compaction: `kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool compactionstats`
- Force compaction if needed: `kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool compact`

#### Repair Operations
{% if values.enableReaper %}
- Reaper automatically schedules repairs
- Monitor repair status in Reaper UI
{% else %}
- Manual repair: `kubectl exec -it ${{ values.clusterName }}-${{ values.datacenterName }}-default-sts-0 -n ${{ values.namespace }} -- nodetool repair`
{% endif %}

### Getting Help
- Check ArgoCD application: [Cassandra Cluster App](https://cnoe.localtest.me:8443/argocd/applications/argocd/cassandra-${{ values.clusterName }}-${{ values.envName }})
- View configuration: [Repository](https://cnoe.localtest.me:8443/gitea/giteaAdmin/cassandra-${{ values.clusterName }}-${{ values.envName }})
- Contact platform team for support

## References

- [K8ssandra Documentation](https://docs.k8ssandra.io/)
- [Apache Cassandra Documentation](https://cassandra.apache.org/doc/latest/)
- [Stargate Documentation](https://stargate.io/docs/stargate/1.0/quickstart/quickstart.html)
- [Reaper Documentation](http://cassandra-reaper.io/)
- [Medusa Documentation](https://github.com/thelastpickle/cassandra-medusa)
- [Kubernetes Documentation](https://kubernetes.io/docs/)