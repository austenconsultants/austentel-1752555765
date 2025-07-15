#!/bin/bash
# ===== ACS VOICEHUB PRO - GITHUB TO AZURE DEPLOY =====
# Deploys existing webapp to GitHub and then to Azure Static Web Apps
# Assumes you already have the React app built and ready
# Save as: github-azure-deploy.sh

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Configuration - CONFIGURED FOR YOUR PROJECT
GITHUB_REPO="austentel-1752555765"  # Your actual repo name
RESOURCE_GROUP="austentel-voip-rg"
AZURE_APP_NAME="austentel-1752555765"
LOCATION="centralus"
CUSTOM_DOMAIN="acs1.austentel.com"

# Auto-detected values
GITHUB_USERNAME=""
GITHUB_REPO_URL=""
SWA_HOSTNAME=""

clear
echo -e "${CYAN}"
echo "🚀 ACS VOICEHUB PRO - GITHUB TO AZURE DEPLOY 🚀"
echo "=============================================="
echo -e "${NC}"
echo "Repo: $GITHUB_REPO"
echo "Domain: $CUSTOM_DOMAIN"
echo "Time: $(date)"
echo ""

# Logging function
log_operation() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") echo -e "${BLUE}ℹ️  [$timestamp] $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ [$timestamp] $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  [$timestamp] $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ [$timestamp] $message${NC}" ;;
        "PENDING") echo -e "${ORANGE}⏳ [$timestamp] $message${NC}" ;;
        "STEP") echo -e "${PURPLE}🔄 [$timestamp] $message${NC}" ;;
    esac
}

# Check basic dependencies
check_dependencies() {
    log_operation "INFO" "Checking required tools"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git az jq curl; do
        if ! command -v $cmd >/dev/null 2>&1; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_operation "ERROR" "Missing required tools: ${missing_deps[*]}"
        echo ""
        echo "Install missing tools:"
        echo "• Git: https://git-scm.com/"
        echo "• Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        echo "• jq: brew install jq (macOS) or apt install jq (Linux)"
        exit 1
    fi
    
    # Check Azure login
    if ! az account show >/dev/null 2>&1; then
        log_operation "ERROR" "Not logged into Azure CLI"
        log_operation "INFO" "Run: az login"
        exit 1
    fi
    
    # Check if we're in a React project
    if [ ! -f "package.json" ]; then
        log_operation "ERROR" "No package.json found - are you in the React project directory?"
        exit 1
    fi
    
    if ! grep -q "react" package.json 2>/dev/null; then
        log_operation "ERROR" "This doesn't appear to be a React project"
        exit 1
    fi
    
    log_operation "SUCCESS" "All required tools available"
}

# Detect GitHub info
detect_github_info() {
    log_operation "INFO" "Detecting GitHub repository information"
    
    # Check if we're in a git repo
    if [ ! -d ".git" ]; then
        log_operation "ERROR" "Not in a Git repository. Run: git init"
        exit 1
    fi
    
    # Try to get GitHub info from existing remote
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ $remote_url =~ github\.com[/:]([^/]+)/([^/]+)(\.git)?$ ]]; then
        GITHUB_USERNAME="${BASH_REMATCH[1]}"
        GITHUB_REPO="${BASH_REMATCH[2]%.git}"
        GITHUB_REPO_URL="https://github.com/$GITHUB_USERNAME/$GITHUB_REPO"
        log_operation "SUCCESS" "Detected repository: $GITHUB_REPO_URL"
    else
        # Try to get username from GitHub CLI or prompt
        if command -v gh >/dev/null 2>&1; then
            local gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
            if [ -n "$gh_user" ]; then
                GITHUB_USERNAME="$gh_user"
                log_operation "SUCCESS" "Detected GitHub user: $GITHUB_USERNAME"
            fi
        fi
        
        if [ -z "$GITHUB_USERNAME" ]; then
            echo ""
            read -p "Enter your GitHub username: " GITHUB_USERNAME
        fi
        
        GITHUB_REPO_URL="https://github.com/$GITHUB_USERNAME/$GITHUB_REPO"
        
        # Set the remote
        if [ -z "$remote_url" ]; then
            log_operation "INFO" "Adding GitHub remote: $GITHUB_REPO_URL"
            git remote add origin "$GITHUB_REPO_URL"
        else
            log_operation "INFO" "Updating GitHub remote: $GITHUB_REPO_URL"
            git remote set-url origin "$GITHUB_REPO_URL"
        fi
        
        log_operation "SUCCESS" "GitHub repository configured: $GITHUB_REPO_URL"
    fi
}

