# Bitbucket Templates for Backstage

This document provides an overview of all the Bitbucket templates created for the CNOE Reference Implementation. These templates complement the existing GitHub templates and provide the same functionality using Bitbucket as the Git provider.

## Template Categories

### 1. Application Templates (from GitHub)
These templates create application repositories with full CI/CD integration:

- **`spring-boot-backend-bitbucket`** - Java Spring Boot backend with Maven and Docker
- **`nodejs-backend-bitbucket`** - Node.js/Express backend with TypeScript and Docker
- **`go-backend-bitbucket`** - Go backend with Gin framework and Docker
- **`quarkus-backend-bitbucket`** - Quarkus Java backend with Maven and Docker
- **`basic-bitbucket`** - Simple Kubernetes deployment

### 2. Infrastructure Templates (from Gitea)
These templates create infrastructure components with GitOps workflow:

- **`postgres-database-bitbucket`** - PostgreSQL database deployment using Bitnami chart
- **`kafka-cluster-bitbucket`** - Apache Kafka cluster with Strimzi operator
- **`database-request-bitbucket`** - Database provisioning request template

## Key Features

### Unified Authentication
All templates use the Bitbucket integration configured in the main system:
- **App Password Authentication** for Backstage API operations
- **SSH Key Authentication** for ArgoCD Git operations
- **Workspace-based** repository management

### GitOps Integration
Every template creates:
- **Bitbucket Repository** with application/infrastructure code
- **ArgoCD Application** for continuous deployment
- **Backstage Catalog Entry** for discovery and management

### Template Structure
Each template includes:
- **`template.yaml`** - Main template definition with Bitbucket actions
- **`skeleton/`** - Source code and configuration templates
- **`catalog-template/`** - Backstage catalog metadata

## Usage Examples

### Application Development
```yaml
# Create a Node.js backend
Template: nodejs-backend-bitbucket
Parameters:
  - name: my-api
  - workspace: my-team
  - description: User management API
```

### Infrastructure Management
```yaml
# Deploy PostgreSQL database
Template: postgres-database-bitbucket
Parameters:
  - repoName: user-db-gitops
  - workspace: my-team
  - envName: dev
  - databaseName: userdb
  - postgresVersion: "15"
  - storageSize: 20Gi
```

## Template Actions Used

### Bitbucket Actions
- **`publish:bitbucket`** - Creates new repository
- **`publish:bitbucket:pull-request`** - Creates pull request for updates
- **`catalog:register`** - Registers component in Backstage catalog

### ArgoCD Actions
- **`cnoe:create-argocd-app`** - Creates ArgoCD application
- **`argocd:create-multi-source-app`** - Creates multi-source ArgoCD application

## Repository Structure

### Application Templates
```
templates/backstage/
├── basic-bitbucket/
│   ├── template.yaml
│   └── skeleton/
│       ├── catalog-info.yaml
│       ├── manifests/
│       └── README.md
├── spring-boot-backend-bitbucket/
│   ├── template.yaml
│   └── skeleton/
│       ├── catalog-info.yaml
│       ├── src/
│       ├── pom.xml
│       ├── Dockerfile
│       └── manifests/
└── ...
```

### Infrastructure Templates
```
templates/backstage/
├── postgres-database-bitbucket/
│   ├── template.yaml
│   ├── skeleton/
│   ├── skeleton-values/
│   └── catalog-template/
├── kafka-cluster-bitbucket/
│   ├── template.yaml
│   ├── skeleton/
│   └── catalog-template/
└── ...
```

## Configuration Requirements

### Bitbucket Configuration
Templates require the following configuration in `config.yaml`:
```yaml
integrations:
  bitbucket:
    - host: bitbucket.org
      username: ${BITBUCKET_USERNAME}
      appPassword: ${BITBUCKET_APP_PASSWORD}
```

### ArgoCD Configuration
ArgoCD requires SSH key access for private repositories:
```yaml
# In argocd-bitbucket-app.yaml
spec:
  source:
    repoURL: git@bitbucket.org:workspace/repo.git
```

## Template Parameters

### Common Parameters
All templates include these common parameters:
- **`workspace`** - Bitbucket workspace name
- **`name`** - Application/component name
- **`description`** - Description of the component

