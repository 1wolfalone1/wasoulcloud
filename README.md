# wasoulcloud

A self-hosted Infrastructure-as-a-Service (IaaS) platform. Like OpenStack, but built to learn — and themed after souls games because why not.

Compute with KubeVirt, storage with Ceph, networking with [greattree](https://github.com/1wolfalone1/greattree).

## Stack

| Layer | Technology | Description |
|---|---|---|
| **Orchestration** | Kubernetes | The backbone |
| **Compute** | KubeVirt | VMs inside K8s pods |
| **Storage** | Ceph | Distributed block storage (RBD) + object storage (RGW) |
| **Networking** | [greattree](https://github.com/1wolfalone1/greattree) | Custom SDN — L2 switching, VXLAN overlay, L3 routing, firewall, DHCP. |

## Infrastructure

```
K8s cluster (nodes 1-5)
|-- 1 master node
|-- 4 worker nodes (KubeVirt VMs run here)

Ceph cluster (nodes 6-8)
|-- 3 nodes (MON, MGR, OSD, RGW)
```

Provisioned with Vagrant + Ansible. Everything automated via Makefile.

## Quick Start

```bash
make infra-up                 # boot 8 VMs
make infra-k8s-provision      # setup K8s cluster
make infra-k8s-get-config     # fetch kubeconfig
make infra-k8s-deploy         # deploy KubeVirt
make infra-ceph-deploy        # setup Ceph cluster
```

## Project Structure

```
wasoulcloud/
├── infra/
│   ├── vm/vagrant/       # Vagrantfile (8-node cluster)
│   ├── k8s/ansible/      # K8s provisioning
│   └── ceph/ansible/     # Ceph provisioning
├── deploy/
│   └── k8s/              # Helmfile + KubeVirt chart
└── greattree/            # SDN (git submodule)
```
