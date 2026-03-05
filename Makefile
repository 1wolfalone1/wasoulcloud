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
