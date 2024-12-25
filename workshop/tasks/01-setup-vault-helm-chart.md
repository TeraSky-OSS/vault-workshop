# Vault Workshop - Setup Vault with Helm Chart

In this section, we will walk through the steps to deploy HashiCorp Vault on a Kubernetes cluster using Helm. This setup will allow you to manage secrets and other sensitive data securely in your Kubernetes environment.

## Steps for Setting Up Vault with Helm Chart

### 1. **Add HashiCorp Helm Repository**

First, add the HashiCorp Helm repository to your Helm configuration and update it:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

### 2. **Download the Vault Helm Chart Values**

To customize the Helm chart for your Vault deployment, you'll need to retrieve the default values for Vault's Helm chart. For Vault version 1.16, run the following command:

```bash
helm show values hashicorp/vault --version 0.28.0 > values.yaml
```

> **Note**: The default values were saved to a file named `values.yaml`. You should now modify the `values.yaml` file (for [example](../../Docs/vault-values.yaml)).

The Vault cluster should have the following configurations:
* Standalone Vault: Configure Vault to run as a standalone instance, without HA.
* Raft Storage Backend: Enable the Raft storage backend.
* Configure Vault to use TLS for secure communication. You will need to provide your own certificates or enable auto-generation of certificates (use the example [here](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls)).
* Enable the Vault web UI for easier management and configuration.
* Configure Kubernetes liveness and readiness probes to ensure Vault's health status is properly monitored
* Set resource requests and limits for Vault to ensure it has enough resources to run efficiently and prevent over-provisioning.


### 3. **Install Vault Using Helm**

Run the following command to install Vault in the `vault` namespace with you `vault-values.yaml` file:

```bash
helm upgrade -i vault hashicorp/vault --version 0.28.0 -f vault-values.yaml --namespace vault --create-namespace
```

### 4. **Initialize Vault**

Once Vault is deployed, you need to initialize it. This step is required to set up the Vault server with the initial keys and unseal it.

Run the following command to initialize Vault:

```bash
kubectl exec vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json > cluster-keys.json
```

This command will output the unseal keys and the root token into a file named `cluster-keys.json`.

> **Note**: Do not run an unsealed Vault in production with a single key share and a single key threshold. This approach is only used here to simplify the unsealing process for Hands On.

### 5. **Unseal Vault**

After initialization, Vault is in a sealed state. To unseal it, you need to use the unseal keys. Run the following command to unseal Vault:

```bash
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
kubectl exec -it vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```

### 6. **Set Vault Address**

Now that Vault is initialized and unsealed, set the Vault address to the service URL of the Vault pod you just created.

Run the following command in your terminal to export the Vault address:

```bash
export VAULT_ADDR="http://vault.vault.svc.cluster.local:8200"
```

> **Note**: This command sets the `VAULT_ADDR` environment variable to the Vault service's address in your Kubernetes cluster. You can now interact with Vault using the Vault CLI.


Now Login to Vault

```bash
vault status
```

```bash
vault token login $(jq -r ".root_token" cluster-keys.json)
```


---

Next: [Configure Vault Auth Methods](./02-vault-auth-methods.md)