# Verify project is ready
verify_project() {
    log_operation "STEP" "Verifying project is deployment-ready"
    
    # Check for essential files
    local missing_files=()
    
    if [ ! -f "src/App.js" ]; then missing_files+=("src/App.js"); fi
    if [ ! -f "src/index.js" ]; then missing_files+=("src/index.js"); fi
    if [ ! -f "public/index.html" ]; then missing_files+=("public/index.html"); fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_operation "ERROR" "Missing essential React files: ${missing_files[*]}"
        exit 1
    fi
    
    # Check if build works
    log_operation "INFO" "Testing React build..."
    npm run build > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_operation "SUCCESS" "React app builds successfully"
        # Clean up build for deployment
        rm -rf build
    else
        log_operation "ERROR" "React app build failed"
        echo ""
        echo "Fix build errors before deploying. Run 'npm run build' to see details."
        exit 1
    fi
    
    # Create Azure Static Web Apps config if missing
    if [ ! -f "public/staticwebapp.config.json" ]; then
        log_operation "INFO" "Creating Azure Static Web Apps configuration"
        cat > public/staticwebapp.config.json << 'EOF'
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["authenticated"]
    },
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "responseOverrides": {
    "401": {
      "redirect": "/login",
      "statusCode": 302
    }
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:;"
  }
}
EOF
        log_operation "SUCCESS" "Azure configuration created"
    fi
    
    log_operation "SUCCESS" "Project is ready for deployment"
}

# Commit and push to GitHub
deploy_to_github() {
    log_operation "STEP" "Deploying to GitHub"
    
    # Check if repository exists on GitHub
    if command -v gh >/dev/null 2>&1; then
        if ! gh repo view "$GITHUB_USERNAME/$GITHUB_REPO" >/dev/null 2>&1; then
            log_operation "INFO" "Creating GitHub repository"
            
            gh repo create "$GITHUB_REPO" \
                --public \
                --description "ACS VoiceHub Pro - FreeSWITCH Management Interface" \
                --homepage "https://$CUSTOM_DOMAIN"
            
            if [ $? -eq 0 ]; then
                log_operation "SUCCESS" "GitHub repository created"
            else
                log_operation "ERROR" "Failed to create repository"
                echo "Create repository manually at: https://github.com/new"
                exit 1
            fi
        fi
    else
        log_operation "WARNING" "GitHub CLI not available - ensure repository exists"
        echo "Repository must exist at: $GITHUB_REPO_URL"
        read -p "Press Enter to continue (Ctrl+C to abort)..."
    fi
    
    # Stage all changes
    log_operation "INFO" "Staging changes for commit"
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        log_operation "INFO" "No new changes to commit"
    else
        # Create commit with deployment info
        local commit_msg="🚀 Deploy ACS VoiceHub Pro to Azure

- Updated for Azure Static Web Apps deployment
- Production build optimized
- Security headers configured
- Ready for $CUSTOM_DOMAIN custom domain

Deployment target: Azure Static Web Apps
Build: React $(npm list react --depth=0 2>/dev/null | grep react@ | cut -d@ -f2 || echo 'latest')
Date: $(date '+%Y-%m-%d %H:%M:%S')"

        log_operation "INFO" "Committing changes"
        git commit -m "$commit_msg"
        
        if [ $? -eq 0 ]; then
            log_operation "SUCCESS" "Changes committed"
        else
            log_operation "ERROR" "Failed to commit changes"
            exit 1
        fi
    fi
    
    # Push to GitHub
    log_operation "INFO" "Pushing to GitHub"
    
    # Determine if we need to set upstream
    local current_branch=$(git branch --show-current)
    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
    
    if [ -z "$upstream" ]; then
        git push -u origin "$current_branch"
    else
        git push
    fi
    
    if [ $? -eq 0 ]; then
        log_operation "SUCCESS" "Code pushed to GitHub successfully"
        log_operation "INFO" "Repository: $GITHUB_REPO_URL"
    else
        log_operation "ERROR" "Failed to push to GitHub"
        echo ""
        echo "Common issues:"
        echo "1. Repository doesn't exist - create it first"
        echo "2. No push access - check authentication"
        echo "3. Branch protection - check repository settings"
        exit 1
    fi
}

