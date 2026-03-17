# Path to the directory containing the Vagrantfile
VAGRANT_DIR = infra/vm/vagrant/
ANSIBLE_DIR = infra/k8s/ansible
INVENTORY   = $(ANSIBLE_DIR)/inventory.ini
PLAYBOOK    = $(ANSIBLE_DIR)/site.yml

export ANSIBLE_CONFIG = $(ANSIBLE_DIR)/ansible.cfg
# VM control
.PHONY: help infra-up infra-down infra-status infra-clean infra-plugin

# Path to the directory containing the Vagrantfile
VAGRANT_DIR = infra/vm/vagrant/
ANSIBLE_DIR = infra/k8s/ansible
INVENTORY   = $(ANSIBLE_DIR)/inventory.ini
PLAYBOOK    = $(ANSIBLE_DIR)/site.yml

export ANSIBLE_CONFIG = $(ANSIBLE_DIR)/ansible.cfg

KUBECONFIG_LOCAL = ~/.kube/config-wacloud
HELMFILE_DIR = deploy/k8s
HELMFILE     = helmfile -f $(HELMFILE_DIR)/helmfile.yaml
KUBEVIRT_VER = v1.7.0
CHART_PATH   = $(HELMFILE_DIR)/charts/kubevirt-stack
CEPH_INVENTORY = infra/ceph/ansible/inventory.ini
CEPH_PLAYBOOK  = infra/ceph/ansible/site.yml

.PHONY: help \
	infra-plugin infra-up infra-down infra-reload infra-status infra-clean \
	infra-k8s-ping infra-k8s-provision infra-k8s-get-config \
	infra-k8s-setup infra-k8s-diff infra-k8s-deploy infra-k8s-destroy infra-k8s-status \
	infra-ceph-ping infra-ceph-deploy infra-ceph-status infra-ceph-clean

help:
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║              Wacloud Management Commands             ║"
	@echo "╚══════════════════════════════════════════════════════╝"
	@echo ""
	@echo "── Infrastructure ──────────────────────────────────────"
	@echo "  make infra-plugin              - Install vagrant disksize plugin"
	@echo "  make infra-up                  - Load vboxdrv and boot 8 nodes"
	@echo "  make infra-boot                - Boot existing nodes without provisioning"
	@echo "  make infra-down                - Halt all nodes"
	@echo "  make infra-reload              - Reload and reprovision all nodes"
	@echo "  make infra-status              - Check VM states"
	@echo "  make infra-clean               - Destroy all VMs"
	@echo "  make infra-ssh-n[1-8]          - SSH into node (e.g. make infra-ssh-n1)"
	@echo ""
	@echo "── Kubernetes Ansible ──────────────────────────────────"
	@echo "  make infra-k8s-ping            - Ping all k8s nodes"
	@echo "  make infra-k8s-provision       - Provision k8s cluster"
	@echo "  make infra-k8s-get-config      - Fetch kubeconfig from node-1"
	@echo ""
	@echo "── Kubernetes Helm ─────────────────────────────────────"
	@echo "  make infra-k8s-setup           - Install helm plugins"
	@echo "  make infra-k8s-diff            - Diff helmfile changes"
	@echo "  make infra-k8s-deploy          - Deploy kubevirt stack"
	@echo "  make infra-k8s-destroy         - Destroy kubevirt stack"
	@echo "  make infra-k8s-status          - Check kubevirt status"
	@echo ""
	@echo "── Ceph ────────────────────────────────────────────────"
	@echo "  make infra-ceph-ping           - Ping ceph nodes"
	@echo "  make infra-ceph-deploy         - Deploy Ceph cluster"
	@echo "  make infra-ceph-status         - Check Ceph cluster status"
	@echo "  make infra-ceph-clean          - Destroy Ceph cluster"
	@echo "  make infra-ceph-dashboard      - Forward Ceph dashboard to localhost:8443"
	@echo ""

# --- VM ---
infra-plugin:
	vagrant plugin install vagrant-disksize

infra-up:
	@echo "Checking VirtualBox Kernel Modules..."
	sudo modprobe vboxdrv || echo "Module already loaded"
	cd $(VAGRANT_DIR) && VAGRANT_EXPERIMENTAL="disks" vagrant up

infra-boot:
	@echo "Checking VirtualBox Kernel Modules..."
	sudo modprobe vboxdrv || echo "Module already loaded"
	cd $(VAGRANT_DIR) && VAGRANT_EXPERIMENTAL="disks" vagrant up --no-provision

infra-down:
	cd $(VAGRANT_DIR) && vagrant halt

infra-reload:
	cd $(VAGRANT_DIR) && vagrant reload --provision

infra-status:
	cd $(VAGRANT_DIR) && vagrant status

infra-clean:
	cd $(VAGRANT_DIR) && vagrant destroy -f

infra-ssh-n%:
	cd $(VAGRANT_DIR) && vagrant ssh wacloud-node-$*

# --- K8s Ansible ---
infra-k8s-ping:
	ansible all -i $(INVENTORY) -m ping --extra-vars "ansible_ssh_pass=vagrant"

infra-k8s-provision:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --extra-vars "ansible_ssh_pass=vagrant"

infra-k8s-get-config:
	@echo "Fetching kubeconfig from node-1..."
	@mkdir -p ~/.kube
	@scp -i ~/.vagrant.d/insecure_private_key \
		-o StrictHostKeyChecking=no \
		vagrant@192.168.56.11:/home/vagrant/.kube/config $(KUBECONFIG_LOCAL)
	@sed -i 's/127.0.0.1/192.168.56.11/g' $(KUBECONFIG_LOCAL)
	@echo "Config saved to $(KUBECONFIG_LOCAL)"
	@echo "To use it, run: export KUBECONFIG=$(KUBECONFIG_LOCAL)"

# --- K8s Helm ---
infra-k8s-setup:
	helm plugin install https://github.com/databus23/helm-diff --verify=false || true

infra-k8s-diff:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) diff

infra-k8s-deploy:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) apply

infra-k8s-destroy:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) destroy

infra-k8s-status:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && kubectl get all -n kubevirt

# --- Ceph ---
infra-ceph-ping:
	ansible all -i $(CEPH_INVENTORY) -m ping

infra-ceph-deploy:
	ansible-playbook -i $(CEPH_INVENTORY) $(CEPH_PLAYBOOK)

infra-ceph-status:
	ssh -i infra/vm/vagrant/.vagrant/machines/wacloud-node-6/virtualbox/private_key \
		-o StrictHostKeyChecking=no \
		vagrant@192.168.56.16 "sudo ceph -s"

infra-ceph-clean:
	ansible all -i $(CEPH_INVENTORY) -m shell -a "cephadm rm-cluster --fsid \$(ceph fsid) --force" || true

infra-ceph-dashboard:
	@echo "Forwarding Ceph dashboard to https://localhost:8443"
	ssh -i ~/.vagrant.d/insecure_private_key \
		-o StrictHostKeyChecking=no \
		-L 8443:192.168.56.16:8443 \
		vagrant@192.168.56.16 -N
