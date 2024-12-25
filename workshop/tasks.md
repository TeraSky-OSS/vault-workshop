# Vault Workshop

Welcome to the Vault Workshop! This workshop is designed to provide both theoretical knowledge and hands-on experience with HashiCorp Vault, focusing on its architecture, use cases, and various secrets management features.

## Course Overview

This workshop is structured into multiple topics, each covering different aspects of Vault. You will learn about Vault’s internals, secret engines, authentication methods, dynamic secrets, and more. Along with the theory, you will engage in practical exercises to reinforce your understanding and skills.

### Agenda

#### Introduction to Vault and Setup
- **Introduction to Secret Management** (Theory)
  - Overview of Vault internals and architecture (unseal, storage backend, auth, audit, snapshots, namespaces)
  - Vault replication (Standby, DR, Performance)
  - Deep dive into Secret Engines
- **Setting up a Vault Cluster on Kubernetes** (Hands-On)
  - Vault interfaces (CLI, UI, API)
  - Authentication methods (userpass, AppRole, token, LDAP, Kubernetes)
  - Vault Policies (Hands-On)

#### Dynamic Secrets and Use Cases
- **KV Secrets – v1 and v2** (Hands-On)
- **Dynamic Secrets**:
  - Database (Postgres, Mongo) (Hands-On)
  - Cloud Account - AWS (Hands-On)
  - SSH Keys (Demo)
  - LDAP (Demo)
  - Kubernetes Secrets Engine (Demo)
- **Vault Secrets Operator for Kubernetes** (Demo)

#### Advanced Vault Features and Use Cases
- **Understanding Sentinel Policies** (Demo)
- **Vault Auditing and Monitoring** (Demo)
  - Focus on Grafana for performance monitoring
- **Vault Backup – Snapshot and Recovery** (Hands-On)
  - Automatic Backups (Demo)
  - Vault Agent Deployment (Demo)
- **PKI and ADP Use Cases** (Demo)
  - KMIP, DB and appliance encryption, FPE


## Hands-On Tasks

Throughout this workshop, you will complete various hands-on exercises to implement what you learn. These tasks will include:
- Setting up Vault on Kubernetes
- Configuring different authentication methods
- Working with KV secrets and dynamic secrets engines
- Auditing, monitoring, and backing up Vault


By the end of this workshop, you will have a solid understanding of how to use Vault for secure secret management and how to implement it in a production environment.


Next: [prerequisites](./tasks/00-prerequisites.md)
