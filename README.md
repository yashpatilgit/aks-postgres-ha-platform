# AKS PostgreSQL HA Platform

A production-grade Azure platform hosting a self-managed, highly available PostgreSQL cluster on Azure Kubernetes Service (AKS). Infrastructure is provisioned via Terraform, with a self-hosted PostgreSQL layer running inside Kubernetes using the CloudNativePG operator — validated with a real, measured failover test and a live reliability-monitoring application, not just theoretical HA claims.

## Overview

This project provisions a secure, multi-environment AKS platform on Microsoft Azure and deploys a 3-instance, self-healing PostgreSQL cluster on top of it. Unlike using a managed PaaS database, PostgreSQL runs **inside** the Kubernetes cluster itself via the CloudNativePG operator — a deliberately harder, more advanced setup that proves hands-on experience with stateful workloads on Kubernetes, not just container orchestration for stateless apps.

A custom **PostgreSQL Resilient Transaction Monitor**, written in Java, runs continuously against the cluster — writing a transaction every second, retrying on failure, and logging every successful write, retry, and failure with a timestamp. This turns the project's HA claim into something observable in real time: during a failover test, you can watch write attempts pause and then automatically resume as a new primary is promoted.

The platform provides:

* Multi-environment (dev/staging) AKS clusters, provisioned via Terraform
* Dedicated Azure Virtual Network with segmented subnets and NSGs
* Self-hosted, 3-instance HA PostgreSQL cluster (CloudNativePG) with automatic failover
* A live Java application continuously exercising and proving database resilience
* Centralized secrets management via Azure Key Vault
* Service Principal–based authentication with Azure RBAC
* Remote Terraform state, isolated per environment
* Azure DevOps CI/CD pipeline for infrastructure provisioning

## Architecture

> Architecture diagram to be added here.

**Design at a glance:**
- A dedicated VNet (`10.10.0.0/16`) with a separate subnet for AKS nodes (`10.10.1.0/24`) and one reserved for future private endpoints (`10.10.2.0/24`)
- An NSG on the AKS subnet that allows only intra-VNet traffic and denies direct internet inbound access
- AKS nodes provisioned inside that private subnet (verified: node internal IPs fall within `10.10.1.0/24`, with no public IP assigned)
- A CloudNativePG-managed PostgreSQL `Cluster` resource (3 instances) running as pods inside AKS, using Azure Disk CSI–backed persistent storage
- A Java application deployed as a separate pod, continuously writing to and monitoring the health of the PostgreSQL cluster
- Terraform state stored remotely in Azure Blob Storage, with a separate storage account per environment

## Azure Services Used

| Service | Purpose |
|---|---|
| **Azure Kubernetes Service (AKS)** | Container orchestration, hosts PostgreSQL and the monitoring app |
| **Azure Virtual Network** | Private network for AKS nodes |
| **Azure Subnets** | Segmentation between AKS workloads and reserved private-endpoint space |
| **Network Security Groups** | Restricts inbound traffic to intra-VNet only |
| **Azure Key Vault** | Stores the Service Principal's client secret |
| **Azure RBAC** | Service Principal authorization for provisioning resources |
| **Azure Storage** | Terraform remote state, isolated per environment |
| **Azure Disk (CSI driver)** | Persistent storage backing the PostgreSQL pods |

## Terraform Modules

```text
terraform/
├── modules/
│   ├── networking/       # VNet, subnets, NSG
│   ├── serviceprincipal/  # Azure AD Service Principal for Terraform/AKS auth
│   ├── keyvault/           # Secrets storage
│   └── aks/                 # AKS cluster, node pool, VNet integration
├── dev/
└── staging/
```

PostgreSQL and the monitoring application are deployed via Kubernetes manifests (see below), not as Terraform modules — they're managed through `kubectl`/the CloudNativePG operator rather than provisioned as raw cloud infrastructure.

## Repository Structure

```text
aks-postgres-ha-platform/
│
├── terraform/
│   ├── modules/
│   │   ├── networking/
│   │   ├── serviceprincipal/
│   │   ├── keyvault/
│   │   └── aks/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── scripts/
│   │   └── dev.sh
│   ├── provider.tf
│   └── variables.tf
│
├── k8s-manifests/
│   ├── postgresql/
│   │   ├── postgres-cluster.yaml
│   │   └── postgres-pdb.yaml
│   └── application/
│       ├── App.java
│       └── app-deployment.yaml
│
├── az-devops/
│   ├── azure-pipelines.yml
│   └── terraform-destroy.yml
│
├── .gitignore
└── README.md
```

## Technologies

* Microsoft Azure
* Azure Kubernetes Service (AKS)
* PostgreSQL (self-hosted via CloudNativePG)
* Terraform
* Kubernetes / kubectl
* Java (JDBC, PostgreSQL driver)
* Azure DevOps Pipelines
* Azure Key Vault
* Azure CLI
* Git & GitHub

## Prerequisites

```bash
az version
terraform version
kubectl version --client
git --version
```

Required: an Azure subscription, an Azure AD Service Principal with Contributor access, and Terraform remote state storage already provisioned in Azure Blob Storage.

## Deployment

Infrastructure is deployed via the Azure DevOps pipeline (`az-devops/azure-pipelines.yml`), which runs Terraform against the `dev` or `staging` directory depending on the branch/stage.

To deploy manually instead:

