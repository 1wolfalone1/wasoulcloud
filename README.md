# wacloud

**wacloud** is a self-hosted Infrastructure-as-a-Service (IaaS) platform designed to transform bare-metal or virtualized hardware into a private cloud. By leveraging industry-standard cloud-native technologies, **wacloud** provides a seamless experience for managing Virtual Machines and storage at scale.

## 🚀 Project Overview

The goal of **wacloud** is to provide a robust, open-source cloud stack that handles the three pillars of computing: **Compute**, **Storage**, and **Networking**. It is designed for users who want public-cloud flexibility (like AWS EC2 or DigitalOcean) on their own hardware.

### Core Technology Stack

* **Orchestration:** [Kubernetes](https://kubernetes.io/) – The backbone of the entire cluster.
* **Compute:** [KubeVirt](https://kubevirt.io/) – Enables running traditional Virtual Machines inside Kubernetes pods, allowing legacy and cloud-native workloads to coexist.
* **Storage:** [Ceph](https://ceph.com/) – Distributed, software-defined storage providing highly available block storage for VM disks.
* **Networking:** Built-in software-defined networking (SDN) to handle VM isolation, routing, and connectivity.
* **Interface:** A unified **UI** and **CLI** for easy VM provisioning, monitoring, and resource management.

## 🏗️ Architecture

The infrastructure is currently modeled using a 5-node topology:

* **1 Master Node:** Handles the Kubernetes Control Plane and cluster API.
* **4 Worker Nodes:** Managed nodes where VMs (via KubeVirt) and Storage (via Ceph) reside.

## 🛠️ Development Environment

For local development and rapid testing, the project utilizes:

* **Vagrant:** To simulate a multi-node physical environment using VirtualBox.
* **Ansible:** For automated, "one-click" provisioning of the entire OS and Kubernetes stack.
* **Makefile:** Standardized entry points for project lifecycle management.

## 🏁 Quick Start (Development Lab)

1. **Spin up the virtual hardware:**

    ```bash
    make up
    ```

2. **Provision the Kubernetes cluster:**

    ```bash
    make provision
    ```

3. **Access the cluster from localhost:**

    ```bash
    make get-config
    export KUBECONFIG=~/.kube/config-wacloud
    kubectl get nodes
    ```

---
*Developed with a focus on simplicity, scalability, and sovereignty.*
