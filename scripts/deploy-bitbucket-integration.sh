#!/bin/bash
set -e

export REPO_ROOT=$(git rev-parse --show-toplevel)
source ${REPO_ROOT}/scripts/utils.sh

echo -e "\n${BOLD}${BLUE}🚀 Deploying Bitbucket Integration${NC}"
echo -e "${CYAN}================================================${NC}"

# Check if config file exists
if [ ! -f "config.yaml" ]; then
    echo -e "${RED}❌ Config file not found: config.yaml${NC}"
    exit 1
fi

# Check if Bitbucket is enabled in config
if yq eval '.git_providers.bitbucket.enabled' config.yaml > /dev/null 2>&1; then
    BITBUCKET_ENABLED=$(yq eval '.git_providers.bitbucket.enabled' config.yaml)
else
    # Check for legacy configuration
    echo -e "${YELLOW}⚠️  Using legacy configuration format${NC}"
    echo -e "${CYAN}ℹ️  Run './scripts/migrate-config.sh' to upgrade to new format${NC}"
    BITBUCKET_ENABLED="false"
fi

if [ "$BITBUCKET_ENABLED" = "true" ]; then
    echo -e "${GREEN}✅ Bitbucket integration is enabled, proceeding with deployment...${NC}"
    
    # Check if secrets are created
    echo -e "\n${YELLOW}🔐 Checking Bitbucket secrets in AWS Secrets Manager...${NC}"
    if aws secretsmanager describe-secret --secret-id "cnoe-ref-impl/bitbucket-app" --region $(yq eval '.region' config.yaml) >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Bitbucket secrets found in AWS Secrets Manager${NC}"
    else
        echo -e "${RED}❌ Bitbucket secrets not found in AWS Secrets Manager${NC}"
        echo -e "${CYAN}ℹ️  Run './scripts/create-config-secrets.sh' to create secrets${NC}"
        exit 1
    fi
    
    # Apply Bitbucket external secrets
    echo -e "\n${YELLOW}📦 Applying Bitbucket External Secrets...${NC}"
    kubectl apply -f packages/backstage/manifests/external-secrets-bitbucket.yaml
    kubectl apply -f packages/argo-cd/manifests/argo-cd-bitbucket-app.yaml
    
    # Wait for secrets to be created
    echo -e "\n${YELLOW}⏳ Waiting for Bitbucket secrets to be created...${NC}"
    
    # Wait for backstage secrets
    echo -e "${CYAN}  Waiting for backstage secrets...${NC}"
    kubectl wait --for=condition=Ready externalsecret/bitbucket-integration -n backstage --timeout=300s
    kubectl wait --for=condition=Ready externalsecret/bitbucket-env-vars -n backstage --timeout=300s
    
    # Wait for argocd secrets (with error handling for SSH key if not configured)
    echo -e "${CYAN}  Waiting for ArgoCD secrets...${NC}"
    kubectl wait --for=condition=Ready externalsecret/bitbucket-app-password -n argocd --timeout=300s
    
    # Check if SSH key is configured
    if aws secretsmanager get-secret-value --secret-id "cnoe-ref-impl/bitbucket-app" --region $(yq eval '.region' config.yaml) --query 'SecretString' --output text | jq -r '.ssh_private_key' | grep -q "BEGIN"; then
        echo -e "${CYAN}  SSH key detected, waiting for SSH secrets...${NC}"
        kubectl wait --for=condition=Ready externalsecret/bitbucket-ssh-key -n argocd --timeout=300s || echo -e "${YELLOW}⚠️  SSH key secret creation failed, continuing with app password only${NC}"
        kubectl wait --for=condition=Ready externalsecret/bitbucket-workspace-ssh-key -n argocd --timeout=300s || echo -e "${YELLOW}⚠️  Workspace SSH key secret creation failed, continuing with app password only${NC}"
    else
        echo -e "${YELLOW}⚠️  No SSH key found, using app password authentication only${NC}"
    fi
    
    # Check if Backstage Bitbucket integration is enabled in values
    if yq eval '.backstage.config.integrations.bitbucket.enabled' packages/backstage/values.yaml | grep -q "true"; then
        echo -e "${GREEN}✅ Backstage Bitbucket integration is enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Backstage Bitbucket integration is not enabled in values.yaml${NC}"
        echo -e "${CYAN}ℹ️  Enable it with: yq eval '.backstage.config.integrations.bitbucket.enabled = true' -i packages/backstage/values.yaml${NC}"
    fi
    
    # Restart Backstage to pick up new configuration
    echo -e "\n${YELLOW}🔄 Restarting Backstage to pick up new configuration...${NC}"
    if kubectl get deployment backstage -n backstage >/dev/null 2>&1; then
        kubectl rollout restart deployment/backstage -n backstage
        echo -e "${GREEN}✅ Backstage deployment restarted${NC}"
    else
        echo -e "${YELLOW}⚠️  Backstage deployment not found, it may not be deployed yet${NC}"
    fi
    
    echo -e "\n${BOLD}${GREEN}🎉 Bitbucket integration deployed successfully!${NC}"
    echo -e "${CYAN}📋 Next steps:${NC}"
    echo -e "${CYAN}1. Run './scripts/validate-bitbucket-integration.sh' to validate the integration${NC}"
    echo -e "${CYAN}2. Update your Backstage templates to use Bitbucket repositories${NC}"
    echo -e "${CYAN}3. Configure ArgoCD applications to use Bitbucket repositories${NC}"
    
else
    echo -e "${RED}❌ Bitbucket integration is disabled in config.yaml${NC}"
    echo -e "${CYAN}ℹ️  To enable Bitbucket integration:${NC}"
    echo -e "${CYAN}1. Run './scripts/migrate-config.sh' to upgrade configuration${NC}"
    echo -e "${CYAN}2. Set git_providers.bitbucket.enabled = true in config.yaml${NC}"
    echo -e "${CYAN}3. Configure git_providers.bitbucket.workspace and repo.url${NC}"
    echo -e "${CYAN}4. Create private/bitbucket-config.yaml with your credentials${NC}"
    echo -e "${CYAN}5. Run './scripts/create-config-secrets.sh' to create secrets${NC}"
    echo -e "${CYAN}6. Run this script again${NC}"
    exit 1
fi