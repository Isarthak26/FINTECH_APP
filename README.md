# Fintech DevOps - Azure Multi-Service Deployment

A highly available, scalable microservices-based fintech application deployed on Azure with Kubernetes (AKS), PostgreSQL, and GitOps (ArgoCD).

## Architecture Overview

- **Frontend**: Static HTML served via nginx (port 80)
- **Backend**: Node.js Express API (port 3000)
- **Database**: Azure Database for PostgreSQL Flexible Server
- **Orchestration**: Azure Kubernetes Service (AKS)
- **Registry**: Azure Container Registry (ACR)
- **CI/CD**: GitHub Actions + ArgoCD
- **IaC**: Terraform (modular design)

## Prerequisites

### Local Development
- Node.js 20+
- Docker & Docker Compose
- Terraform >= 1.2.0
- Azure CLI
- kubectl
- Git

### Azure
- Azure subscription
- Service Principal with Contributor role
- Resource Group for Terraform state

## Local Development Setup

### 1. Install Dependencies

```bash
cd backend
npm install
cd ../frontend
# Frontend is static (no npm deps)
```

### 2. Start PostgreSQL Locally (Docker)

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=fintech \
  -p 5432:5432 \
  postgres:15-alpine
```

### 3. Run Backend Service

```bash
cd backend
npm start
# Backend runs on http://localhost:3000
```

### 4. Serve Frontend Locally

```bash
cd frontend
python3 -m http.server 8080
# Frontend runs on http://localhost:8080
```

## Docker Build & Push

### Build Images Locally

```bash
# Backend image
docker build -t fintech/backend:latest ./backend

# Frontend image
docker build -t fintech/frontend:latest ./frontend
```

### Push to Azure Container Registry

```bash
# Login to ACR
az acr login --name <your-acr-name>

# Tag images
docker tag fintech/backend:latest <acr-name>.azurecr.io/fintech/backend:latest
docker tag fintech/frontend:latest <acr-name>.azurecr.io/fintech/frontend:latest

# Push
docker push <acr-name>.azurecr.io/fintech/backend:latest
docker push <acr-name>.azurecr.io/fintech/frontend:latest
```

## Infrastructure Provisioning (Terraform)

### 1. Set Up Remote State

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location eastus

# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name tfstate \
  --account-name mystorageaccount
```

### 2. Configure Backend

```bash
# Copy backend.tf.example to backend.tf and update values
cp terraform/environments/dev/backend.tf.example terraform/environments/dev/backend.tf

# Edit backend.tf with your storage account details
```

### 3. Deploy Infrastructure (Dev)

```bash
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Capture outputs (ACR, AKS, PostgreSQL)
terraform output
```

### 4. Deploy Infrastructure (Prod)

```bash
cd terraform/environments/prod

# Repeat init, plan, apply steps
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Kubernetes Deployment Setup

### 1. Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group fintech-dev-rg \
  --name fintech-dev-aks
```

### 2. Create Kubernetes Secrets

```bash
kubectl create secret generic fintech-secrets \
  --from-literal=db_host=<postgres-fqdn> \
  --from-literal=db_user=postgres \
  --from-literal=db_password=<password>
```

### 3. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 4. Deploy Applications via ArgoCD

```bash
# Create ArgoCD application
kubectl apply -f k8s/web-app/argocd-app.yaml

# Verify sync status
argocd app get web-app
```

## CI/CD Pipeline Setup

### 1. Create GitHub Secrets

In your GitHub repository, add these secrets:

```
AZURE_CREDENTIALS         # JSON from `az ad sp create-for-rbac`
ACR_LOGIN_SERVER          # Your ACR login server
ACR_USERNAME              # ACR username
ACR_PASSWORD              # ACR password
ARGOCD_SERVER             # ArgoCD server endpoint
ARGOCD_TOKEN              # ArgoCD authentication token
GH_TOKEN                  # GitHub personal access token
```

### 2. Obtain Azure Service Principal Credentials

```bash
az ad sp create-for-rbac \
  --name github-actions \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>

# Output: Copy the JSON to AZURE_CREDENTIALS secret
```

### 3. Get ArgoCD Token

```bash
argocd account generate-token --account github-actions
# Or use existing admin token from step 3 above
```

### 4. Trigger CI/CD

Push to `main` branch:

```bash
git add .
git commit -m "Deploy backend and frontend"
git push origin main
```

