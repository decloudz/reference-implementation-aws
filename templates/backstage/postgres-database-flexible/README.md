# PostgreSQL Database (Flexible) Template

This Backstage template provides a flexible way to create PostgreSQL databases with support for multiple deployment types and scenarios.

## Overview

The flexible PostgreSQL database template supports four different deployment scenarios:

1. **Bitnami PostgreSQL (Helm Chart)** - Traditional PostgreSQL deployment using Bitnami Helm chart
2. **CloudNativePG Operator Cluster** - Database creation on existing CloudNativePG clusters
3. **External PostgreSQL (RDS/Managed)** - Connect to external PostgreSQL services
4. **Database Setup Only** - Create databases on existing PostgreSQL instances

## Features

- **Multi-Deployment Support**: Works with different PostgreSQL deployment types
- **Database Management**: Automated database and user creation
- **Flexible Connectivity**: Supports internal clusters and external services
- **Security**: Automatic secret generation and credential management
- **GitOps Integration**: Full ArgoCD workflow for all deployment types
- **Monitoring**: Built-in monitoring configuration where applicable

## Deployment Types

### 1. Bitnami PostgreSQL (Helm Chart)

**Use Case**: When you need a new PostgreSQL instance deployed via Helm chart

**Features**:
- Standalone or Primary-Replica architecture
- Configurable PostgreSQL versions (14, 15, 16)
- Persistent storage configuration
- Built-in monitoring and metrics
- Automated database and user creation

**Generated Resources**:
- PostgreSQL Helm deployment via ArgoCD
- Database initialization scripts
- Kubernetes secrets for credentials
- Service monitors for Prometheus

### 2. CloudNativePG Operator Cluster

**Use Case**: When you have an existing CloudNativePG cluster and want to create a new database

**Features**:
- Uses existing CloudNativePG cluster
- Automated database and user creation via Job
- Connection to primary (read-write) endpoint
- Integration with operator-managed credentials

**Generated Resources**:
- Database setup Job
- User creation and privilege assignment
- Connection secrets
- Catalog integration

### 3. External PostgreSQL (RDS/Managed)

**Use Case**: When connecting to external PostgreSQL services like AWS RDS, Google Cloud SQL, etc.

**Features**:
- SSL/TLS connection support
- Configurable host and port
- Integration with external credentials
- Database and user creation on external instance

**Generated Resources**:
- Database setup Job for external connection
- Admin credential secrets (manual configuration required)
- Application connection secrets
- Connection string generation

### 4. Database Setup Only

**Use Case**: When you have an existing PostgreSQL instance and just need to create databases/users

**Features**:
- Minimal resource creation
- Focus on database and user management
- Flexible privilege assignment
- Reusable for multiple scenarios

**Generated Resources**:
- Database setup Job
- User and privilege management
- Connection configuration

## Template Parameters

### Deployment Configuration
- **Deployment Type**: Choose from the four supported types
- **Database Name**: Name of the database to create
- **Environment**: Target environment (dev/staging/prod)
- **Namespace**: Kubernetes namespace for resources

### Type-Specific Configuration

#### Bitnami PostgreSQL
- **PostgreSQL Version**: 14, 15, or 16
- **Storage Size**: Persistent storage allocation
- **Architecture**: Standalone or Primary-Replica

#### CloudNativePG
- **Cluster Name**: Name of existing CloudNativePG cluster
- **Cluster Namespace**: Namespace of the cluster

#### External Database
- **Host**: PostgreSQL server hostname
- **Port**: PostgreSQL server port (default 5432)
- **SSL**: Enable SSL connections
- **Existing Database**: Database to connect to for setup

### Database User Configuration
- **Create User**: Whether to create a dedicated user
- **Username**: Database username
- **Privileges**: User privileges (ALL, Read/Write, Read-only)

### Advanced Options
- **Initialization Script**: Custom SQL script to run
- **Secret Creation**: Generate Kubernetes secrets
- **Secret Name**: Name for the credentials secret

## Usage Examples

### Example 1: New Bitnami PostgreSQL for Development

```yaml
deploymentType: bitnami-helm
databaseName: myapp
envName: dev
bitnamiPostgresVersion: "16"
bitnamiStorageSize: "10Gi"
bitnamiArchitecture: standalone
createDatabaseUser: true
databaseUser: myapp_user
```

### Example 2: Database on CloudNativePG Cluster

```yaml
deploymentType: cloudnative-operator
databaseName: analytics
envName: prod
cnpgClusterName: postgres-cluster-prod
cnpgClusterNamespace: prod-postgres
createDatabaseUser: true
databaseUser: analytics_user
userPrivileges: "ALL"
```

