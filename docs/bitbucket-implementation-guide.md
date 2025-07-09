# Bitbucket Integration Implementation Guide

## Overview

This guide provides step-by-step instructions and specific code changes needed to implement Bitbucket integration into the CNOE Reference Implementation.

## Prerequisites

1. **Bitbucket Workspace**: Access to a Bitbucket workspace (Cloud or Server)
2. **App Password**: Generated in Bitbucket with appropriate permissions
3. **SSH Key**: Optional but recommended for ArgoCD authentication
4. **AWS Secrets Manager**: Access to store Bitbucket credentials

## Implementation Steps

### Step 1: Configuration Schema Updates

#### 1.1 Enhanced `config.yaml` Schema

Create a new configuration structure that supports multiple Git providers:

```yaml
### Config for CNOE AWS Reference Implementation ###
# Source: "https://github.com/cnoe/reference-implementation-aws"

# Git providers configuration
git_providers:
  github:
    enabled: true
    repo:
      url: "https://github.com/decloudz/reference-implementation-aws"
      revision: "ref-impl-v2"
      basepath: "packages"
    integration_type: "github_app"
  
  bitbucket:
    enabled: true
    repo:
      url: "https://bitbucket.org/your-workspace/reference-implementation-aws"
      revision: "ref-impl-v2"
      basepath: "packages"
    integration_type: "app_password"  # Options: app_password, ssh_key
    workspace: "your-workspace"
    server_url: "https://bitbucket.org"  # For Bitbucket Server: https://your-bitbucket-server.com

# Backward compatibility - will be deprecated
repo: 
  url: "https://github.com/decloudz/reference-implementation-aws"
  revision: "ref-impl-v2"
  basepath: "packages"

# EKS cluster configuration
cluster_name: "cnoe-ref-impl"
auto_mode: "true"
region: "us-west-2"
domain: coe-emea.greshamcloud.com
route53_hosted_zone_id: Z01340051RWCTQLP0995Y
path_routing: "true"

# Primary Git provider for ArgoCD applications
primary_git_provider: "github"  # Options: github, bitbucket

tags:
  githubRepo: "github.com/cnoe-io/reference-implementation-aws"
  env: "dev"
  project: "cnoe"
```

#### 1.2 Configuration Migration Script

Create `scripts/migrate-config.sh`:

```bash
#!/bin/bash
# Migration script for config.yaml

CONFIG_FILE="config.yaml"
BACKUP_FILE="config.yaml.backup"

# Create backup
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Check if new format exists
if ! grep -q "git_providers:" "$CONFIG_FILE"; then
    echo "Migrating config.yaml to new format..."
    
    # Extract existing repo configuration
    REPO_URL=$(yq eval '.repo.url' "$CONFIG_FILE")
    REPO_REVISION=$(yq eval '.repo.revision' "$CONFIG_FILE")
    REPO_BASEPATH=$(yq eval '.repo.basepath' "$CONFIG_FILE")
    
    # Create new configuration structure
    yq eval ".git_providers.github.enabled = true" -i "$CONFIG_FILE"
    yq eval ".git_providers.github.repo.url = \"$REPO_URL\"" -i "$CONFIG_FILE"
    yq eval ".git_providers.github.repo.revision = \"$REPO_REVISION\"" -i "$CONFIG_FILE"
    yq eval ".git_providers.github.repo.basepath = \"$REPO_BASEPATH\"" -i "$CONFIG_FILE"
    yq eval ".git_providers.github.integration_type = \"github_app\"" -i "$CONFIG_FILE"
    yq eval ".primary_git_provider = \"github\"" -i "$CONFIG_FILE"
    
    echo "Migration completed. Backup saved as $BACKUP_FILE"
else
    echo "Config.yaml already in new format"
fi
```

### Step 2: Secret Management Implementation

#### 2.1 Enhanced External Secrets for Bitbucket

Create `packages/backstage/manifests/external-secrets-bitbucket.yaml`:

```yaml
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bitbucket-integration
  namespace: backstage
  annotations:
    argocd.argoproj.io/sync-wave: "-10"
spec:
  refreshInterval: "0"
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
  data:
  - secretKey: "server_url"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: server_url
  - secretKey: "username"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: username
  - secretKey: "app_password"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: app_password
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bitbucket-env-vars
  namespace: backstage
  annotations:
    argocd.argoproj.io/sync-wave: "-10"
spec:
  refreshInterval: "0"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: bitbucket-env-vars
    creationPolicy: "Merge"
    template:
      data:
        BITBUCKET_USERNAME: "{{ .username }}"
        BITBUCKET_APP_PASSWORD: "{{ .app_password }}"
        BITBUCKET_SERVER_URL: "{{ .server_url }}"
        BITBUCKET_WORKSPACE: "{{ .workspace }}"
  data:
  - secretKey: "username"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: username
  - secretKey: "app_password"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: app_password
  - secretKey: "server_url"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: server_url
  - secretKey: "workspace"
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: workspace
```

#### 2.2 ArgoCD Bitbucket Integration

Create `packages/argo-cd/manifests/argo-cd-bitbucket-app.yaml`:

```yaml
---
# Bitbucket App Password Secret for ArgoCD
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bitbucket-app-password
  namespace: argocd
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: bitbucket-app-password
    template:
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repo-creds
      data:
        type: git
        url: '{{ .repoURL }}'
        username: "{{ .username }}"
        password: "{{ .app_password }}"
  data:
  - secretKey: username
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: username
  - secretKey: app_password
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: app_password
  - secretKey: repoURL
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: server_url
---
# Bitbucket SSH Key Secret for ArgoCD (Optional but recommended)
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bitbucket-ssh-key
  namespace: argocd
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: bitbucket-ssh-key
    template:
      metadata:
        labels:
          argocd.argoproj.io/secret-type: repo-creds
      data:
        type: git
        url: 'git@bitbucket.org:{{ .workspace }}'
        sshPrivateKey: "{{ .ssh_private_key }}"
  data:
  - secretKey: ssh_private_key
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: ssh_private_key
  - secretKey: workspace
    remoteRef:
      conversionStrategy: Default
      decodingStrategy: None
      key: cnoe-ref-impl/bitbucket-app
      metadataPolicy: None
      property: workspace
```

### Step 3: Backstage Configuration Updates

#### 3.1 Enhanced Backstage ConfigMap

