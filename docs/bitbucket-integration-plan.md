# Bitbucket Integration Plan for CNOE Reference Implementation

## Overview

This document outlines the plan to integrate Bitbucket support into the CNOE AWS Reference Implementation alongside the existing GitHub integration. The integration will support both Bitbucket Cloud and Bitbucket Server/Data Center.

## Current Architecture Analysis

### GitHub Integration (Current State)

#### Backstage Integration
- **Authentication Method**: GitHub App
- **Required Credentials**:
  - App ID, Client ID, Client Secret
  - Webhook URL and Secret
  - Private Key for authentication
- **Storage**: AWS Secrets Manager (`cnoe-ref-impl/github-app`)
- **Capabilities**: Repository operations, user authentication, catalog discovery, scaffolding

#### ArgoCD Integration
- **Authentication Method**: GitHub App
- **Required Credentials**:
  - App ID, Installation ID
  - Private Key for authentication
  - Repository URL
- **Storage**: AWS Secrets Manager (`cnoe-ref-impl/github-app`)
- **Capabilities**: GitOps operations, repository access for synchronization

## Proposed Bitbucket Integration

### Authentication Methods

#### For Backstage
- **Primary**: App Password (Bitbucket Cloud) / Personal Access Token (Bitbucket Server)
- **Alternative**: OAuth Consumer (for enhanced security)

#### For ArgoCD
- **Primary**: SSH Key (existing private key can be reused)
- **Alternative**: Personal Access Token / App Password

### Implementation Strategy

#### Phase 1: Core Integration Setup
1. **Configuration Enhancement**
   - Extend `config.yaml` to support multiple Git providers
   - Add Bitbucket-specific configuration parameters
   - Maintain backward compatibility with GitHub-only setups

2. **Secret Management**
   - Create new AWS Secrets Manager secret: `cnoe-ref-impl/bitbucket-app`
   - Extend existing External Secrets configurations
   - Support for multiple authentication methods

3. **Backstage Configuration**
   - Update Backstage configuration to support Bitbucket integration
   - Configure catalog discovery for Bitbucket repositories
   - Add Bitbucket-specific scaffolding templates

4. **ArgoCD Configuration**
   - Configure ArgoCD to work with Bitbucket repositories
   - Set up repository credentials for Bitbucket
   - Update repository templates and configurations

#### Phase 2: Enhanced Features
1. **Multi-Provider Support**
   - Support for simultaneous GitHub and Bitbucket integrations
   - Provider-specific template catalogs
   - Unified authentication experience

2. **Advanced Features**
   - Bitbucket Pipelines integration
   - Bitbucket-specific webhooks
   - Enhanced repository permissions management

## Detailed Implementation Plan

### 1. Configuration Updates

#### Extended `config.yaml`
```yaml
# Git provider configuration
git_providers:
  github:
    enabled: true
    repo:
      url: "https://github.com/decloudz/reference-implementation-aws"
      revision: "ref-impl-v2"
    integration_type: "github_app"
  bitbucket:
    enabled: true
    repo:
      url: "https://bitbucket.org/your-workspace/reference-implementation-aws"
      revision: "ref-impl-v2"
    integration_type: "app_password"  # or "ssh_key"
    workspace: "your-workspace"
    server_url: "https://bitbucket.org"  # For Bitbucket Server: https://your-bitbucket-server.com
```

#### Backward Compatibility
- Maintain existing `repo` configuration for GitHub
- Automatically detect and migrate to new format
- Fallback to GitHub-only mode if Bitbucket is not configured

### 2. Secret Management Strategy

#### New AWS Secrets Manager Structure
```json
{
  "cnoe-ref-impl/bitbucket-app": {
    "username": "your-bitbucket-username",
    "app_password": "your-app-password",
    "ssh_private_key": "-----BEGIN OPENSSH PRIVATE KEY-----\n...",
    "ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2E...",
    "server_url": "https://bitbucket.org",
    "workspace": "your-workspace"
  }
}
```

#### Enhanced External Secrets Configuration
```yaml
# New ExternalSecret for Bitbucket
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bitbucket-integration
  namespace: backstage
spec:
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: bitbucket-integration
    template:
      data:
        bitbucket-integration.yaml: |
          server: {{ .server_url }}
          username: {{ .username }}
          appPassword: {{ .app_password }}
```

### 3. Backstage Integration

#### Configuration Updates
```yaml
# In backstage configmap
integrations:
  github:
    - host: github.com
      apps:
        - $include: github-integration.yaml
  bitbucket:
    - host: bitbucket.org
      username: ${BITBUCKET_USERNAME}
      appPassword: ${BITBUCKET_APP_PASSWORD}
    # For Bitbucket Server
    - host: your-bitbucket-server.com
      token: ${BITBUCKET_TOKEN}

catalog:
  locations:
    # GitHub locations
    - type: url
      target: https://github.com/decloudz/reference-implementation-aws/blob/ref-impl-v2/templates/backstage/catalog-info.yaml
    # Bitbucket locations
    - type: url
      target: https://bitbucket.org/your-workspace/reference-implementation-aws/src/ref-impl-v2/templates/backstage/catalog-info.yaml
```

#### Template Updates
- Create Bitbucket-specific software templates
- Update existing templates to support both providers
- Add provider selection in template forms

### 4. ArgoCD Integration