### Example 3: External RDS Database

```yaml
deploymentType: external-database
databaseName: webapp
envName: prod
externalHost: mydb.cluster-xyz.us-east-1.rds.amazonaws.com
externalPort: 5432
externalSSL: true
createDatabaseUser: true
databaseUser: webapp_user
```

### Example 4: Database Setup on Existing PostgreSQL

```yaml
deploymentType: database-setup-only
databaseName: reporting
envName: staging
externalHost: postgres.staging.local
externalPort: 5432
createDatabaseUser: true
databaseUser: reporting_user
userPrivileges: "SELECT,INSERT,UPDATE,DELETE"
```

## Generated Secrets

The template creates standardized Kubernetes secrets:

### Connection Credentials Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {databaseName}-db-credentials
data:
  host: <base64-encoded-host>
  port: <base64-encoded-port>
  database: <base64-encoded-database>
  username: <base64-encoded-username>
  password: <base64-encoded-password>
  sslmode: <base64-encoded-sslmode> # if applicable
```

### Connection String Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {databaseName}-db-credentials-connection
data:
  connection-string: <base64-encoded-postgresql-url>
```

## Application Integration

### Environment Variables
```bash
# Load from secret
POSTGRES_HOST=$(kubectl get secret myapp-db-credentials -o jsonpath='{.data.host}' | base64 -d)
POSTGRES_PORT=$(kubectl get secret myapp-db-credentials -o jsonpath='{.data.port}' | base64 -d)
POSTGRES_DB=$(kubectl get secret myapp-db-credentials -o jsonpath='{.data.database}' | base64 -d)
POSTGRES_USER=$(kubectl get secret myapp-db-credentials -o jsonpath='{.data.username}' | base64 -d)
POSTGRES_PASSWORD=$(kubectl get secret myapp-db-credentials -o jsonpath='{.data.password}' | base64 -d)

# Or use connection string
DATABASE_URL=$(kubectl get secret myapp-db-credentials-connection -o jsonpath='{.data.connection-string}' | base64 -d)
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:latest
          envFrom:
            - secretRef:
                name: myapp-db-credentials
          # Or use connection string
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-db-credentials-connection
                  key: connection-string
```

## Manual Setup Requirements

### External Database Setup
For external databases, you need to manually create the admin credentials secret:

```bash
kubectl create secret generic myapp-admin-credentials \
  --from-literal=username=admin \
  --from-literal=password=admin-password \
  -n myapp-namespace
```

### RDS/Cloud SQL Permissions
Ensure the admin user has the following permissions:
- `CREATE DATABASE`
- `CREATE USER`
- `GRANT` privileges
- Access to `pg_database` and `pg_user` system catalogs

## Troubleshooting

### Common Issues

1. **Database Setup Job Fails**
   ```bash
   kubectl logs job/myapp-setup-dev -n myapp-namespace
   kubectl describe job/myapp-setup-dev -n myapp-namespace
   ```

2. **Admin Credentials Missing**
   ```bash
   kubectl get secret myapp-admin-credentials -n myapp-namespace
   # Create if missing
   ```

3. **Connection Issues**
   ```bash
   # Test connection from setup job pod
   kubectl exec -it job/myapp-setup-dev -n myapp-namespace -- psql -h $PGHOST -U $PGUSER -d $PGDATABASE -c "SELECT 1"
   ```

4. **CloudNativePG Cluster Issues**
   ```bash
   kubectl get cluster -n postgres-namespace
   kubectl describe cluster cluster-name -n postgres-namespace
   ```

## Monitoring

### Bitnami PostgreSQL
- Automatic Prometheus metrics
- Service monitors for scraping
- Built-in PostgreSQL exporter

### CloudNativePG
- Operator-managed monitoring
- Cluster-level metrics
- Per-database monitoring setup

### External Databases
- Manual monitoring setup required
- Connection health checks via Jobs
- Application-level metrics recommended

## Security Considerations

- **Secrets Management**: Use proper RBAC for secret access
- **SSL/TLS**: Always enable for external connections
- **Least Privilege**: Use minimal required database privileges
- **Password Rotation**: Implement regular password updates
- **Network Policies**: Restrict database access at network level

## Best Practices

1. **Use CloudNativePG for production workloads**
2. **Enable SSL for all external connections**
3. **Create dedicated users with minimal privileges**
4. **Use separate databases for different applications**
5. **Implement proper backup strategies**
6. **Monitor connection pool usage**
7. **Regular security updates and patches**