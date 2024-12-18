CURRENT_DIR:=$(shell pwd)

DO_ACCESS_TOKEN:=$(shell cat dotoken)

DO_CLUSTER_NAME:=kubeflow
DO_CLUSTER_SIZE:=s-2vcpu-4gb
DO_CLUSTER_NODE_COUNT:=2

ARGOCD_PORT:=8080
ARGOCD_PORTFORWARD_LOG:=portforward.log
ARGOCD_PID:=argo-cd-pid.txt

default: debug init-doctl do-create-cluster do-cluster-config do-cluster-get-nodes

#.PHONY: lint
#.lint:
#	yamllint .

debug:
	echo CURRENT_DIR is ${CURRENT_DIR}
	echo Using shell: $$SHELL
	echo Digital Ocean Token ${DO_ACCESS_TOKEN}

init-doctl:
	doctl auth init --access-token ${DO_ACCESS_TOKEN}

.PHONY: debug
do-create-cluster: debug
	doctl kubernetes cluster create kubeflow --count=2 --size=s-4vcpu-8gb-intel

do-cluster-config: debug
	doctl kubernetes cluster kubeconfig save kubeflow

do-cluster-get-nodes: debug
	kubectl --kubeconfig=/Users/mahdikhashan/.kube/config get nodes

## remove cluster, namespace and all others here
#.PHONY: clean
#clean-local: clean-debug
#	kubectl delete namespace ${NAMESPACE} || true
#	. ./cluster/setup.sh && drop_cluster $(CLUSTER_NAME)

#.PHONY: start-local
#start-local: clean
#	bash k3d-version.sh || true
#	. ./cluster/setup.sh && create_cluster $(CLUSTER_NAME)
#	@if kubectl config use-context 'k3d-$(CLUSTER_NAME)' &>/dev/null && kubectl config current-context | grep -q 'k3d-$(CLUSTER_NAME)'; then echo 'switched to cluster $(CLUSTER_NAME).'; fi
#	kubectl create namespace ${NAMESPACE}

#.PHONY: start-local-argo
#start-local-argo: start-local
#	. argocd.sh && apply ${NAMESPACE}
#	. argocd.sh && portforward ${NAMESPACE} ${ARGOCD_PORT} ${ARGOCD_PORTFORWARD_LOG} ${ARGOCD_PID}
#	. argocd.sh && ui_admin_password ${NAMESPACE}

#.PHONY: stop-local-argocd
#stop-local-argocd:
#	@pgrep -f "kubectl port-forward" | xargs kill -9

#.PHONY: show-argocd-password
#.show-argocd-password:
#	. argocd.sh && ui_admin_password ${NAMESPACE}

.PHONY: install-argo
.install-argo:
	kubectl apply -f ./apps/namespaces/argocd.yaml
	@while ! kubectl get namespace argocd &>/dev/null; do \
      		echo "Waiting for namespace 'argocd' to be created..."; \
            sleep 1; \
    done
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=ready pod --all -n argocd --timeout=600s
	bash ./scripts/patch-argocd.sh
	bash ./scripts/argocd-password.sh

.stop-and-remove-argo:
	kubectl delete applications --all -n argocd --ignore-not-found
	kubectl delete namespace argocd --force --grace-period=0 --ignore-not-found
	kubectl delete all -l app.kubernetes.io/part-of=argocd --all-namespaces --ignore-not-found

.remove-load-balancers:
	doctl compute lb list
	#doctl compute load-balancer remove-droplets

.add-repositories:
	bash ./scripts/add-bitnami-repo.sh
	bash ./scripts/add-minio-repo.sh

.PHONY: install-base-argo-app
.install-base-argo-app:
	kubectl apply -f app.yaml

.get-argocd-password:
	bash ./scripts/argocd-password.sh

.PHONY: get-grafana-password
.get-grafana-password:
	kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

.PHONY: portforward-app
.portforward-app:
	kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
