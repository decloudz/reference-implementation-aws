#!/bin/bash
set -e -o pipefail

export REPO_ROOT=$(git rev-parse --show-toplevel)
PHASE="install"
source ${REPO_ROOT}/scripts/utils.sh

echo -e "\n${BOLD}${BLUE}🚀 Starting installation process...${NC}"

# Static helm values files
ARGOCD_STATIC_VALUES_FILE=${REPO_ROOT}/packages/argo-cd/values.yaml
EXTERNAL_SECRETS_STATIC_VALUES_FILE=${REPO_ROOT}/packages/external-secrets/values.yaml
ADDONS_APPSET_STATIC_VALUES_FILE=${REPO_ROOT}/packages/bootstrap/values.yaml

# Chart versions for Argo CD and ESO
ARGOCD_CHART_VERSION=$(yq '.argocd.defaultVersion' ${REPO_ROOT}/packages/addons/values.yaml)
EXTERNAL_SECRETS_CHART_VERSION=$(yq '.external-secrets.defaultVersion' ${REPO_ROOT}/packages/addons/values.yaml)

# Custom Manifests Paths
ARGOCD_CUSTOM_MANIFESTS_PATH=${REPO_ROOT}/packages/argo-cd/manifests
EXTERNAL_SECRETS_CUSTOM_MANIFESTS_PATH=${REPO_ROOT}/packages/external-secrets/manifests

# Build Argo CD dynamic values
ARGOCD_DYNAMIC_VALUES_FILE=$(mktemp)
ISSUER_URL=$([[ "${PATH_ROUTING}" == "false" ]] && echo "keycloak.${DOMAIN_NAME}" || echo "${DOMAIN_NAME}/keycloak")
cat << EOF > "$ARGOCD_DYNAMIC_VALUES_FILE"
cnoe_ref_impl: # Specific values for reference CNOE implementation to control extraObjects.
  auto_mode: $([[ "${AUTO_MODE}" == "true" ]] && echo '"true"' || echo '"false"')
global:
  domain: $([[ "${PATH_ROUTING}" == "true" ]] && echo "${DOMAIN_NAME}" || echo "argocd.${DOMAIN_NAME}")
server:
  ingress:
    annotations: 
      cert-manager.io/cluster-issuer: $([[ "${PATH_ROUTING}" == "false" ]] && echo '"letsencrypt-prod"' || echo "")
    path: /$([[ "${PATH_ROUTING}" == "true" ]] && echo "argocd" || echo "")
configs:
  cm:
    oidc.config: |
      name: Keycloak
      issuer: https://$ISSUER_URL/realms/cnoe
      clientID: argocd
      enablePKCEAuthentication: true
      requestedScopes:
        - openid
        - profile
        - email
        - groups
  params:
    'server.basehref': /$([[ "${PATH_ROUTING}" == "true" ]] && echo "argocd" || echo "")
    'server.rootpath': $([[ "${PATH_ROUTING}" == "true" ]] && echo "argocd" || echo "")
EOF

echo -e "${BOLD}${GREEN}🔄 Installing Argo CD...${NC}"
helm repo add argo "https://argoproj.github.io/argo-helm"
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --version $ARGOCD_CHART_VERSION \
  --create-namespace \
  --values "$ARGOCD_STATIC_VALUES_FILE" \
  --values "$ARGOCD_DYNAMIC_VALUES_FILE" \
  --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1

echo -e "${YELLOW}⏳ Waiting for Argo CD to be healthy...${NC}"
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s --kubeconfig $KUBECONFIG_FILE


echo -e "${BOLD}${GREEN}🔄 Installing External Secrets...${NC}"
helm repo add external-secrets "https://charts.external-secrets.io"
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --version $EXTERNAL_SECRETS_CHART_VERSION \
  --create-namespace \
  --values "$EXTERNAL_SECRETS_STATIC_VALUES_FILE" \
  --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1

echo -e "${YELLOW}⏳ Waiting for External Secrets to be healthy...${NC}"
kubectl wait --for=condition=available deployment/external-secrets -n external-secrets --timeout=300s --kubeconfig $KUBECONFIG_FILE


echo -e "${BOLD}${GREEN}🔄 Applying custom manifests...${NC}"
kubectl apply -f "$ARGOCD_CUSTOM_MANIFESTS_PATH" --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1
kubectl apply -f "$EXTERNAL_SECRETS_CUSTOM_MANIFESTS_PATH" --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1

# Apply Git provider specific manifests
echo -e "${CYAN}🔍 Detecting enabled Git providers...${NC}"

# Check for GitHub integration
if yq eval '.git_providers.github.enabled // .repo.url | test("github")' "$CONFIG_FILE" | grep -q "true"; then
    echo -e "${GREEN}✅ GitHub integration detected${NC}"
    # GitHub manifests are already applied above
fi

# Check for Bitbucket integration
if yq eval '.git_providers.bitbucket.enabled' "$CONFIG_FILE" 2>/dev/null | grep -q "true"; then
    echo -e "${GREEN}✅ Bitbucket integration detected - applying Bitbucket manifests${NC}"
    
    # Apply Backstage Bitbucket manifests
    if [ -f "${REPO_ROOT}/packages/backstage/manifests/external-secrets-bitbucket.yaml" ]; then
        kubectl apply -f "${REPO_ROOT}/packages/backstage/manifests/external-secrets-bitbucket.yaml" --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1
        echo -e "${CYAN}  Applied Backstage Bitbucket external secrets${NC}"
    fi
    
    # Apply ArgoCD Bitbucket manifests  
    if [ -f "${REPO_ROOT}/packages/argo-cd/manifests/argo-cd-bitbucket-app.yaml" ]; then
        kubectl apply -f "${REPO_ROOT}/packages/argo-cd/manifests/argo-cd-bitbucket-app.yaml" --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1
        echo -e "${CYAN}  Applied ArgoCD Bitbucket external secrets${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Bitbucket integration not enabled${NC}"
fi

echo -e "${BOLD}${GREEN}🔄 Installing Addons AppSet Argo CD application...${NC}"
helm upgrade --install addons-appset ${REPO_ROOT}/packages/appset-chart \
  --namespace argocd \
  --values "$ADDONS_APPSET_STATIC_VALUES_FILE" \
  --kubeconfig $KUBECONFIG_FILE > /dev/null 2>&1

# Wait for Argo CD applications to sync
wait_for_apps

echo -e "\n${BOLD}${BLUE}🎉 Installation completed successfully! 🎉${NC}"
echo -e "${CYAN}📊 You can now access your resources and start deploying applications.${NC}"