Update `packages/backstage/chart/templates/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backstage-config
  namespace: {{ .Values.namespace }}
  labels:
    app.kubernetes.io/name: backstage
    {{- include "backstage.labels" . | nindent 4 }}
data:
  app-config.yaml: |
    app:
      title: {{ .Values.backstage.config.app.title }}
      baseUrl: ${BACKSTAGE_FRONTEND_URL}
    organization:
      name: {{ .Values.backstage.config.organization.name }}
    backend:
      baseUrl: ${BACKSTAGE_FRONTEND_URL}
      listen:
        port: {{ .Values.backstage.config.backend.listen.port }}
      csp:
        connect-src: {{.Values.backstage.config.backend.csp.connectsrc | toJson }}
      cors:
        origin: ${BACKSTAGE_FRONTEND_URL}
        methods: {{ .Values.backstage.config.backend.cors.methods | toJson }}
        credentials: {{ .Values.backstage.config.backend.cors.credentials }}
      database:
        client: {{ .Values.backstage.config.backend.database.client }}
        connection:
          host: ${POSTGRES_HOST}
          port: ${POSTGRES_PORT}
          user: ${POSTGRES_USER}
          password: ${POSTGRES_PASSWORD}
      cache:
        store: {{ .Values.backstage.config.backend.cache.store }}

    integrations:
      {{- if .Values.backstage.config.integrations.github.enabled }}
      github:
        - host: github.com
          apps:
            - $include: github-integration.yaml
      {{- end }}
      {{- if .Values.backstage.config.integrations.bitbucket.enabled }}
      bitbucket:
        - host: {{ .Values.backstage.config.integrations.bitbucket.host }}
          username: ${BITBUCKET_USERNAME}
          appPassword: ${BITBUCKET_APP_PASSWORD}
      {{- end }}

    proxy:
      '/argo-workflows/api':
        target: ${ARGO_WORKFLOWS_URL}
        changeOrigin: true
        secure: true
        headers:
          Authorization:
            $env: ARGO_WORKFLOWS_AUTH_TOKEN
      '/argocd/api':
        target: ${ARGO_CD_URL}
        changeOrigin: true
        headers:
          Cookie:
            $env: ARGOCD_AUTH_TOKEN

    techdocs:
      builder: 'local'
      generator:
        runIn: 'docker'
      publisher:
        type: 'local'

    auth:
      environment: {{ .Values.backstage.config.auth.environment }}
      session:
        secret: {{ .Values.backstage.config.auth.session.secret | quote }}
      providers:
        keycloak-oidc:
          development:
            metadataUrl: ${KEYCLOAK_NAME_METADATA}
            clientId: {{ .Values.backstage.config.auth.providers.keycloakoidc.development.clientId }}
            clientSecret: ${BACKSTAGE_CLIENT_SECRET}
            additionalScopes: {{ .Values.backstage.config.auth.providers.keycloakoidc.development.scope | quote }}
            prompt: {{ .Values.backstage.config.auth.providers.keycloakoidc.development.prompt }}

    scaffolder:
      # see https://backstage.io/docs/features/software-templates/configuration for software template options

    catalog:
      import:
        entityFilename: {{ .Values.backstage.config.catalog.import.entityFilename }}
        pullRequestBranchName: {{ .Values.backstage.config.catalog.import.pullRequestBranchName }}
      rules:
        {{- toYaml .Values.backstage.config.catalog.rules | nindent 8 }}
      locations:
        {{- range .Values.backstage.config.catalog.locations }}
        - type: {{ .type }}
          target: {{ .target }}
        {{- end }}
        {{- if .Values.backstage.config.integrations.bitbucket.enabled }}
        {{- range .Values.backstage.config.catalog.bitbucket_locations }}
        - type: {{ .type }}
          target: {{ .target }}
        {{- end }}
        {{- end }}
        
    kubernetes:
      serviceLocatorMethod:
        type: {{ .Values.backstage.config.kubernetes.serviceLocatorMethod.type | quote }}
      clusterLocatorMethods:
        - $include: k8s-config.yaml
    argocd:
      username: admin
      password: ${ARGOCD_ADMIN_PASSWORD}
      appLocatorMethods:
        - type: 'config'
          instances:
            - name: in-cluster
              url: ${ARGO_CD_URL}
              username: admin
              password: ${ARGOCD_ADMIN_PASSWORD}
    argoWorkflows:
        baseUrl: ${ARGO_WORKFLOWS_URL}
```

#### 3.2 Updated Backstage Values

Update `packages/backstage/chart/values.yaml`:

```yaml
# ... existing configuration ...

backstage:
  # ... existing configuration ...
  config:
    # ... existing configuration ...
    integrations:
      github:
        enabled: true
        - host: github.com
          # Token will be provided via secret
      bitbucket:
        enabled: false  # Set to true when enabling Bitbucket
        host: bitbucket.org  # For Bitbucket Server: your-bitbucket-server.com
    catalog:
      import:
        entityFilename: catalog-info.yaml
        pullRequestBranchName: backstage-integration
      rules:
        - allow: [Component, System, API, Resource, Location, Template]
      locations:
        - type: url
          target: https://github.com/cnoe-io/reference-implementation-aws/blob/ref-impl-v2/templates/backstage/catalog-info.yaml
      bitbucket_locations:
        - type: url
          target: https://bitbucket.org/your-workspace/reference-implementation-aws/src/ref-impl-v2/templates/backstage/catalog-info.yaml
    # ... rest of configuration ...

# ... rest of configuration ...
```