#### Repository Configuration
```yaml
# ArgoCD Bitbucket repository secret
apiVersion: v1
kind: Secret
metadata:
  name: bitbucket-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
data:
  type: git
  url: https://bitbucket.org/your-workspace
  password: <base64-encoded-app-password>
  username: <base64-encoded-username>
```

#### SSH Key Support (Recommended)
```yaml
# ArgoCD Bitbucket SSH repository secret
apiVersion: v1
kind: Secret
metadata:
  name: bitbucket-repo-ssh-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
data:
  type: git
  url: git@bitbucket.org:your-workspace
  sshPrivateKey: <base64-encoded-ssh-private-key>
```

### 5. Installation Scripts Updates

#### Enhanced Setup Script
```bash
#!/bin/bash
# Enhanced create-config-secrets.sh

# Check for Bitbucket configuration
if [ -f "private/bitbucket-config.yaml" ]; then
    echo "Creating Bitbucket integration secrets..."
    
    # Create Bitbucket app secret
    aws secretsmanager create-secret \
        --name "cnoe-ref-impl/bitbucket-app" \
        --description "Bitbucket integration credentials for CNOE Reference Implementation" \
        --secret-string file://private/bitbucket-secrets.json
        
    # Configure SSH key for ArgoCD if provided
    if [ -f "private/bitbucket-ssh-key" ]; then
        echo "Configuring SSH key for Bitbucket..."
        # Additional SSH key setup
    fi
fi
```

## Security Considerations

### Authentication Security
1. **App Passwords**: Limited scope, can be easily rotated
2. **SSH Keys**: Secure for ArgoCD, existing key can be reused
3. **Secret Rotation**: Implement automated secret rotation
4. **Principle of Least Privilege**: Minimal required permissions

### Access Control
1. **Repository Access**: Read-only for ArgoCD synchronization
2. **Backstage Permissions**: Controlled by Bitbucket workspace permissions
3. **Webhook Security**: Secure webhook endpoints and validation

## Migration Strategy

### For New Installations
1. Choose Git provider during initial setup
2. Run provider-specific setup scripts
3. Configure secrets in AWS Secrets Manager
4. Deploy with selected provider configuration

### For Existing GitHub Installations
1. **Zero-downtime migration**: Add Bitbucket alongside GitHub
2. **Gradual transition**: Migrate repositories incrementally
3. **Rollback capability**: Maintain GitHub integration during transition
4. **Validation**: Thorough testing before full migration

## Testing Strategy

### Unit Tests
- Configuration validation
- Secret handling
- Provider detection logic

### Integration Tests
- End-to-end repository operations
- Webhook functionality
- Authentication flows

### Provider-Specific Tests
- Bitbucket Cloud integration
- Bitbucket Server integration
- SSH key authentication
- App password authentication

## Documentation Updates

### User Documentation
1. **Setup Guide**: Step-by-step Bitbucket integration setup
2. **Configuration Reference**: Complete configuration options
3. **Troubleshooting**: Common issues and solutions
4. **Migration Guide**: GitHub to Bitbucket migration steps

### Developer Documentation
1. **Architecture Changes**: Updated system architecture
2. **API Changes**: New configuration options
3. **Template Development**: Creating Bitbucket-compatible templates

## Implementation Timeline

### Phase 1: Foundation (Weeks 1-2)
- [ ] Configuration system updates
- [ ] Secret management implementation
- [ ] Basic Backstage integration
- [ ] ArgoCD repository configuration

### Phase 2: Core Features (Weeks 3-4)
- [ ] Template system updates
- [ ] Webhook integration
- [ ] Installation script updates
- [ ] Basic testing

### Phase 3: Advanced Features (Weeks 5-6)
- [ ] Multi-provider support
- [ ] Enhanced security features
- [ ] Comprehensive testing
- [ ] Documentation updates

### Phase 4: Validation & Release (Weeks 7-8)
- [ ] End-to-end testing
- [ ] Performance validation
- [ ] Security audit
- [ ] Documentation review
- [ ] Release preparation

## Success Criteria

### Functional Requirements
- ✅ Bitbucket repositories accessible via Backstage
- ✅ ArgoCD can synchronize from Bitbucket repositories
- ✅ Template scaffolding works with Bitbucket
- ✅ Webhook integration functional
- ✅ Multi-provider support (GitHub + Bitbucket)

### Non-Functional Requirements
- ✅ Zero-downtime migration capability
- ✅ Backward compatibility maintained
- ✅ Security standards met
- ✅ Performance impact minimal
- ✅ Comprehensive documentation

## Risk Assessment

### Technical Risks
- **Integration Complexity**: Mitigation through phased approach
- **Authentication Issues**: Extensive testing of auth methods
- **Performance Impact**: Load testing and optimization

### Operational Risks
- **Migration Disruption**: Gradual rollout strategy
- **Configuration Errors**: Validation and testing
- **Secret Management**: Automated rotation and monitoring

## Next Steps

1. **Approve the plan**: Review and approve the integration approach
2. **Set up development environment**: Create test Bitbucket workspace
3. **Begin implementation**: Start with Phase 1 tasks
4. **Continuous validation**: Test each component as it's developed
5. **Documentation**: Update docs alongside development

---

*This plan provides a comprehensive roadmap for integrating Bitbucket support into the CNOE Reference Implementation while maintaining existing GitHub functionality and ensuring a smooth transition path.*