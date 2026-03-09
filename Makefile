# Path to the directory containing the Vagrantfile
VAGRANT_DIR = infra/vm/vagrant/
ANSIBLE_DIR = infra/k8s/ansible
INVENTORY   = $(ANSIBLE_DIR)/inventory.ini
PLAYBOOK    = $(ANSIBLE_DIR)/site.yml

export ANSIBLE_CONFIG = $(ANSIBLE_DIR)/ansible.cfg
# VM control
.PHONY: help infra-up infra-down infra-status infra-clean infra-plugin

help:
	@echo "Wacloud VM Management:"
	@echo "  make infra-plugin  - Install disksize plugin"
	@echo "  make infra-up      - Load vboxdrv and boot 5 nodes"
	@echo "  make infra-down    - Halt all nodes"
	@echo "  make infra-status  - Check VM states"
	@echo "  make infra-clean   - Destroy all VMs"
	@echo "  make ssh-n1        - SSH into node 1 (also n2, n3, n4, n5)"

infra-plugin:
	vagrant plugin install vagrant-disksize

infra-up:
	@echo "Checking VirtualBox Kernel Modules..."
	sudo modprobe vboxdrv || echo "Module already loaded"
	cd $(VAGRANT_DIR) && vagrant up

infra-down:
	cd $(VAGRANT_DIR) && vagrant halt

infra-reload:
	cd $(VAGRANT_DIR) && vagrant reload --provision

infra-status:
	cd $(VAGRANT_DIR) && vagrant status

infra-clean:
	cd $(VAGRANT_DIR) && vagrant destroy -f

ssh-n%:
	cd $(VAGRANT_DIR) && vagrant ssh wacloud-node-$*

.PHONY: ansible-setup

infra-ansible-ping:
	ansible all -i $(INVENTORY) -m ping --extra-vars "ansible_ssh_pass=vagrant"

infra-ansible-provision:
	ansible-playbook -i $(INVENTORY) infra/k8s/ansible/site.yml --extra-vars "ansible_ssh_pass=vagrant"

# --- Kubeconfig Helper ---
.PHONY: get-config
KUBECONFIG_LOCAL = ~/.kube/config-wacloud

infra-get-config:
	@echo "Fetching kubeconfig from node-1..."
	@mkdir -p ~/.kube
	@scp -i infra/vm/vagrant/.vagrant/machines/wacloud-node-1/virtualbox/private_key \
		-o StrictHostKeyChecking=no \
		vagrant@192.168.56.11:/home/vagrant/.kube/config $(KUBECONFIG_LOCAL)
	@sed -i 's/127.0.0.1/192.168.56.11/g' $(KUBECONFIG_LOCAL)
	@echo "Config saved to $(KUBECONFIG_LOCAL)"
	@echo "To use it, run: export KUBECONFIG=$(KUBECONFIG_LOCAL)"

.PHONY: k8s-prep k8s-deploy k8s-diff k8s-destroy k8s-status
HELMFILE_DIR = deploy/k8s
HELMFILE     = helmfile -f $(HELMFILE_DIR)/helmfile.yaml
KUBEVIRT_VER = v1.7.0
CHART_PATH   = $(HELMFILE_DIR)/charts/kubevirt-stack

k8s-setup:
	helm plugin install https://github.com/databus23/helm-diff --verify=false || true

k8s-diff:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) diff

k8s-deploy:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) apply

k8s-destroy:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && $(HELMFILE) destroy

k8s-status:
	@export KUBECONFIG=$(KUBECONFIG_LOCAL) && kubectl get all -n kubevirt
