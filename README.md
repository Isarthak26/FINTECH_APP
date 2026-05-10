# 🏦 Fintech DevOps — Azure Multi-Service Deployment

<div align="center">

![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

A **production-grade**, highly available, and scalable microservices fintech application deployed on **Azure Kubernetes Service (AKS)** with full GitOps automation, infrastructure-as-code, and multi-region failover support.

</div>

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Prerequisites](#-prerequisites)
- [Local Development Setup](#-local-development-setup)
- [Docker Build & Push](#-docker-build--push)
- [Infrastructure Provisioning (Terraform)](#-infrastructure-provisioning-terraform)
- [Kubernetes Deployment Setup](#-kubernetes-deployment-setup)
- [CI/CD Pipeline Setup](#-cicd-pipeline-setup)
- [Monitoring & Logging](#-monitoring--logging)
- [Scaling & Auto-Scaling](#-scaling--auto-scaling)
- [Rollback Strategies](#-rollback-strategies)
- [Multi-Region Failover](#-multi-region-failover)
- [Cost Optimization](#-cost-optimization)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)

---

## 🏗️ Architecture Overview

```
                        ┌─────────────────────────────────────────┐
                        │         Azure Traffic Manager            │
                        │   (Priority-based multi-region routing)  │
                        └──────────────┬──────────────┬───────────┘
                                       │              │
                     ┌─────────────────▼──┐    ┌──────▼─────────────┐
                     │   Region: eastus    │    │  Region: eastus2   │
                     │   (Primary AKS)     │    │  (Failover AKS)    │
                     └────────┬───────────┘    └──────────┬─────────┘
                              │                            │
              ┌───────────────▼─────────────┐             │
              │   Azure Kubernetes Service   │             │
              │                             │             │
              │  ┌──────────┐ ┌──────────┐  │             │
              │  │ Frontend │ │ Backend  │  │             │
              │  │  nginx   │ │ Node.js  │  │             │
              │  │ :80      │ │ :3000    │  │             │
              │  └──────────┘ └────┬─────┘  │             │
              │                   │         │             │
              └───────────────────┼─────────┘             │
                                  │                        │
              ┌───────────────────▼────────────────────┐   │
              │  Azure DB for PostgreSQL Flexible Server│◄──┘
              │     (Primary)          (Read Replica)   │
              └─────────────────────────────────────────┘

  CI/CD Flow:
  GitHub Push → GitHub Actions (CI) → ACR → ArgoCD (CD) → AKS
  Terraform manages: AKS, ACR, PostgreSQL, VNet, Monitoring
```

### Component Breakdown

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend** | Static HTML + nginx | Serves UI on port 80 |
| **Backend** | Node.js + Express | REST API on port 3000 |
| **Database** | Azure PostgreSQL Flexible Server | Persistent data store |
| **Orchestration** | Azure Kubernetes Service (AKS) | Container orchestration |
| **Registry** | Azure Container Registry (ACR) | Private image storage |
| **CI/CD** | GitHub Actions + ArgoCD | GitOps-driven automation |
| **IaC** | Terraform (modular) | Repeatable infra provisioning |
| **Failover** | Azure Traffic Manager | DNS-level multi-region routing |

---

## 🛠️ Tech Stack

- **Cloud:** Microsoft Azure (AKS, ACR, PostgreSQL, Traffic Manager, Log Analytics)
- **Containers:** Docker, Kubernetes
- **IaC:** Terraform >= 1.2.0 with remote state on Azure Blob Storage
- **GitOps:** ArgoCD for continuous delivery
- **CI/CD:** GitHub Actions (separate CI and CD workflows)
- **Backend Runtime:** Node.js 20+ with Express
- **Database:** PostgreSQL 15 (Azure Flexible Server)
- **Autoscaling:** Kubernetes Horizontal Pod Autoscaler (HPA)

---

## 📁 Repository Structure

```
fintech-devops/
├── .github/
│   └── workflows/
│       ├── ci.yml              # Build, test & push images to ACR
│       └── cd.yml              # Trigger ArgoCD sync via API
│
├── backend/
│   ├── Dockerfile              # Multi-stage Node.js build
│   ├── server.js               # Express REST API
│   └── package.json
│
├── frontend/
│   ├── Dockerfile              # nginx serving static HTML
│   └── index.html
│
├── k8s/
│   └── web-app/
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── backend-hpa.yaml    # Horizontal Pod Autoscaler
│       ├── frontend-deployment.yaml
│       ├── frontend-service.yaml
│       ├── frontend-hpa.yaml
│       └── argocd-app.yaml     # ArgoCD Application manifest
│
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   └── backend.tf.example
│   │   └── prod/               # Mirrors dev structure
│   │
│   └── modules/
│       ├── network/main.tf     # VNet, subnets
│       ├── aks/main.tf         # AKS cluster
│       ├── postgres/main.tf    # PostgreSQL Flexible Server
│       └── monitoring/main.tf  # Log Analytics workspace
│
├── .dockerignore
├── .gitignore
├── index.html
├── init-db.js
├── package.json
└── README.md
```

---

## ✅ Prerequisites

### Local Tooling

| Tool | Version | Install |
|---|---|---|
| Node.js | 20+ | [nodejs.org](https://nodejs.org) |
| Docker | Latest | [docker.com](https://docker.com) |
| Docker Compose | Latest | Included with Docker Desktop |
| Terraform | >= 1.2.0 | [terraform.io](https://terraform.io) |
| Azure CLI | Latest | `brew install azure-cli` or [docs](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| kubectl | Latest | `az aks install-cli` |
| ArgoCD CLI | Latest | [argo-cd.readthedocs.io](https://argo-cd.readthedocs.io/en/stable/cli_installation/) |
| Git | Latest | [git-scm.com](https://git-scm.com) |

### Azure Requirements

- Active Azure subscription
- Service Principal with **Contributor** role on the target subscription
- Resource Group pre-created for Terraform remote state storage

---

## 💻 Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Isarthak26/FINTECH_APP.git
cd FINTECH_APP
```

### 2. Install Backend Dependencies

```bash
cd backend
npm install
```

> The frontend is pure static HTML — no npm dependencies required.

### 3. Start PostgreSQL Locally via Docker

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=fintech \
  -p 5432:5432 \
  postgres:15-alpine
```

Verify it's running:

```bash
docker ps | grep postgres
```

### 4. Run the Backend

```bash
cd backend
npm start
# API available at http://localhost:3000
```

### 5. Serve the Frontend

```bash
cd frontend
python3 -m http.server 8080
# Frontend available at http://localhost:8080
```

---

## 🐳 Docker Build & Push

### Build Images Locally

```bash
# Backend image
docker build -t fintech/backend:latest ./backend

# Frontend image
docker build -t fintech/frontend:latest ./frontend
```

### Push to Azure Container Registry

```bash
# Authenticate with ACR
az acr login --name <your-acr-name>

# Tag for ACR
docker tag fintech/backend:latest <acr-name>.azurecr.io/fintech/backend:latest
docker tag fintech/frontend:latest <acr-name>.azurecr.io/fintech/frontend:latest

# Push
docker push <acr-name>.azurecr.io/fintech/backend:latest
docker push <acr-name>.azurecr.io/fintech/frontend:latest
```

---

## ☁️ Infrastructure Provisioning (Terraform)

Terraform is organized into reusable modules (`network`, `aks`, `postgres`, `monitoring`) and separate `dev` and `prod` environment configurations. Remote state is stored in Azure Blob Storage.

### Step 1 — Bootstrap Remote State Backend

```bash
# Create resource group for state storage
az group create --name rg-terraform-state --location eastus

# Create storage account (name must be globally unique)
az storage account create \
  --name <unique-storage-account-name> \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --name tfstate \
  --account-name <unique-storage-account-name>
```

### Step 2 — Configure Terraform Backend

```bash
# Copy the example backend config and fill in your values
cp terraform/environments/dev/backend.tf.example terraform/environments/dev/backend.tf

# Edit backend.tf with your storage account name, resource group, and container
```

### Step 3 — Deploy Dev Environment

```bash
cd terraform/environments/dev

terraform init          # Initialize providers and remote state
terraform plan -out=tfplan   # Preview changes
terraform apply tfplan       # Apply

# Retrieve outputs (ACR login server, AKS name, PostgreSQL FQDN)
terraform output
```

### Step 4 — Deploy Prod Environment

```bash
cd terraform/environments/prod

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

> **Tip:** Terraform outputs include the ACR login server, AKS cluster name, and PostgreSQL FQDN — save these for subsequent steps.

---

## ☸️ Kubernetes Deployment Setup

### 1. Authenticate with AKS

```bash
az aks get-credentials \
  --resource-group fintech-dev-rg \
  --name fintech-dev-aks

# Verify connectivity
kubectl get nodes
```

### 2. Create Kubernetes Secrets

```bash
kubectl create secret generic fintech-secrets \
  --from-literal=db_host=<postgres-fqdn> \
  --from-literal=db_user=postgres \
  --from-literal=db_password=<your-db-password>
```

### 3. Install ArgoCD

```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s

# Retrieve the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Access the ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080  (username: admin)
```

### 4. Deploy Applications via ArgoCD

```bash
# Register the application with ArgoCD
kubectl apply -f k8s/web-app/argocd-app.yaml

# Verify sync status
argocd app get web-app

# Manually trigger a sync if needed
argocd app sync web-app
```

---

## 🔄 CI/CD Pipeline Setup

The pipeline uses two separate GitHub Actions workflows:

- **`ci.yml`** — Runs on every push to `main`: lints, tests, builds Docker images, and pushes to ACR.
- **`cd.yml`** — Triggered by a `repository_dispatch` event from CI: calls the ArgoCD API to sync the application.

### Pipeline Flow

```
git push → GitHub Actions CI
              ↓
         Run tests
              ↓
         docker build + push → ACR
              ↓
         Trigger repository_dispatch
              ↓
         GitHub Actions CD
              ↓
         ArgoCD API sync call
              ↓
         ArgoCD pulls manifests from Git → applies to AKS
```

### Step 1 — Add GitHub Repository Secrets

Navigate to **Settings → Secrets and variables → Actions** and add:

| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | JSON output from `az ad sp create-for-rbac --sdk-auth` |
| `ACR_LOGIN_SERVER` | e.g. `myregistry.azurecr.io` |
| `ARGOCD_SERVER` | ArgoCD server endpoint (IP or DNS) |
| `ARGOCD_TOKEN` | ArgoCD API token |
| `GH_TOKEN` | GitHub Personal Access Token (for dispatch) |

### Step 2 — Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name github-actions \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Paste the full JSON output into the AZURE_CREDENTIALS secret
```

### Step 3 — Generate ArgoCD API Token

```bash
# Option A: Generate token for a dedicated CI account
argocd account generate-token --account github-actions

# Option B: Use the admin token obtained during ArgoCD installation
```

### Step 4 — Trigger the Pipeline

```bash
git add .
git commit -m "feat: deploy updated backend and frontend"
git push origin main
```

---

## 📊 Monitoring & Logging

### View Live Application Logs

```bash
# Backend logs (streaming)
kubectl logs deployment/fintech-backend -f

# Frontend logs (streaming)
kubectl logs deployment/fintech-frontend -f

# Logs from a specific pod
kubectl logs <pod-name> -n default
```

### Check Application Health

```bash
# List all deployments and their readiness
kubectl get deployments

# List all services and their endpoints
kubectl get svc

# Check HPA status
kubectl get hpa

# Full deployment event log (useful for debugging)
kubectl describe deployment fintech-backend
kubectl describe deployment fintech-frontend
```

### Access ArgoCD Dashboard

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

> **Note:** Terraform provisions an **Azure Log Analytics Workspace** via the `monitoring` module. Application logs are forwarded automatically when using AKS with the OMS agent enabled.

---

## 📈 Scaling & Auto-Scaling

### Manual Scaling

```bash
# Scale backend to 5 replicas manually
kubectl scale deployment fintech-backend --replicas=5
```

### Horizontal Pod Autoscaler (HPA)

The HPA automatically adjusts replica counts based on CPU utilization.

```bash
# View current HPA status
kubectl get hpa

# Inspect HPA events and configuration
kubectl describe hpa fintech-backend-hpa
```

### Adjust HPA Thresholds

Edit `k8s/web-app/backend-hpa.yaml`:

```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60   # Scale up when CPU exceeds 60%
```

Apply the change:

```bash
kubectl apply -f k8s/web-app/backend-hpa.yaml
```

### Check Node & Pod Resource Usage

```bash
kubectl top nodes
kubectl top pods
```

> **Prerequisite:** The `metrics-server` must be running in `kube-system`. Verify with:
> ```bash
> kubectl get deployment metrics-server -n kube-system
> ```

---

## ↩️ Rollback Strategies

### Option A — Rollback via ArgoCD (Recommended)

```bash
# View deployment revision history
argocd app history web-app

# Rollback to a specific revision (e.g., revision 1)
argocd app rollback web-app 1
```

### Option B — Rollback via Kubernetes

```bash
# View rollout history for the backend deployment
kubectl rollout history deployment/fintech-backend

# Rollback to the previous revision
kubectl rollout undo deployment/fintech-backend

# Rollback to a specific revision
kubectl rollout undo deployment/fintech-backend --to-revision=1

# Monitor rollback status
kubectl rollout status deployment/fintech-backend
```

---

## 🌍 Multi-Region Failover

The production setup spans two Azure regions with automatic DNS failover:

| Role | Region |
|---|---|
| Primary | `eastus` |
| Secondary (Failover) | `eastus2` |

### Configure Azure Traffic Manager

```bash
# Create the Traffic Manager profile with Priority routing
az network traffic-manager profile create \
  --name fintech-tm \
  --resource-group fintech-prod-rg \
  --routing-method Priority

# Add primary endpoint (priority 1 = preferred)
az network traffic-manager endpoint create \
  --name primary \
  --profile-name fintech-tm \
  --resource-group fintech-prod-rg \
  --type azureEndpoints \
  --target <primary-alb-fqdn> \
  --priority 1

# Add secondary endpoint (priority 2 = failover)
az network traffic-manager endpoint create \
  --name secondary \
  --profile-name fintech-tm \
  --resource-group fintech-prod-rg \
  --type azureEndpoints \
  --target <secondary-alb-fqdn> \
  --priority 2
```

### Configure PostgreSQL Geo-Replication

```bash
# Create a read replica in the secondary region
az postgres flexible-server replica create \
  --replica-name fintech-pg-replica \
  --source-server fintech-prod-pg \
  --resource-group fintech-prod-rg \
  --location eastus2
```

> During a failover event, promote the read replica to primary via `az postgres flexible-server replica stop-replication` and update the backend's `DB_HOST` secret.

---

## 💰 Cost Optimization

| Strategy | Impact |
|---|---|
| Use **Spot VMs** in AKS node pools | Up to 90% savings on non-critical nodes |
| **Scheduled scale-down** during off-hours | Reduces idle node costs |
| Use **Azure Reserved Instances** for predictable workloads | Up to 72% savings over pay-as-you-go |
| Clean up **stale ACR image tags** regularly | Reduces storage costs |
| Set **Log Analytics retention** to 30 days | Minimizes analytics storage spend |

---

## 🔧 Troubleshooting

### Backend Cannot Connect to PostgreSQL

**Symptoms:** `ECONNREFUSED` or `FATAL: password authentication failed` errors in backend logs.

```bash
# 1. Verify the secret exists and has correct values
kubectl get secret fintech-secrets -o yaml

# 2. Decode and inspect a specific field
kubectl get secret fintech-secrets \
  -o jsonpath='{.data.db_host}' | base64 -d && echo

# 3. Test connectivity directly from the backend pod
kubectl exec -it deployment/fintech-backend -- bash
# Inside the pod:
psql -h $DB_HOST -U $DB_USER -d fintech
```

---

### Images Not Pulling from ACR (`ImagePullBackOff`)

**Symptoms:** Pods stuck in `ImagePullBackOff` or `ErrImagePull` state.

```bash
# 1. Describe the failing pod for the exact error
kubectl describe pod <pod-name>

# 2. Check if image pull secrets are attached
kubectl get secrets

# 3. Re-authenticate AKS with ACR (attaches pull permission via Managed Identity)
az aks update \
  --name fintech-dev-aks \
  --resource-group fintech-dev-rg \
  --attach-acr <acr-name>

# 4. Verify ACR access locally
az acr login --name <acr-name>
```

---

### ArgoCD Not Syncing

**Symptoms:** ArgoCD shows `OutOfSync` or sync never completes.

```bash
# 1. Check application sync status and events
argocd app get web-app

# 2. View ArgoCD server logs for errors
kubectl logs -n argocd deployment/argocd-server

# 3. Force a manual sync
argocd app sync web-app --force

# 4. Check if the target namespace exists
kubectl get namespace
```

---

### HPA Not Scaling

**Symptoms:** HPA shows `<unknown>/60%` for CPU or replicas never increase under load.

```bash
# 1. Verify metrics-server is running
kubectl get deployment metrics-server -n kube-system

# 2. Check HPA events for errors
kubectl describe hpa fintech-backend-hpa

# 3. Check current resource usage
kubectl top nodes
kubectl top pods

# 4. Ensure resource requests are defined in deployment manifests
# HPA requires `resources.requests.cpu` to be set on the container
kubectl describe deployment fintech-backend | grep -A5 Requests
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ by [Isarthak26](https://github.com/Isarthak26)

</div>
