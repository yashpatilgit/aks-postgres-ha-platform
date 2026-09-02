# AKS PostgreSQL HA Platform

A production-grade Azure cloud platform designed to host highly available containerized workloads with a resilient PostgreSQL database layer. The entire infrastructure is provisioned and managed using Terraform, following Infrastructure as Code, security, scalability, and high-availability best practices.

## Overview

This project implements a secure and highly available application platform on **Microsoft Azure** using **Azure Kubernetes Service (AKS)** and **PostgreSQL**.

The platform provides:

* Highly available AKS cluster
* PostgreSQL high-availability architecture
* Secure Azure networking
* Private connectivity for database workloads
* Managed identities and Azure RBAC
* Centralized secrets management
* Load balancing and scalable compute
* Monitoring and observability
* Automated infrastructure provisioning using Terraform

## Architecture

> Architecture diagram will be added here.

## Azure Services

| Service                            | Purpose                                           |
| ---------------------------------- | ------------------------------------------------- |
| **Azure Kubernetes Service (AKS)** | Container orchestration and application workloads |
| **Azure Database for PostgreSQL**  | Managed PostgreSQL database layer                 |
| **Azure Virtual Network**          | Private network architecture                      |
| **Azure Subnets**                  | Network segmentation                              |
| **Network Security Groups**        | Network-level security controls                   |
| **Azure Load Balancer**            | Traffic distribution and high availability        |
| **Azure Key Vault**                | Secure secrets and credential management          |
| **Managed Identity**               | Passwordless Azure service authentication         |
| **Azure RBAC**                     | Identity and access management                    |
| **Azure Monitor**                  | Infrastructure and application monitoring         |
| **Log Analytics**                  | Centralized logging and observability             |
| **Azure Storage**                  | Terraform remote state management                 |

## Key Features

### High Availability

The platform is designed to eliminate single points of failure across the compute and database layers.

* Multi-node AKS architecture
* Availability-aware infrastructure design
* PostgreSQL primary/standby architecture
* Automated recovery capabilities
* Load-balanced application access
* Resilient network architecture

### Secure Networking

The infrastructure follows a private-first networking approach.

* Dedicated Azure Virtual Network
* Segmented subnets
* Network Security Groups
* Private database connectivity
* Restricted inbound and outbound traffic
* Controlled communication between application and database tiers

### Infrastructure as Code

All Azure infrastructure is managed through **Terraform**.

Terraform provides:

* Declarative infrastructure management
* Repeatable deployments
* Infrastructure version control
* Dependency management
* Consistent environments
* Automated provisioning and destruction

## Terraform Modules

The infrastructure is organized into reusable Terraform modules:

```text
modules/
├── networking/
├── aks/
├── postgresql/
├── key-vault/
├── monitoring/
└── load-balancer/
```

This modular approach allows infrastructure components to be independently maintained, reused, and extended.

## Repository Structure

```text
aks-postgres-ha-platform/
│
├── modules/
│   ├── networking/
│   ├── aks/
│   ├── postgresql/
│   ├── key-vault/
│   ├── monitoring/
│   └── load-balancer/
│
├── environments/
│   ├── dev/
│   └── prod/
│
├── scripts/
│
├── backend.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── main.tf
├── .gitignore
└── README.md
```

## Technologies

* **Microsoft Azure**
* **Azure Kubernetes Service**
* **PostgreSQL**
* **Terraform**
* **Kubernetes**
* **Azure CLI**
* **kubectl**
* **Git & GitHub**
* **Azure Key Vault**
* **Azure Monitor**
* **Log Analytics**

## Prerequisites

The following tools are required:

```bash
az version
terraform version
kubectl version --client
git --version
```

Required:

* Azure subscription
* Azure CLI
* Terraform
* kubectl
* Git

## Azure Authentication

Terraform uses an **Azure Service Principal** for infrastructure authentication.

Required environment variables:

```bash
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

Credentials and secrets are never stored directly in Terraform configuration files or committed to Git.

## Deployment

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt -recursive
```

Validate the configuration:

```bash
terraform validate
```

Review the deployment plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

After deployment, configure Kubernetes access:

```bash
az aks get-credentials \
  --resource-group <resource-group-name> \
  --name <aks-cluster-name>
```

Verify the cluster:

```bash
kubectl get nodes
```

Verify workloads:

```bash
kubectl get pods -A
```

## Terraform Remote State

Terraform state is maintained remotely using **Azure Blob Storage**.

Remote state provides:

* Centralized state management
* State persistence
* State locking
* Safer collaborative deployments
* Separation of infrastructure code and state

Terraform state files are excluded from source control.

## Security

Security is incorporated across the infrastructure layers.

* Service Principal authentication
* Azure RBAC
* Managed identities
* Azure Key Vault
* Private database connectivity
* Network Security Groups
* Network segmentation
* Least-privilege access
* Sensitive variables protected from source control

## Observability

Azure monitoring capabilities provide visibility into the platform.

Monitoring covers:

* AKS cluster health
* Node utilization
* Pod and workload health
* PostgreSQL metrics
* Network activity
* Infrastructure logs
* Application logs
* Resource health

Logs and metrics are centralized through **Azure Monitor** and **Log Analytics**.

## Disaster Recovery & Resilience

The platform incorporates resilience principles at both the compute and database layers.

* Redundant Kubernetes nodes
* Load-balanced workloads
* PostgreSQL replication
* Automated recovery mechanisms
* Infrastructure reproducibility through Terraform
* Remote Terraform state
* Separation of application and database tiers

## Engineering Practices

This project demonstrates practical implementation of:

* Infrastructure as Code
* Cloud platform engineering
* Kubernetes administration
* PostgreSQL high availability
* Azure networking
* Cloud security
* Identity and access management
* Infrastructure modularization
* Remote Terraform state management
* Monitoring and observability
* Production-oriented cloud architecture

## Author

**Yash Patil**

Cloud Database Engineer | Azure | Terraform | Kubernetes | PostgreSQL
