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

# Helm
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
VERSION=v4.4.8
install.sh: ${docker}
	curl -s -O https://raw.githubusercontent.com/rancher/k3d/main/install.sh
	TAG=$(VERSION) bash install.sh

k3d: .k3d_cluster_created
.k3d_cluster_created: install.sh
	k3d cluster create $(shell basename ${PWD}) --servers 2
	# override local-path storage provisioner config
	kubectl apply -f local-path-config.yaml
	touch $@

# Test if docker is installed and running, we need it for K3D
${docker}: $(WORKON_HOME)
	@systemctl is-active --quiet docker || (echo "❌🐋 Docker not found or not running? Docker is required for K3D"; exit 1)
	touch ${docker}

# K8ssandra
k8ssandra_helm:
	helm repo add k8ssandra https://helm.k8ssandra.io/stable
	helm repo add traefik https://helm.traefik.io/traefik
	helm repo update

k8ssandra_install: k8ssandra_helm
	helm install cass-operator k8ssandra/cass-operator -n cass-operator --create-namespace
	kubectl config set-context --current --namespace cass-operator
	touch $@

# We are using a custom version of the ttps://raw.githubusercontent.com/k8ssandra/cass-operator/master/operator/example-cassdc-yaml/cassandra-3.11.x/example-cassdc-minimal.yaml
# example dc resource with a custom local-path storage class to be able to run on k3d
k8ssandra_datacenter: k8ssandra_install
	kubectl -n cass-operator apply -f example-cassdc-minimal.yaml

k8ssandra_status:
	kubectl -n cass-operator get cassdc -o jsonpath="{range .items[*]}{.status.cassandraOperatorProgress}{'\n'}{end}"

# cass-operator requires cert-manager for handling TLS on required webhooks as stated 
# here: https://github.com/k8ssandra/cass-operator#installing-the-operator-with-kustomize
cert_manager_install:
	kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.3/cert-manager.yaml

# Using the mrproper convention we have a target for cleaning up our whole development environment in one go!
mrproper:
	-k3d cluster delete $(shell basename ${PWD})
	rm -rf $(WORKON_HOME)
	sudo rm /usr/local/bin/k3d
	rm k8ssandra_install

clean:
	rm k3d
	rm install.sh
	rm k8ssandra_install