# Deploy to Azure Static Web Apps
deploy_to_azure() {
    log_operation "STEP" "Deploying to Azure Static Web Apps"
    
    # Check/create resource group
    log_operation "INFO" "Checking Azure resource group: $RESOURCE_GROUP"
    if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
        log_operation "INFO" "Creating resource group"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        
        if [ $? -eq 0 ]; then
            log_operation "SUCCESS" "Resource group created"
        else
            log_operation "ERROR" "Failed to create resource group"
            exit 1
        fi
    else
        log_operation "SUCCESS" "Resource group exists"
    fi
    
    # Check if Static Web App exists
    local existing_app=$(az staticwebapp show \
        --name "$AZURE_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "name" \
        --output tsv 2>/dev/null || echo "")
    
    if [ -n "$existing_app" ]; then
        log_operation "SUCCESS" "Static Web App already exists: $AZURE_APP_NAME"
        
        # Get current hostname
        SWA_HOSTNAME=$(az staticwebapp show \
            --name "$AZURE_APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --query "defaultHostname" \
            --output tsv)
        
        log_operation "INFO" "Current URL: https://$SWA_HOSTNAME"
        
        # Trigger a new deployment by updating the app
        log_operation "INFO" "Triggering new deployment"
        az staticwebapp update \
            --name "$AZURE_APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --source "$GITHUB_REPO_URL" >/dev/null 2>&1
        
    else
        log_operation "INFO" "Creating new Azure Static Web App"
        
        local result=$(az staticwebapp create \
            --name "$AZURE_APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --source "$GITHUB_REPO_URL" \
            --location "$LOCATION" \
            --branch main \
            --app-location "/" \
            --output-location "build" \
            --login-with-github \
            --output json 2>&1)
        
        if echo "$result" | jq -e '.defaultHostname' >/dev/null 2>&1; then
            SWA_HOSTNAME=$(echo "$result" | jq -r '.defaultHostname')
            log_operation "SUCCESS" "Static Web App created successfully"
            log_operation "INFO" "New URL: https://$SWA_HOSTNAME"
        else
            log_operation "ERROR" "Failed to create Static Web App"
            echo "Error details:"
            echo "$result"
            exit 1
        fi
    fi
    
    # Wait for deployment
    log_operation "INFO" "Waiting for deployment to complete..."
    
    local max_attempts=24  # 12 minutes max
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_operation "PENDING" "Checking deployment status... ($attempt/$max_attempts)"
        
        # Check if the site responds
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "https://$SWA_HOSTNAME" --max-time 10 2>/dev/null || echo "000")
        
        if [ "$http_code" = "200" ]; then
            log_operation "SUCCESS" "Deployment successful! Site is live"
            break
        elif [ "$http_code" = "000" ]; then
            log_operation "PENDING" "Site not responding yet..."
        else
            log_operation "PENDING" "Site responding with HTTP $http_code..."
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_operation "WARNING" "Deployment taking longer than expected"
            log_operation "INFO" "Check GitHub Actions: $GITHUB_REPO_URL/actions"
            log_operation "INFO" "Check Azure Portal for deployment status"
            break
        fi
        
        sleep 30
        ((attempt++))
    done
}

# Setup custom domain
setup_custom_domain() {
    log_operation "STEP" "Setting up custom domain"
    
    if [ -f "swa-custom-domain.sh" ]; then
        log_operation "INFO" "Found custom domain script - running setup"
        
        # Make sure it's executable
        chmod +x swa-custom-domain.sh
        
        # Export variables for the custom domain script
        export SWA_NAME="$AZURE_APP_NAME"
        export RESOURCE_GROUP="$RESOURCE_GROUP"
        export SWA_HOSTNAME="$SWA_HOSTNAME"
        
        echo ""
        echo -e "${YELLOW}🌐 RUNNING CUSTOM DOMAIN SETUP${NC}"
        echo "This will configure: $CUSTOM_DOMAIN"
        echo ""
        
        # Run the custom domain script
        ./swa-custom-domain.sh
        
        local script_exit_code=$?
        
        if [ $script_exit_code -eq 0 ]; then
            log_operation "SUCCESS" "Custom domain setup completed"
        else
            log_operation "WARNING" "Custom domain setup had issues (exit code: $script_exit_code)"
            log_operation "INFO" "You can run it manually later: ./swa-custom-domain.sh"
        fi
    else
        log_operation "WARNING" "Custom domain script not found (swa-custom-domain.sh)"
        echo ""
        echo "To set up $CUSTOM_DOMAIN manually:"
        echo "1. Go to Azure Portal > Static Web Apps > $AZURE_APP_NAME"
        echo "2. Click 'Custom domains' → '+ Add'"
        echo "3. Enter domain: $CUSTOM_DOMAIN"
        echo "4. Add DNS records to Cloudflare:"
        echo "   - CNAME: acs1 → $SWA_HOSTNAME"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Final summary
show_summary() {
    log_operation "STEP" "Deployment Summary"
    
    echo ""
    echo -e "${CYAN}🧪 TESTING DEPLOYMENT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Test Azure Static Web App
    echo -ne "Azure Static Web App: "
    local swa_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$SWA_HOSTNAME" --max-time 10 2>/dev/null || echo "000")
    if [ "$swa_status" = "200" ]; then
        echo -e "${GREEN}✅ LIVE (HTTP $swa_status)${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP $swa_status${NC}"
    fi
    
    # Test custom domain
    echo -ne "Custom Domain: "
    local custom_status=$(curl -s -o /dev/null -w "%{http_code}" "https://$CUSTOM_DOMAIN" --max-time 10 2>/dev/null || echo "000")
    if [ "$custom_status" = "200" ]; then
        echo -e "${GREEN}✅ LIVE (HTTP $custom_status)${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTP $custom_status${NC}"
    fi
    
    # Check GitHub Actions
    echo -ne "GitHub Actions: "
    if command -v gh >/dev/null 2>&1; then
        local workflow_status=$(gh run list --repo "$GITHUB_USERNAME/$GITHUB_REPO" --limit 1 --json status --jq '.[0].status' 2>/dev/null || echo "unknown")
        case $workflow_status in
            "completed") echo -e "${GREEN}✅ COMPLETED${NC}" ;;
            "in_progress") echo -e "${ORANGE}⏳ RUNNING${NC}" ;;
            "queued") echo -e "${YELLOW}⏳ QUEUED${NC}" ;;
            *) echo -e "${YELLOW}⚠️  CHECK MANUALLY${NC}" ;;
        esac
    else
        echo -e "${YELLOW}⚠️  CHECK MANUALLY${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${GREEN}🎉 ACS VOICEHUB PRO DEPLOYMENT COMPLETE! 🎉${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}📱 Live URLs:${NC}"
    echo "   Azure:  https://$SWA_HOSTNAME"
    echo "   Custom: https://$CUSTOM_DOMAIN"
    echo ""
    echo -e "${GREEN}🔗 Resources:${NC}"
    echo "   GitHub: $GITHUB_REPO_URL"
    echo "   Actions: $GITHUB_REPO_URL/actions"
    echo "   Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/staticSites/$AZURE_APP_NAME"
    echo ""
    echo -e "${GREEN}🚀 Next Steps:${NC}"
    echo "1. Test the application functionality"
    echo "2. Verify role-based access control"
    echo "3. Configure backend FreeSWITCH integration"
    echo "4. Set up authentication (SSO)"
    echo "5. Monitor GitHub Actions for future deployments"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Offer to open in browser
    if command -v open >/dev/null 2>&1 || command -v xdg-open >/dev/null 2>&1; then
        echo ""
        read -p "Open the application in your browser? (y/n): " open_browser
        if [[ $open_browser =~ ^[Yy] ]]; then
            if [ "$custom_status" = "200" ]; then
                if command -v open >/dev/null 2>&1; then
                    open "https://$CUSTOM_DOMAIN"
                else
                    xdg-open "https://$CUSTOM_DOMAIN"
                fi
            else
                if command -v open >/dev/null 2>&1; then
                    open "https://$SWA_HOSTNAME"
                else
                    xdg-open "https://$SWA_HOSTNAME"
                fi
            fi
        fi
    fi
}

# Main execution
main() {
    log_operation "INFO" "Starting GitHub → Azure deployment process"
    
    echo ""
    echo -e "${YELLOW}This script will:${NC}"
    echo "1. ✅ Verify your existing React app is ready"
    echo "2. 🔗 Push your code to GitHub"
    echo "3. ☁️  Deploy to Azure Static Web Apps"
    echo "4. 🌐 Configure custom domain ($CUSTOM_DOMAIN)"
    echo "5. 🧪 Test deployment and provide summary"
    echo ""
    read -p "Continue with deployment? (y/n): " confirm_deploy
    
    if [[ ! $confirm_deploy =~ ^[Yy] ]]; then
        log_operation "INFO" "Deployment cancelled by user"
        exit 0
    fi
    
    # Execute deployment steps
    check_dependencies
    detect_github_info
    verify_project
    deploy_to_github
    deploy_to_azure
    setup_custom_domain
    show_summary
    
    log_operation "SUCCESS" "Deployment process completed!"
}

# Run main function
main "$@"