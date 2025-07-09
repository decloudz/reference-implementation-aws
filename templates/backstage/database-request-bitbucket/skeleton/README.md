# Database Configuration for ${{ serviceName }}

This directory contains the database configuration for the **${{ serviceName }}** service in the **${{ envName }}** environment.

## Database Details

- **Service**: ${{ serviceName }}
- **Environment**: ${{ envName }}
- **Database Name**: ${{ databaseName }}
- **Database User**: ${{ dbUser }}
- **PostgreSQL Cluster**: ${{ postgresCluster }}
- **Namespace**: ${{ namespace }}

## Files

- `secret.yaml` - Database connection credentials (populated by init job)
- `configmap.yaml` - Database connection configuration
- `README.md` - This documentation

## Usage in Your Service

### Environment Variables

Use the secret in your deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${{ serviceName }}
  namespace: ${{ namespace }}
spec:
  template:
    spec:
      containers:
      - name: ${{ serviceName }}
        env:
          # Full database URL (recommended)
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: database-url
          
          # Or individual components
          - name: DB_HOST
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: host
          - name: DB_PORT
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: port
          - name: DB_NAME
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: database
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: username
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: ${{ serviceName }}-database
                key: password
          
          # Non-sensitive config from ConfigMap
          - name: DB_ENVIRONMENT
            valueFrom:
              configMapKeyRef:
                name: ${{ serviceName }}-database-config
                key: environment
```

### Volume Mounts

You can also mount the secret as a volume:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${{ serviceName }}
spec:
  template:
    spec:
      containers:
      - name: ${{ serviceName }}
        volumeMounts:
        - name: db-config
          mountPath: /etc/database
          readOnly: true
      volumes:
      - name: db-config
        secret:
          secretName: ${{ serviceName }}-database
```

## Database Access

### Local Development

For local testing, you can port-forward to the PostgreSQL cluster:

```bash
# Port forward to PostgreSQL
kubectl port-forward svc/${{ postgresCluster }}-${{ envName }} 5432:5432 -n ${{ postgresNamespace }}

# Get database credentials
kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.database-url}' | base64 -d

# Connect with psql
psql $(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.database-url}' | base64 -d)
```

### Direct Connection

```bash
# Get individual connection details
DB_HOST=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.host}' | base64 -d)
DB_PORT=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.port}' | base64 -d)
DB_NAME=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.database}' | base64 -d)
DB_USER=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.username}' | base64 -d)
DB_PASS=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.password}' | base64 -d)

# Connect
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
```

## Database Schema Management

Your database user has the following permissions:
- CREATE, DROP, ALTER on tables in the database
- CONNECT to the database
- USAGE on schemas
- No superuser privileges (for security)

### Migrations

You can run database migrations using:

```bash
# Example with a migration job
kubectl run migration-job --rm -it --image=your-migration-image --env="DATABASE_URL=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.database-url}' | base64 -d)" -- migrate up
```

## Backup and Recovery

The database is automatically backed up as part of the PostgreSQL cluster backup strategy. For specific backup needs:

1. Contact the platform team for backup schedules
2. Use `pg_dump` for application-specific backups
3. Consider implementing application-level backup strategies

## Monitoring

Database metrics are available through the PostgreSQL cluster monitoring. Your service can also implement:

- Connection pool monitoring
- Query performance tracking
- Application-specific database metrics

## Troubleshooting

### Connection Issues

1. **Check secret exists**:
   ```bash
   kubectl get secret ${{ serviceName }}-database -n ${{ namespace }}
   ```

2. **Verify PostgreSQL cluster is running**:
   ```bash
   kubectl get pods -l app.kubernetes.io/name=postgresql -n ${{ postgresNamespace }}
   ```

3. **Check database user permissions**:
   ```bash
   kubectl run test-db --rm -it --image=postgres:15 --env="PGPASSWORD=$(kubectl get secret ${{ serviceName }}-database -n ${{ namespace }} -o jsonpath='{.data.password}' | base64 -d)" -- psql -h ${{ postgresCluster }}-${{ envName }}.${{ postgresNamespace }}.svc.cluster.local -U ${{ dbUser }} -d ${{ databaseName }} -c "\dt"
   ```

### Database Performance

1. **Monitor connections**:
   ```sql
   SELECT count(*) FROM pg_stat_activity WHERE datname = '${{ databaseName }}';
   ```

2. **Check for locks**:
   ```sql
   SELECT * FROM pg_locks WHERE database = (SELECT oid FROM pg_database WHERE datname = '${{ databaseName }}');
   ```

### Support

For database issues:
1. Check PostgreSQL cluster logs
2. Review your application database connection code
3. Contact the platform team for cluster-level issues
4. Use the Backstage catalog to find related services and documentation

## Related Resources

- PostgreSQL Cluster: [${{ postgresCluster }}-${{ envName }}](https://cnoe.localtest.me:8443/argocd/applications/argocd/${{ postgresCluster }}-${{ envName }})
- Service Repository: [https://cnoe.localtest.me:8443/gitea/giteaAdmin/${{ targetRepo }}](https://cnoe.localtest.me:8443/gitea/giteaAdmin/${{ targetRepo }})
- Backstage Catalog: [https://cnoe.localtest.me:8443/catalog](https://cnoe.localtest.me:8443/catalog)