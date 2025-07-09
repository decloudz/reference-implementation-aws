#!/bin/bash
set -e

export REPO_ROOT=$(git rev-parse --show-toplevel)
source ${REPO_ROOT}/scripts/utils.sh

echo -e "\n${BOLD}${BLUE}🔍 Validating Bitbucket Integration${NC}"
echo -e "${CYAN}================================================${NC}"

# Status tracking
VALIDATION_ERRORS=0

# Function to check validation status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
}

# Function to check optional status
check_optional_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${YELLOW}⚠️  $2${NC}"
    fi
}

echo -e "\n${YELLOW}🔐 Checking Bitbucket secrets...${NC}"

# Check if secrets exist in Kubernetes
echo -e "${CYAN}  Checking Kubernetes secrets...${NC}"
kubectl get secret bitbucket-integration -n backstage >/dev/null 2>&1
check_status $? "Bitbucket integration secret exists in backstage namespace"

kubectl get secret bitbucket-env-vars -n backstage >/dev/null 2>&1
check_status $? "Bitbucket environment variables secret exists in backstage namespace"

kubectl get secret bitbucket-app-password -n argocd >/dev/null 2>&1
check_status $? "Bitbucket app password secret exists in argocd namespace"

# Check optional SSH key secrets
kubectl get secret bitbucket-ssh-key -n argocd >/dev/null 2>&1
check_optional_status $? "Bitbucket SSH key secret exists in argocd namespace (optional)"

kubectl get secret bitbucket-workspace-ssh-key -n argocd >/dev/null 2>&1
check_optional_status $? "Bitbucket workspace SSH key secret exists in argocd namespace (optional)"

# Check External Secrets status
echo -e "\n${YELLOW}📦 Checking External Secrets status...${NC}"
kubectl get externalsecret bitbucket-integration -n backstage -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"
check_status $? "Bitbucket integration external secret is ready"

kubectl get externalsecret bitbucket-env-vars -n backstage -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"
check_status $? "Bitbucket environment variables external secret is ready"

kubectl get externalsecret bitbucket-app-password -n argocd -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"
check_status $? "Bitbucket app password external secret is ready"

# Check if Backstage can access Bitbucket
echo -e "\n${YELLOW}🏗️  Checking Backstage configuration...${NC}"

# Check if Backstage is running
kubectl get deployment backstage -n backstage >/dev/null 2>&1
check_status $? "Backstage deployment exists"

if kubectl get deployment backstage -n backstage >/dev/null 2>&1; then
    # Check if deployment is ready
    kubectl get deployment backstage -n backstage -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' | grep -q "True"
    check_status $? "Backstage deployment is available"
    
    # Check if Bitbucket integration is enabled in values
    if yq eval '.backstage.config.integrations.bitbucket.enabled' packages/backstage/values.yaml | grep -q "true"; then
        echo -e "${GREEN}✅ Backstage Bitbucket integration is enabled in values.yaml${NC}"
    else
        echo -e "${RED}❌ Backstage Bitbucket integration is disabled in values.yaml${NC}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
    
    # Check Backstage logs for Bitbucket integration
    echo -e "\n${YELLOW}📋 Checking Backstage logs for Bitbucket integration...${NC}"
    if kubectl logs -n backstage deployment/backstage --tail=100 | grep -i bitbucket >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Bitbucket integration logs found in Backstage${NC}"
        kubectl logs -n backstage deployment/backstage --tail=100 | grep -i bitbucket | head -5 | while read line; do
            echo -e "${CYAN}  $line${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  No Bitbucket integration logs found (this may be normal)${NC}"
    fi
fi

# Check ArgoCD repository connections
echo -e "\n${YELLOW}🔄 Checking ArgoCD repository connections...${NC}"

# Check if ArgoCD is running
kubectl get deployment argocd-server -n argocd >/dev/null 2>&1
check_status $? "ArgoCD server deployment exists"

if kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    # Check if ArgoCD can list repositories
    echo -e "${CYAN}  Checking ArgoCD repository connections...${NC}"
    if kubectl exec -n argocd deployment/argocd-server -- argocd repo list --grpc-web 2>/dev/null | grep -i bitbucket >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Bitbucket repositories found in ArgoCD${NC}"
        kubectl exec -n argocd deployment/argocd-server -- argocd repo list --grpc-web 2>/dev/null | grep -i bitbucket | head -3 | while read line; do
            echo -e "${CYAN}  $line${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  No Bitbucket repositories found in ArgoCD (add them manually)${NC}"
    fi
fi

