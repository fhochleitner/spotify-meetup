#!/bin/bash

set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Setup for the local management cluster'

gum confirm '
Ready to start? This setup will start or configure a local management cluster, which is used for setting up everything else.
In the end you will have a local Kubernetes cluster with Crossplane and ArgoCD installed with a git Repository set up.
' || exit 0

echo "
## You will need following tools installed:
|Name            |Required             |More info                                          |
|----------------|---------------------|---------------------------------------------------|
|Linux Shell     |Yes                  |Use WSL if you are running Windows                 |
|Docker          |Yes                  |'https://docs.docker.com/engine/install'           |
|kind CLI        |Yes                  |'https://kind.sigs.k8s.io/docs/user/quick-start/#installation'|
|kubectl CLI     |Yes                  |'https://kubernetes.io/docs/tasks/tools/#kubectl'  |
|crossplane CLI  |Yes                  |'https://docs.crossplane.io/latest/cli'            |
|yq CLI          |Yes                  |'https://github.com/mikefarah/yq#install'          |
|AWS account with admin permissions|Yes|'https://aws.amazon.com'                  |
" | gum format

gum confirm "
Do you have those tools installed?
" || exit 0

rm -f .env

#########################
# Control Plane Cluster #
#########################

kind create cluster --config kind.yaml || gum confirm "
Failed to create kind cluster with the provided configuration.
If the cluster is already existing you can continue if you are sure
that it can be used for this and is not required for other purposes."

kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

##############
# Crossplane #
##############

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply -f providers/provider-kubernetes-incluster.yaml

kubectl apply -f providers/provider-helm-incluster.yaml

## Secrets

kubectl create secret generic aws-creds -n crossplane-system \
    --from-file creds=../.creds/aws-creds

kubectl create ns spotify || true

###########
# Argo CD #
###########

REPO_URL=$(git config --get remote.origin.url)
# workaround to avoid setting up SSH key in ArgoCD
REPO_URL=$(echo $REPO_URL | sed 's/git@github.com:/https:\/\/github.com\//') # replace git@github.com: to https://github.com/

yq --inplace ".spec.source.repoURL = \"$REPO_URL\"" argocd/apps.yaml

helm upgrade --install argocd argo-cd \
    --repo https://argoproj.github.io/argo-helm \
    --namespace argocd --create-namespace \
    --values argocd/helm-values.yaml --wait

kubectl apply --filename argocd/apps.yaml
