#!/bin/bash

########################
# include the magic
########################
. ./demo-magic.sh
. ./helper_functions.sh

# hide the evidence
SCRIPT_PATH=`readlink -f “${BASH_SOURCE:-$0}”`
TYPE_SPEED=80
DEMO_PROMPT="${GREEN}➜ ${CYAN}"
clear

p "Setting up Vault Cluster..."
kubectl create secret generic vault-enterprise-license --from-file=license=vault.hclic --namespace vault
helm upgrade -i vault hashicorp/vault --version 0.28.0 -f vault-values.yaml --namespace vault --create-namespace

wait_for_pod_by_label "statefulset.kubernetes.io/pod-name=vault-0"


p "Initializing Vault..."
kubectl exec vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json

p "Unsealing Vault..."
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
kubectl exec -it vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

p "Logging into Vault..."
vault login $(jq -r ".root_token" cluster-keys.json)

p "Done!"

clear

caption "Welcome to Vault Workshop"

pe "vault status"

p ''
clear