# Check AWS Secrets Manager
echo -e "\n${YELLOW}☁️  Checking AWS Secrets Manager...${NC}"
if [ -f "config.yaml" ]; then
    AWS_REGION=$(yq eval '.region' config.yaml)
    echo -e "${CYAN}  Checking Bitbucket secrets in AWS Secrets Manager (region: $AWS_REGION)...${NC}"
    
    aws secretsmanager describe-secret --secret-id "cnoe-ref-impl/bitbucket-app" --region $AWS_REGION >/dev/null 2>&1
    check_status $? "Bitbucket app secret exists in AWS Secrets Manager"
    
    if aws secretsmanager describe-secret --secret-id "cnoe-ref-impl/bitbucket-app" --region $AWS_REGION >/dev/null 2>&1; then
        # Check if secret has required fields
        SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "cnoe-ref-impl/bitbucket-app" --region $AWS_REGION --query 'SecretString' --output text)
        
        echo "$SECRET_VALUE" | jq -r '.username' | grep -v "null" >/dev/null 2>&1
        check_status $? "Bitbucket username is configured"
        
        echo "$SECRET_VALUE" | jq -r '.app_password' | grep -v "null" >/dev/null 2>&1
        check_status $? "Bitbucket app password is configured"
        
        echo "$SECRET_VALUE" | jq -r '.workspace' | grep -v "null" >/dev/null 2>&1
        check_status $? "Bitbucket workspace is configured"
        
        echo "$SECRET_VALUE" | jq -r '.server_url' | grep -v "null" >/dev/null 2>&1
        check_status $? "Bitbucket server URL is configured"
        
        # Check optional SSH key
        if echo "$SECRET_VALUE" | jq -r '.ssh_private_key' | grep -q "BEGIN"; then
            echo -e "${GREEN}✅ SSH private key is configured (optional)${NC}"
        else
            echo -e "${YELLOW}⚠️  SSH private key is not configured (optional)${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Config file not found${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Check configuration
echo -e "\n${YELLOW}⚙️  Checking configuration...${NC}"
if [ -f "config.yaml" ]; then
    # Check if Bitbucket is enabled
    if yq eval '.git_providers.bitbucket.enabled' config.yaml 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}✅ Bitbucket is enabled in config.yaml${NC}"
        
        # Check workspace configuration
        WORKSPACE=$(yq eval '.git_providers.bitbucket.workspace' config.yaml 2>/dev/null)
        if [ "$WORKSPACE" != "null" ] && [ -n "$WORKSPACE" ]; then
            echo -e "${GREEN}✅ Bitbucket workspace is configured: $WORKSPACE${NC}"
        else
            echo -e "${RED}❌ Bitbucket workspace is not configured${NC}"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        
        # Check repository URL
        REPO_URL=$(yq eval '.git_providers.bitbucket.repo.url' config.yaml 2>/dev/null)
        if [ "$REPO_URL" != "null" ] && [ -n "$REPO_URL" ]; then
            echo -e "${GREEN}✅ Bitbucket repository URL is configured: $REPO_URL${NC}"
        else
            echo -e "${RED}❌ Bitbucket repository URL is not configured${NC}"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo -e "${RED}❌ Bitbucket is disabled in config.yaml${NC}"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    echo -e "${RED}❌ Config file not found${NC}"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

# Final validation summary
echo -e "\n${BOLD}${BLUE}📊 Validation Summary${NC}"
echo -e "${CYAN}===================${NC}"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo -e "${BOLD}${GREEN}🎉 All validations passed! Bitbucket integration is working correctly.${NC}"
    echo -e "\n${CYAN}📋 Next steps:${NC}"
    echo -e "${CYAN}1. Test creating a new service using Bitbucket templates in Backstage${NC}"
    echo -e "${CYAN}2. Configure ArgoCD applications to use Bitbucket repositories${NC}"
    echo -e "${CYAN}3. Test webhook integration if configured${NC}"
    exit 0
else
    echo -e "${BOLD}${RED}❌ Validation failed with $VALIDATION_ERRORS errors.${NC}"
    echo -e "\n${CYAN}📋 Troubleshooting steps:${NC}"
    echo -e "${CYAN}1. Check that all secrets are properly configured${NC}"
    echo -e "${CYAN}2. Verify Bitbucket credentials and permissions${NC}"
    echo -e "${CYAN}3. Ensure External Secrets Operator is running${NC}"
    echo -e "${CYAN}4. Check ArgoCD and Backstage logs for errors${NC}"
    echo -e "${CYAN}5. Run './scripts/deploy-bitbucket-integration.sh' to redeploy${NC}"
    exit 1
fi