### Step 4: Enhanced Installation Scripts

#### 4.1 Updated `create-config-secrets.sh`

```bash
#!/bin/bash
set -e

# Configuration
CONFIG_FILE="config.yaml"
PRIVATE_DIR="private"
AWS_REGION=$(yq eval '.region' "$CONFIG_FILE")

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI not configured or no valid credentials found"
    exit 1
fi

# Function to create or update secret
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3
    
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$AWS_REGION" &> /dev/null; then
        echo "Updating existing secret: $secret_name"
        aws secretsmanager update-secret \
            --secret-id "$secret_name" \
            --secret-string "$secret_value" \
            --region "$AWS_REGION"
    else
        echo "Creating new secret: $secret_name"
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --description "$description" \
            --secret-string "$secret_value" \
            --region "$AWS_REGION"
    fi
}

# Create config secret
echo "Creating configuration secret..."
CONFIG_JSON=$(yq eval '. | to_entries | map({"key": .key, "value": .value}) | from_entries' "$CONFIG_FILE" -o=json)
create_or_update_secret "cnoe-ref-impl/config" "$CONFIG_JSON" "CNOE Reference Implementation Configuration"

# Create GitHub App secret (existing functionality)
if [ -f "$PRIVATE_DIR/backstage-github.yaml" ] && [ -f "$PRIVATE_DIR/argocd-github.yaml" ]; then
    echo "Creating GitHub App secret..."
    
    # Create GitHub secrets JSON
    GITHUB_SECRETS=$(cat << EOF
{
  "backstage-github.appId": "$(yq eval '.appId' "$PRIVATE_DIR/backstage-github.yaml")",
  "backstage-github.clientId": "$(yq eval '.clientId' "$PRIVATE_DIR/backstage-github.yaml")",
  "backstage-github.clientSecret": "$(yq eval '.clientSecret' "$PRIVATE_DIR/backstage-github.yaml")",
  "backstage-github.webhookSecret": "$(yq eval '.webhookSecret' "$PRIVATE_DIR/backstage-github.yaml")",
  "backstage-github.privateKey": "$(yq eval '.privateKey' "$PRIVATE_DIR/backstage-github.yaml")",
  "backstage-github.webhookUrl": "$(yq eval '.webhookUrl' "$PRIVATE_DIR/backstage-github.yaml")",
  "argocd-github.appId": "$(yq eval '.appId' "$PRIVATE_DIR/argocd-github.yaml")",
  "argocd-github.installationId": "$(yq eval '.installationId' "$PRIVATE_DIR/argocd-github.yaml")",
  "argocd-github.privateKey": "$(yq eval '.privateKey' "$PRIVATE_DIR/argocd-github.yaml")",
  "argocd-github.url": "$(yq eval '.url' "$PRIVATE_DIR/argocd-github.yaml")"
}
EOF
)
    
    create_or_update_secret "cnoe-ref-impl/github-app" "$GITHUB_SECRETS" "GitHub App credentials for CNOE Reference Implementation"
fi

# Create Bitbucket App secret (new functionality)
if [ -f "$PRIVATE_DIR/bitbucket-config.yaml" ]; then
    echo "Creating Bitbucket App secret..."
    
    # Create Bitbucket secrets JSON
    BITBUCKET_SECRETS=$(cat << EOF
{
  "username": "$(yq eval '.username' "$PRIVATE_DIR/bitbucket-config.yaml")",
  "app_password": "$(yq eval '.app_password' "$PRIVATE_DIR/bitbucket-config.yaml")",
  "server_url": "$(yq eval '.server_url' "$PRIVATE_DIR/bitbucket-config.yaml")",
  "workspace": "$(yq eval '.workspace' "$PRIVATE_DIR/bitbucket-config.yaml")"
}
EOF
)
    
    # Add SSH key if provided
    if [ -f "$PRIVATE_DIR/bitbucket-ssh-key" ]; then
        SSH_PRIVATE_KEY=$(cat "$PRIVATE_DIR/bitbucket-ssh-key" | sed ':a;N;$!ba;s/\n/\\n/g')
        BITBUCKET_SECRETS=$(echo "$BITBUCKET_SECRETS" | jq --arg ssh_key "$SSH_PRIVATE_KEY" '. + {"ssh_private_key": $ssh_key}')
    fi
    
    if [ -f "$PRIVATE_DIR/bitbucket-ssh-key.pub" ]; then
        SSH_PUBLIC_KEY=$(cat "$PRIVATE_DIR/bitbucket-ssh-key.pub")
        BITBUCKET_SECRETS=$(echo "$BITBUCKET_SECRETS" | jq --arg ssh_pub "$SSH_PUBLIC_KEY" '. + {"ssh_public_key": $ssh_pub}')
    fi
    
    create_or_update_secret "cnoe-ref-impl/bitbucket-app" "$BITBUCKET_SECRETS" "Bitbucket App credentials for CNOE Reference Implementation"
fi

echo "All secrets created/updated successfully!"
```

