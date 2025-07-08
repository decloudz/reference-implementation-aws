# Auth Service GitOps Template

This Backstage template deploys the authentication service using ArgoCD with a multi-source configuration for true GitOps workflow.

## Overview

The template creates:
- **Environment-specific Git branch** (e.g., `env/dev`, `env/staging`)
- **ArgoCD Application** with multi-source configuration
- **GitOps workflow** for configuration management

## Architecture

### Multi-Source Configuration

The ArgoCD application uses two sources:

1. **Values Source** (Git Repository)
   - Repository: Your GitOps repository 
   - Branch: `env/{environment}` (e.g., `env/dev`)
   - Contains: `values.yaml`, `application.yaml`, `catalog-info.yaml`

2. **Chart Source** (Helm Repository)
   - Repository: `https://charts.acx-sandbox.net`
   - Chart: `authentication-service`
   - Version: Configurable (default: 1.0.1)

### Repository Structure

```
gitops-repo/
├── env/dev/              # Development environment branch
│   ├── values.yaml       # Environment-specific Helm values
│   ├── application.yaml  # ArgoCD application definition
│   ├── catalog-info.yaml # Backstage catalog integration
│   └── README.md        # Environment documentation
├── env/staging/          # Staging environment branch
│   └── ...
└── env/prod/            # Production environment branch
    └── ...
```

## Usage

### 1. Create Environment

Use the Backstage template to create a new environment:
- Select environment name (dev, staging, prod)
- Configure image tag and chart version
- Template creates the environment branch with all necessary files

### 2. Deploy Application

Apply the ArgoCD application:
```bash
kubectl apply -f https://your-gitops-repo/raw/branch/env/{environment}/application.yaml
```

### 3. Modify Configuration

To update the deployment configuration:

```bash
# Clone the repository
git clone https://your-gitops-repo

# Switch to environment branch
git checkout env/dev

# Edit configuration
vi values.yaml

# Commit and push changes
git add .
git commit -m "Update dev environment configuration"
git push origin env/dev
```

ArgoCD will automatically detect changes and sync the deployment.

## Configuration

### Environment Variables

Key configuration options in `values.yaml`:

```yaml
# Application Image
image:
  registry: "ac-m2repo-prod.asset-control.com:5443"
  name: authentication-service
  tag: "latest"

# Environment-specific settings
namespace: dev
secretStoreName: "dev-auth-secret-store"
secman_name: "dev/ops360/auth-service"

# Service Configuration
service:
  type: ClusterIP
  port: 9000

# Ingress Configuration
ingress:
  enabled: true
  domain: domain.example.com
```

## Troubleshooting

### ArgoCD Multi-Source Issues

If you encounter errors like:
```
failed to generate manifest for source 1 of 2: rpc error: code = Unknown desc = failed to execute helm template command
```

**Common Causes:**

1. **Values File Not Found**
   - Ensure `values.yaml` exists in the environment branch root
   - Verify the branch name matches the ArgoCD application configuration

2. **Multi-Source Configuration Issues**
   - Check that the `ref: values` is correctly set in the application
   - Verify the `valueFiles` path is `$values/values.yaml`

3. **Repository Access**
   - Ensure ArgoCD has access to both the Helm repository and Git repository
   - Check repository URLs are correct and accessible

**Debugging Steps:**

1. **Verify Repository Structure**
   ```bash
   git checkout env/dev
   ls -la  # Should show values.yaml, application.yaml, etc.
   ```

2. **Check ArgoCD Application**
   ```bash
   kubectl get application auth-service-dev -n argocd -o yaml
   ```

3. **Manual Helm Template Test**
   ```bash
   # Test the Helm chart with your values
   helm template auth-service-dev \
     --repo https://charts.acx-sandbox.net \
     authentication-service \
     --version 1.0.1 \
     --values values.yaml
   ```

### Environment Isolation

Each environment has its own branch, providing:
- **Isolation**: Changes to one environment don't affect others
- **History**: Full Git history for each environment
- **Rollback**: Easy rollback using Git
- **Ownership**: Clear ownership per environment

## Best Practices

1. **Branch Protection**: Consider protecting environment branches
2. **Code Review**: Use pull requests for production changes
3. **Testing**: Test changes in development environments first
4. **Monitoring**: Monitor ArgoCD sync status
5. **Secrets Management**: Use external secret management (AWS Secrets Manager, Vault)

## Integration

### Backstage Catalog

The template automatically creates a `catalog-info.yaml` file for Backstage integration:
- Component registration
- Environment tracking
- Links to ArgoCD applications

### ArgoCD Projects

Consider organizing applications into ArgoCD projects for better governance:
- Separate projects per team/service
- RBAC policies
- Resource quotas 