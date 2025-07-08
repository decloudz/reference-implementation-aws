# Platform Services Database Setup - ${{ values.envName }}

This repository contains database initialization configurations for all platform services in the **${{ values.envName }}** environment.

## 🎯 Overview

This setup creates databases for the following services:

{% if values.createAuthDb %}
### Authentication Service
- **Database**: `authentication_db`
- **User**: `auth_service_user`
- **Secret**: `authentication-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createBdmDb %}
### BDM Service
- **Database**: `bdm_db`
- **User**: `bdm_service_user`
- **Secret**: `bdm-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createLoiDb %}
### LOI Service
- **Database**: `loi_db`
- **User**: `loi_service_user`
- **Secret**: `loi-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createIssueIngestionDb %}
### Issue Ingestion Service
- **Database**: `issue_ingestion_db`
- **User**: `issue_ingestion_user`
- **Secret**: `issue-ingestion-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createIssueDb %}
### Issue Service
- **Database**: `issue_db`
- **User**: `issue_service_user`
- **Secret**: `issue-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createSpreadsheetsDb %}
### Spreadsheets Service
- **Database**: `spreadsheets_db`
- **User**: `spreadsheets_service_user`
- **Secret**: `spreadsheets-service-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

{% if values.createPrimeCloudDb %}
### Prime Cloud
- **Database**: `prime_cloud_db`
- **User**: `prime_cloud_user`
- **Secret**: `prime-cloud-database`
- **Namespace**: `${{ values.namespace }}`
{% endif %}

## 🗂️ Repository Structure

```
manifests/
{% if values.createAuthDb %}├── authentication-service/
│   └── db-init-job.yaml         # Authentication service database job
{% endif %}
{% if values.createBdmDb %}├── bdm-service/
│   └── db-init-job.yaml         # BDM service database job
{% endif %}
{% if values.createLoiDb %}├── loi-service/
│   └── db-init-job.yaml         # LOI service database job
{% endif %}
{% if values.createIssueIngestionDb %}├── issue-ingestion-service/
│   └── db-init-job.yaml         # Issue ingestion service database job
{% endif %}
{% if values.createIssueDb %}├── issue-service/
│   └── db-init-job.yaml         # Issue service database job
{% endif %}
{% if values.createSpreadsheetsDb %}├── spreadsheets-service/
│   └── db-init-job.yaml         # Spreadsheets service database job
{% endif %}
{% if values.createPrimeCloudDb %}└── prime-cloud/
    └── db-init-job.yaml         # Prime Cloud database job
{% endif %}
```

## 🔧 Configuration

### PostgreSQL Cluster
- **Cluster Name**: `${{ values.postgresCluster }}`
- **Namespace**: `${{ values.postgresNamespace }}`
- **Environment**: `${{ values.envName }}`

### Database Initialization Jobs
Each service has its own database initialization job that:
1. Creates the database if it doesn't exist
2. Creates the database user with appropriate permissions
3. Generates a secure password
4. Creates a Kubernetes secret with connection details

## 📋 Usage in Service Deployments

Each service can access its database using the generated secret:

```yaml
spec:
  containers:
  - name: your-service
    env:
      - name: DATABASE_URL
        valueFrom:
          secretKeyRef:
            name: your-service-database  # Replace with actual service name
            key: database-url
      # Or individual components:
      - name: DB_HOST
        valueFrom:
          secretKeyRef:
            name: your-service-database
            key: host
      - name: DB_DATABASE
        valueFrom:
          secretKeyRef:
            name: your-service-database
            key: database
      - name: DB_USERNAME
        valueFrom:
          secretKeyRef:
            name: your-service-database
            key: username
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: your-service-database
            key: password
```

## 🔍 Monitoring and Troubleshooting

### Check Job Status
```bash
kubectl get jobs -n ${{ values.postgresNamespace }} | grep database-init-job
```

### Check Job Logs
```bash
kubectl logs job/database-init-job -n ${{ values.postgresNamespace }}
```

### Verify Secret Creation
```bash
kubectl get secrets -n ${{ values.namespace }} | grep database
```

### Test Database Connection
```bash
# Example for authentication service
kubectl run test-db --rm -it --image=postgres:15 -- psql $(kubectl get secret authentication-service-database -n ${{ values.namespace }} -o jsonpath='{.data.database-url}' | base64 -d)
```

## 🔐 Security Features

- **Secure Password Generation**: Each database user gets a unique, auto-generated password
- **Limited Permissions**: Database users have only necessary permissions, no superuser access
- **Cluster-Only Access**: Database connections are restricted to within the Kubernetes cluster
- **Secret Management**: All credentials are stored securely in Kubernetes secrets
- **RBAC Compliance**: Uses proper service accounts and cluster roles

## 🚀 ArgoCD Integration

Each database setup is managed by its own ArgoCD application:

{% if values.createAuthDb %}
- **Authentication Service**: `authentication-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createBdmDb %}
- **BDM Service**: `bdm-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createLoiDb %}
- **LOI Service**: `loi-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createIssueIngestionDb %}
- **Issue Ingestion Service**: `issue-ingestion-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createIssueDb %}
- **Issue Service**: `issue-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createSpreadsheetsDb %}
- **Spreadsheets Service**: `spreadsheets-service-database-setup-${{ values.envName }}`
{% endif %}
{% if values.createPrimeCloudDb %}
- **Prime Cloud**: `prime-cloud-database-setup-${{ values.envName }}`
{% endif %}

View all database applications in ArgoCD: [Database Applications](https://cnoe.localtest.me:8443/argocd/applications?search=database-setup-${{ values.envName }})

## 📞 Support

If you encounter issues with database setup:

1. Check the ArgoCD application status
2. Review the database initialization job logs
3. Verify PostgreSQL cluster health
4. Contact the platform team for assistance

---

*Generated by Backstage Platform Database Template*