#### 4.2 Bitbucket Configuration Template

Create `private/bitbucket-config.yaml.template`:

```yaml
# Bitbucket Configuration Template
# Copy this file to bitbucket-config.yaml and fill in your values

# Bitbucket username
username: "your-bitbucket-username"

# Bitbucket app password (generate from Bitbucket settings)
app_password: "your-app-password"

# Bitbucket server URL
server_url: "https://bitbucket.org"  # For Bitbucket Server: https://your-bitbucket-server.com

# Bitbucket workspace name
workspace: "your-workspace-name"

# Additional configuration for Bitbucket Server
# server_version: "7.17.0"  # Uncomment for Bitbucket Server
# project_key: "YOUR_PROJECT"  # Uncomment for Bitbucket Server
```

### Step 5: Template Updates

#### 5.1 Bitbucket-Compatible Software Template

Create `templates/backstage/bitbucket-service-template.yaml`:

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: bitbucket-service-template
  title: Bitbucket Service Template
  description: Create a new service with Bitbucket repository
  tags:
    - bitbucket
    - service
    - recommended
spec:
  owner: platform-team
  type: service
  parameters:
    - title: Service Information
      required:
        - name
        - description
      properties:
        name:
          title: Name
          type: string
          description: Unique name of the service
          pattern: '^[a-z0-9-]+$'
        description:
          title: Description
          type: string
          description: Description of the service
        owner:
          title: Owner
          type: string
          description: Owner of the service
          default: platform-team
    - title: Bitbucket Configuration
      required:
        - workspace
        - repoUrl
      properties:
        workspace:
          title: Bitbucket Workspace
          type: string
          description: Bitbucket workspace name
          default: your-workspace
        repoUrl:
          title: Repository Location
          type: string
          ui:field: RepoUrlPicker
          ui:options:
            allowedHosts:
              - bitbucket.org
              - your-bitbucket-server.com
  steps:
    - id: template
      name: Fetch Skeleton + Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          description: ${{ parameters.description }}
          owner: ${{ parameters.owner }}
          workspace: ${{ parameters.workspace }}
    - id: publish
      name: Publish to Bitbucket
      action: publish:bitbucket
      input:
        repoUrl: ${{ parameters.repoUrl }}
        description: ${{ parameters.description }}
        defaultBranch: main
        gitAuthorName: Backstage
        gitAuthorEmail: backstage@example.com
    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml
  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
```

### Step 6: Deployment and Validation

#### 6.1 Deployment Script

Create `scripts/deploy-bitbucket-integration.sh`:

```bash
#!/bin/bash
set -e

echo "Deploying Bitbucket integration..."

# Check if Bitbucket is enabled in config
BITBUCKET_ENABLED=$(yq eval '.git_providers.bitbucket.enabled' config.yaml)