### Application-Specific Parameters
Application templates also include:
- **`port`** - Application port number
- **`language`** - Programming language version
- **`framework`** - Framework-specific settings

### Infrastructure-Specific Parameters
Infrastructure templates include:
- **`environment`** - Target environment (dev/staging/prod)
- **`namespace`** - Kubernetes namespace
- **`resources`** - Resource requirements (CPU, memory, storage)

## Workflow Integration

### Development Workflow
1. **Create Application** - Use application template to create new service
2. **Develop & Test** - Use generated CI/CD pipeline
3. **Deploy** - ArgoCD automatically syncs changes

### Infrastructure Workflow
1. **Request Infrastructure** - Use infrastructure template
2. **Review & Approve** - Platform team reviews request
3. **Deploy** - ArgoCD provisions infrastructure
4. **Configure** - Update configuration via GitOps

## Template Comparison

| Feature | GitHub Templates | Bitbucket Templates |
|---------|------------------|---------------------|
| **Repository** | GitHub.com | Bitbucket.org |
| **Authentication** | GitHub App | App Password |
| **Actions** | `publish:github` | `publish:bitbucket` |
| **ArgoCD Auth** | HTTPS | SSH Key |
| **Pull Requests** | GitHub PR | Bitbucket PR |
| **Catalog Integration** | ✅ | ✅ |
| **ArgoCD Integration** | ✅ | ✅ |

## Best Practices

### Template Development
1. **Copy from Existing** - Start with GitHub/Gitea template
2. **Update Actions** - Change to Bitbucket actions
3. **Update URLs** - Change repository URLs
4. **Test Parameters** - Validate all parameter combinations

### Repository Management
1. **Consistent Naming** - Use lowercase, hyphen-separated names
2. **Workspace Organization** - Group related repositories
3. **Access Control** - Use Bitbucket workspace permissions
4. **Documentation** - Include comprehensive README files

### Security Considerations
1. **Private Repositories** - Use for sensitive infrastructure
2. **Access Reviews** - Regularly review repository access
3. **Credential Management** - Use secure credential storage
4. **Audit Logging** - Monitor repository access and changes

## Troubleshooting

### Common Issues
1. **Authentication Failures** - Check app password configuration
2. **Repository Creation** - Verify workspace permissions
3. **ArgoCD Sync** - Check SSH key configuration
4. **Catalog Registration** - Verify catalog-info.yaml syntax

### Debug Steps
1. **Check Logs** - Review Backstage and ArgoCD logs
2. **Test Credentials** - Verify Bitbucket authentication
3. **Validate Templates** - Check template syntax
4. **Manual Testing** - Test repository creation manually

## Migration Guide

### From GitHub to Bitbucket
1. **Update Configuration** - Enable Bitbucket integration
2. **Test Templates** - Verify all templates work
3. **Train Users** - Educate team on new workflows
4. **Monitor Usage** - Track template usage and issues

### From Gitea to Bitbucket
1. **Compare Features** - Identify feature differences
2. **Update Templates** - Modify Gitea templates for Bitbucket
3. **Test Infrastructure** - Verify infrastructure templates
4. **Update Documentation** - Update internal documentation

## Future Enhancements

### Planned Features
1. **Template Validation** - Automated template testing
2. **Template Versioning** - Version management for templates
3. **Custom Actions** - Bitbucket-specific actions
4. **Advanced Workflows** - Multi-step deployment workflows

### Integration Opportunities
1. **Bitbucket Pipelines** - CI/CD pipeline integration
2. **Jira Integration** - Issue tracking integration
3. **Confluence** - Documentation integration
4. **Bitbucket Insights** - Analytics and reporting

## Support

For issues with Bitbucket templates:
1. **Check Documentation** - Review this guide and template docs
2. **Search Issues** - Look for similar issues in the repository
3. **Contact Platform Team** - Reach out to platform team for support
4. **Create Issue** - Report bugs or request features

## Summary

The Bitbucket templates provide full feature parity with GitHub templates while supporting organizations that prefer Bitbucket for source control. They integrate seamlessly with the existing ArgoCD and Backstage infrastructure, providing a complete GitOps workflow for both application development and infrastructure management.

All templates follow the same patterns and conventions as their GitHub counterparts, making it easy for teams to switch between Git providers without changing their development workflows.