```bash
cd terraform/dev/    # or terraform/staging/
cp terraform.tfvars.example terraform.tfvars   # fill in your own values
terraform init
terraform plan
terraform apply
```

After the AKS cluster is provisioned:

```bash
az aks get-credentials --resource-group <resource-group-name> --name <aks-cluster-name>
kubectl get nodes -o wide
```

### Deploying PostgreSQL

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
helm upgrade --install cnpg cnpg/cloudnative-pg --namespace cnpg-system --create-namespace

kubectl apply -f k8s-manifests/postgresql/postgres-cluster.yaml
kubectl apply -f k8s-manifests/postgresql/postgres-pdb.yaml
kubectl get pods -l cnpg.io/cluster=pg-cluster
```

### Deploying the Reliability Monitor application

```bash
kubectl create configmap postgres-reliability-app --from-file=k8s-manifests/application/App.java
kubectl apply -f k8s-manifests/application/app-deployment.yaml
kubectl logs -l app=postgres-reliability-app -f
```
Watch the logs continuously — this is where the transaction retry/failure behavior becomes visible during a failover test.

## Terraform Remote State

State is stored in Azure Blob Storage, with a **separate storage account per environment** (`dev`, `staging`) under a dedicated state resource group — keeping state isolated from the environment resources it describes, and avoiding a single storage account becoming a cross-environment blast radius. State files, along with real `.tfvars` values, are excluded from source control via `.gitignore`; `.tfvars.example` files are provided instead.

## High Availability — What Was Actually Tested

The PostgreSQL cluster runs 3 CloudNativePG-managed instances (1 primary, 2 standby) with continuous streaming replication. Resource requests and limits are configured on the PostgreSQL pods, and a PodDisruptionBudget (`minAvailable: 2`) prevents routine Kubernetes maintenance operations from taking down more than one replica at a time.

**Failover was validated with a real, timed test**, not just assumed from configuration:
- The active primary pod was deleted manually to simulate an unplanned failure
- CloudNativePG automatically detected the loss and promoted a standby to primary
- **Measured recovery time: ~2 seconds**, timestamped via a scripted check rather than eyeballed
- Verified the new primary was a genuinely different, previously-untouched instance — not the same pod restarting
- The **Reliability Monitor** application (see below) provides a live, continuous view of this: transaction write attempts, retries, and failures are logged in real time, so the failover's impact on live traffic is directly observable, not inferred

This was validated in the `staging` environment; `dev` currently runs the base AKS/networking setup but has not yet had the PostgreSQL layer or application applied.

## The Reliability Monitor Application

A small Java application (`k8s-manifests/application/App.java`) runs as its own pod inside the cluster and continuously exercises the database:
- Writes a transaction to a `reliability_events` table roughly once per second
- Automatically retries on connection failure, with a bounded retry count
- Logs every successful transaction, retry, and failure with a timestamp
- Waits for the database to become reachable on startup rather than crash-looping

This exists specifically to make the HA claim demonstrable, not just testable once — running it during a live failover shows write attempts failing/retrying for the duration of the failover window, then resuming automatically once a new primary is elected.

## Security

* Service Principal authentication, with credentials stored in Azure Key Vault (never committed to source control)
* Real `.tfvars` files are excluded from source control; `.tfvars.example` files with placeholder values are provided instead
* NSG on the AKS subnet denies direct internet inbound traffic; only intra-VNet traffic is permitted
* AKS nodes run in a private subnet with no public IP assigned
* **Design decision on RBAC scope:** the Terraform Service Principal is currently assigned the Contributor role at the subscription level rather than a single resource group. This is because AKS auto-provisions a second, separate "node resource group" at cluster creation time — a resource group that doesn't exist yet when the role assignment is first created, making a narrower pre-scoped assignment non-trivial. In a production environment, the recommended next step would be to pre-create both resource groups explicitly in Terraform and scope two separate role assignments accordingly.

## Known Limitations & Roadmap

This project is intentionally scoped and documented honestly — the following are either partial or not yet built:

* **Node-level pod anti-affinity** — [NEEDS CONFIRMATION: is this currently `required` and working across multiple nodes, or `preferred` due to the regional vCPU quota limit hit earlier? Update this line accordingly.]
* **Backups & PITR** — WAL archiving and point-in-time recovery to Azure Blob Storage
* **Broader monitoring & alerting** — Prometheus/Grafana or Azure Monitor integration for cluster-wide metrics, beyond the application-level logging the Reliability Monitor already provides
* **GitOps** — Argo CD-based deployment for the Kubernetes manifests
* **Extending `dev` environment** — applying the networking, PostgreSQL, and application layers currently only present in `staging`

## Engineering Practices Demonstrated

* Infrastructure as Code with modular, reusable Terraform
* Kubernetes administration, including stateful workload management
* Self-hosted database high availability inside Kubernetes (not reliant on managed PaaS)
* Private-network-first Azure architecture
* Multi-environment infrastructure with isolated state
* CI/CD for infrastructure via Azure DevOps
* Application-level resilience engineering — a custom monitoring tool built specifically to prove infrastructure claims, not just configure them
* Honest scoping and documentation of both what's implemented and what remains — including a documented, reasoned tradeoff on RBAC scope rather than a default choice

## Author

**Yash Patil**
Cloud Database Engineer | Azure | Terraform | Kubernetes | PostgreSQL