if [ "$BITBUCKET_ENABLED" = "true" ]; then
    echo "Bitbucket integration is enabled, proceeding with deployment..."
    
    # Apply Bitbucket external secrets
    kubectl apply -f packages/backstage/manifests/external-secrets-bitbucket.yaml
    kubectl apply -f packages/argo-cd/manifests/argo-cd-bitbucket-app.yaml
    
    # Wait for secrets to be created
    echo "Waiting for Bitbucket secrets to be created..."
    kubectl wait --for=condition=Ready externalsecret/bitbucket-integration -n backstage --timeout=300s
    kubectl wait --for=condition=Ready externalsecret/bitbucket-env-vars -n backstage --timeout=300s
    
    # Restart Backstage to pick up new configuration
    kubectl rollout restart deployment/backstage -n backstage
    
    echo "Bitbucket integration deployed successfully!"
else
    echo "Bitbucket integration is disabled in config.yaml"
fi
```

#### 6.2 Validation Script

Create `scripts/validate-bitbucket-integration.sh`:

```bash
#!/bin/bash
set -e

echo "Validating Bitbucket integration..."

# Check if secrets exist
echo "Checking Bitbucket secrets..."
kubectl get secret bitbucket-integration -n backstage
kubectl get secret bitbucket-env-vars -n backstage
kubectl get secret bitbucket-app-password -n argocd

# Check if Backstage can access Bitbucket
echo "Checking Backstage logs for Bitbucket integration..."
kubectl logs -n backstage deployment/backstage --tail=100 | grep -i bitbucket || echo "No Bitbucket logs found"

# Test ArgoCD repository connection
echo "Testing ArgoCD repository connection..."
kubectl exec -n argocd deployment/argocd-server -- argocd repo list | grep bitbucket || echo "No Bitbucket repositories found in ArgoCD"

echo "Validation completed!"
```

## Quick Start Guide

### For New Bitbucket Setup

1. **Configure Bitbucket credentials:**
   ```bash
   cp private/bitbucket-config.yaml.template private/bitbucket-config.yaml
   # Edit private/bitbucket-config.yaml with your credentials
   ```

2. **Update config.yaml:**
   ```bash
   yq eval '.git_providers.bitbucket.enabled = true' -i config.yaml
   yq eval '.git_providers.bitbucket.workspace = "your-workspace"' -i config.yaml
   yq eval '.git_providers.bitbucket.repo.url = "https://bitbucket.org/your-workspace/your-repo"' -i config.yaml
   ```

3. **Create secrets:**
   ```bash
   ./scripts/create-config-secrets.sh
   ```

4. **Deploy integration:**
   ```bash
   ./scripts/deploy-bitbucket-integration.sh
   ```

5. **Validate:**
   ```bash
   ./scripts/validate-bitbucket-integration.sh
   ```

### For Existing GitHub Setup

1. **Migrate configuration:**
   ```bash
   ./scripts/migrate-config.sh
   ```

2. **Follow steps 1-5 from "New Bitbucket Setup"**

3. **Update Backstage values:**
   ```bash
   yq eval '.backstage.config.integrations.bitbucket.enabled = true' -i packages/backstage/values.yaml
   ```

## Troubleshooting

### Common Issues

1. **Authentication failures:**
   - Verify app password has correct permissions
   - Check workspace name is correct
   - Ensure server URL is accessible

2. **Secret creation failures:**
   - Verify AWS credentials are configured
   - Check AWS Secrets Manager permissions
   - Ensure region is correct in config.yaml

3. **ArgoCD repository access:**
   - Verify SSH key is added to Bitbucket
   - Check repository URL format
   - Ensure repository exists and is accessible

### Debug Commands

```bash
# Check external secrets status
kubectl get externalsecrets -n backstage
kubectl get externalsecrets -n argocd

# Check secret contents (be careful with sensitive data)
kubectl get secret bitbucket-integration -n backstage -o yaml

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server

# Check Backstage logs
kubectl logs -n backstage deployment/backstage
```

---

*This implementation guide provides the complete code changes and configurations needed to integrate Bitbucket support into the CNOE Reference Implementation.*