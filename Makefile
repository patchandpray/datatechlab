# First of we need minikube
# For minikube we need Docker
#
# Or do we rather want k3s
# or maybe k3d
# or maybe KinD
# or minikube
#

WORKON_HOME=${HOME}/.cache/$(shell basename ${PWD})
$(WORKON_HOME):
	mkdir -p $(WORKON_HOME)
	mkdir -p $(bin)


bin = $(WORKON_HOME)/bin
helm = ${bin}/helm
k3s = ${bin}/k3s
k3d = ${bin}/k3d
docker = ${bin}/docker


# The setup target is the main entrypoint for installing all of our components
setup: ${helm} k3d

HELM_VERSION=3.7.0
HELM_ARCHIVE=$(WORKON_HOME)/helm.tar.gz
${helm}: ${HELM_ARCHIVE}
	tar -xzvf $(HELM_ARCHIVE) --strip-components=1 -C ${bin} linux-amd64/helm
	touch $@
$(HELM_ARCHIVE): $(WORKON_HOME)
	wget -O $(HELM_ARCHIVE) https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz
	touch $(HELM_ARCHIVE)

### Setup installation targets

# K3S
# Have k3s write it's configuration file with user readable permissions
ENV=K3S_KUBECONFIG_MODE="644"
${k3s}: 
	curl -sfL https://get.k3s.io | $(ENV) sh -

# K3D
install.sh: ${docker}
	curl -s -O https://raw.githubusercontent.com/rancher/k3d/main/install.sh 
	bash install.sh

k3d: .k3d_cluster_created
.k3d_cluster_created: install.sh
	k3d cluster create $(shell basename ${PWD})
	touch $@

# Test if docker is installed and running, we need it for K3D
${docker}:
	@systemctl is-active --quiet docker || (echo "Docker not found or not running? Docker is required for K3D"; exit 1)
	touch ${docker}

# We require HELM for installing K8sandra
helm: ${helm}
	${helm} version

# Using the mrproper convention we have a target for cleaning up our whole development environment in one go!
mrproper:
	k3d cluster delete $(shell basename ${PWD})
	rm -rf $(WORKON_HOME)
	sudo rm /usr/local/bin/k3d

clean:
	rm k3d
	rm install.sh