**Pipeline flow:**
1. GitHub Actions CI runs tests, builds images, pushes to ACR
2. CI triggers `repository_dispatch` event
3. CD workflow calls ArgoCD API to sync applications
4. ArgoCD pulls latest manifests from Git and updates K8s

## Monitoring & Logging

### View Application Logs

```bash
# Backend logs
kubectl logs deployment/fintech-backend -f

# Frontend logs
kubectl logs deployment/fintech-frontend -f
```

### Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

### Check Application Status

```bash
# Get deployments
kubectl get deployments

# Get services
kubectl get svc

# Get HPA status
kubectl get hpa

# Describe deployment for events
kubectl describe deployment fintech-backend
```

## Scaling & Auto-Scaling

### Manual Scaling

```bash
kubectl scale deployment fintech-backend --replicas=5
```

### Check HPA Status

```bash
kubectl get hpa
kubectl describe hpa fintech-backend-hpa
```

### Adjust HPA Thresholds

Edit `k8s/web-app/hpa.yaml`:

```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60  # Adjust this value
```

Then apply:

```bash
kubectl apply -f k8s/web-app/hpa.yaml
```

## Rollback

### Rollback via ArgoCD

```bash
# View revision history
argocd app history web-app

# Rollback to previous revision
argocd app rollback web-app 1
```

### Rollback via Kubernetes

```bash
kubectl rollout history deployment/fintech-backend
kubectl rollout undo deployment/fintech-backend --to-revision=1
```

## Multi-Region Failover

### Primary Region: eastus
### Secondary Region: eastus2

### Setup Azure Traffic Manager

```bash
# Create Traffic Manager profile (via Azure Portal or CLI)
az network traffic-manager profile create \
  --name fintech-tm \
  --resource-group fintech-prod-rg \
  --routing-method Priority

# Add endpoints (primary and secondary)
az network traffic-manager endpoint create \
  --name primary \
  --profile-name fintech-tm \
  --resource-group fintech-prod-rg \
  --type azureEndpoints \
  --target <primary-alb-fqdn> \
  --priority 1

az network traffic-manager endpoint create \
  --name secondary \
  --profile-name fintech-tm \
  --resource-group fintech-prod-rg \
  --type azureEndpoints \
  --target <secondary-alb-fqdn> \
  --priority 2
```

### Setup Database Geo-Replication

```bash
# Create read replica in secondary region (via Azure Portal or CLI)
az postgres flexible-server replica create \
  --replica-name fintech-pg-replica \
  --source-server fintech-prod-pg \
  --resource-group fintech-prod-rg \
  --location eastus2
```

## Troubleshooting

### Backend can't connect to PostgreSQL

```bash
# Check secrets
kubectl get secrets fintech-secrets -o yaml

# Test connectivity from pod
kubectl exec -it deployment/fintech-backend -- bash
psql -h <db-host> -U postgres -d fintech
```

### Images not pulling from ACR

```bash
# Check image pull secrets
kubectl get secrets

# Verify ACR credentials
az acr login --name <acr-name>
```

### ArgoCD not syncing

```bash
# Check ArgoCD app status
argocd app get web-app

# View ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server
```

### HPA not scaling

```bash
# Check metrics-server
kubectl get deployment metrics-server -n kube-system

# Check HPA status and events
kubectl describe hpa fintech-backend-hpa
kubectl top nodes
kubectl top pods
```

## Cost Optimization Tips

1. **Use spot VMs** in AKS node pools for non-critical workloads
2. **Scale down during off-hours** with scheduled cluster auto-scaling
3. **Use Azure reserved instances** for predictable workloads
4. **Monitor ACR storage** and clean up old image tags
5. **Use Log Analytics with 30-day retention** (adjust as needed)

## Directory Structure

```
fintech-devops/
├── .github/workflows/
│   ├── ci.yml              # Build & push images
│   └── cd.yml              # ArgoCD sync trigger
├── backend/
│   ├── Dockerfile          # Multi-stage Node.js build
│   ├── server.js           # Express API
│   └── package.json
├── frontend/
│   ├── Dockerfile          # nginx + static HTML
│   └── index.html
├── k8s/web-app/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── backend-hpa.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── frontend-hpa.yaml
│   └── argocd-app.yaml
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   └── backend.tf.example
│   │   └── prod/
│   │       └── (same structure as dev)
│   └── modules/
│       ├── network/main.tf
│       ├── aks/main.tf
│       ├── postgres/main.tf
│       └── monitoring/main.tf
└── README.md
```

## License

MIT
