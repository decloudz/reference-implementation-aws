# ${{ chartName }} PostgreSQL Database GitOps Repository

This repository contains GitOps configuration for the **${{ chartName }}** PostgreSQL database across multiple environments using the Bitnami PostgreSQL Helm chart.

## Repository Structure

```
/
├── README.md                           # This file
├── catalog-info.yaml                   # Backstage catalog metadata
└── environments/                       # Environment-specific configurations
    ├── dev/                            # Development environment
    │   └── ${{ chartName }}/
    │       └── values.yaml            # Database values
    ├── staging/                       # Staging environment
    │   └── ${{ chartName }}/
    │       └── values.yaml            # Database values
    └── prod/                          # Production environment
        └── ${{ chartName }}/
            └── values.yaml            # Database values
```

## Environment Management

Each environment has its own directory under `environments/` with databases organized by environment:

- **`environments/{env}/{chart}/values.yaml`** - PostgreSQL values specific to that environment and database

## Current Configuration

- **Chart**: ${{ chartName }} v${{ chartVersion }}
- **Chart Repository**: ${{ chartRepo }}
- **Database**: ${{ databaseName }}
- **PostgreSQL Version**: ${{ postgresVersion }}
- **Initial Environment**: ${{ envName }}
- **Initial Namespace**: ${{ namespace }}
- **Storage**: ${{ storageSize }}

## ⚠️ IMPORTANT: Repository Usage Guidelines

**This is a GitOps configuration repository - NOT a PostgreSQL installation!**

### ✅ DO:
- Modify `values.yaml` files in environment directories
- Update database configuration settings
- Add new environment directories
- Document environment-specific settings
- Adjust resource limits and requests
- Configure backup settings

### ❌ DON'T:
- Add database schema files here (use init scripts in values.yaml)
- Store database dumps or backups in this repository
- Add application code or SQL scripts outside of init configuration
- Modify the PostgreSQL chart templates

All PostgreSQL templates come from the external Bitnami chart repository: `${{ chartRepo }}`

## Adding New Environments

1. **Via Backstage Template** (Recommended):
   - Use this template again with `createNewRepo: false`
   - Select a different environment name
   - The template will create a PR with the new environment

2. **Manual Process**:
   ```bash
   # Create new environment directory
   mkdir -p environments/new-env/${{ chartName }}
   
   # Copy from existing environment
   cp environments/${{ envName }}/${{ chartName }}/values.yaml environments/new-env/${{ chartName }}/
   
   # Edit configuration files for new environment
   # Commit and push changes
   ```

## Making Changes

### Update Database Configuration

1. Navigate to the appropriate environment directory
2. Edit `values.yaml` to modify database settings
3. Commit and push changes to the main branch
4. ArgoCD will automatically sync the changes

### Update Chart Version

1. Use the template again to update chart version
2. The template will update the ArgoCD application automatically

### Environment Promotion

To promote changes between environments:

1. Test changes in development first
2. Copy working configuration to staging
3. After validation, promote to production
4. Consider using automation for promotion workflows

## ArgoCD Multi-Source Configuration

This repository uses ArgoCD's multi-source feature:

1. **Chart Source**: External Bitnami PostgreSQL chart from `${{ chartRepo }}`
2. **Values Source**: Environment-specific values from this Git repository

The configuration in each ArgoCD application looks like:
```yaml
sources:
  - repoURL: ${{ chartRepo }}
    chart: ${{ chartName }}
    targetRevision: ${{ chartVersion }}
    helm:
      valueFiles:
        - $values/environments/ENV_NAME/${{ chartName }}/values.yaml
  - repoURL: https://cnoe.localtest.me:8443/gitea/giteaAdmin/${{ repoName }}
    targetRevision: main
    ref: values
```

## Database Access

After deployment, you can access the PostgreSQL database using:

### Get Database Credentials
```bash
# Get the postgres password
kubectl get secret ${{ chartName }}-ENV_NAME -n NAMESPACE -o jsonpath="{.data.postgres-password}" | base64 -d

# Get the application user password
kubectl get secret ${{ chartName }}-ENV_NAME -n NAMESPACE -o jsonpath="{.data.password}" | base64 -d
```

### Port Forward for Local Access
```bash
kubectl port-forward svc/${{ chartName }}-ENV_NAME 5432:5432 -n NAMESPACE
```

### Connect with psql
```bash
# Connect as postgres user
psql -h localhost -U postgres -d ${{ databaseName }}

# Connect as application user
psql -h localhost -U appuser -d ${{ databaseName }}
```

## Database Configuration

### Performance Tuning

The values.yaml includes optimized settings for:
- Connection limits
- Memory allocation
- Checkpoint settings
- WAL configuration
- Query optimization

### Security

- PostgreSQL runs as non-root user
- Pod security contexts enabled
- Network policies available
- Secrets management for passwords

### Backup

Backup configuration is available but disabled by default. To enable:

1. Edit `values.yaml` in your environment
2. Set `backup.enabled: true`
3. Configure backup schedule and storage

### Monitoring

Metrics are enabled by default and can be scraped by Prometheus:
- PostgreSQL metrics on port 9187
- Service monitor available for Prometheus Operator

## Monitoring

- **ArgoCD Dashboard**: https://cnoe.localtest.me:8443/argocd/applications
- **Git Repository**: https://cnoe.localtest.me:8443/gitea/giteaAdmin/${{ repoName }}
- **Backstage Component**: Available in the Backstage catalog

## Troubleshooting

### Database Not Starting

1. Check ArgoCD application status
2. Verify values.yaml syntax is valid YAML
3. Check resource limits and requests
4. Review PostgreSQL application logs
5. Verify storage class availability

### Connection Issues

1. Check service configuration
2. Verify network policies if enabled
3. Check secret generation
4. Validate database user permissions

### Performance Issues

1. Review resource allocation
2. Check PostgreSQL configuration parameters
3. Monitor connection usage
4. Review query performance

### Backup Issues

1. Verify backup configuration
2. Check storage availability
3. Review backup job logs
4. Validate RBAC permissions

## Support

For issues with this configuration:

1. Check ArgoCD application events and logs
2. Review Kubernetes events in the target namespace
3. Check PostgreSQL logs: `kubectl logs -l app.kubernetes.io/name=postgresql -n NAMESPACE`
4. Consult the Bitnami chart documentation at: ${{ chartRepo }}
5. Contact the platform team for assistance

## Links

- [Bitnami PostgreSQL Chart](${{ chartRepo }})
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [ArgoCD Applications](https://cnoe.localtest.me:8443/argocd/applications)
- [Backstage Catalog](https://cnoe.localtest.me:8443/catalog)

---

Generated by the Backstage PostgreSQL Database GitOps template.