# Vault Workshop - Configure Vault Auth Methods

In this section, we will configure four different authentication methods in Vault: **AppRole**, **Token**, **LDAP**, and **Kubernetes**. 
Each method will be configured with specific tasks, followed by instructions on how to log in using the respective method.

### 1. **AppRole Authentication**

**AppRole** is an authentication method that allows machines or applications to authenticate with Vault using a role-based approach. The AppRole method is commonly used for automated workflows.

#### Tasks:
1. **Enable the AppRole authentication method**:
   ```bash
   vault auth enable approle
   ```

2. **Create an AppRole**:
   Define the policies and set up the AppRole.
   ```bash
   vault write auth/approle/role/my-role policies="default" secret_id_ttl="10m" token_ttl="20m" token_max_ttl="30m"
   ```

3. **Retrieve the Role ID**:
   The Role ID is used by applications to authenticate.
   ```bash
   vault read auth/approle/role/my-role/role-id
   ```

4. **Create a Secret ID**:
   The Secret ID is used along with the Role ID to authenticate.
   ```bash
   vault write -f auth/approle/role/my-role/secret-id
   ```

5. **Login with AppRole**:
   Use the Role ID and Secret ID to authenticate.
   ```bash
   vault write auth/approle/login role_id="<role-id>" secret_id="<secret-id>"
   ```
   
   - After successful authentication, Vault will return a client token.

#### Logging in with AppRole:
Once logged in, you can access Vault resources with the token provided.

---

### 2. **Token Authentication**

**Token** authentication is the simplest method, where a client uses a pre-generated token to authenticate.

#### Tasks:
1. **Enable the Token authentication method** (usually enabled by default):
   ```bash
   vault auth enable token
   ```

2. **Create a Token**:
   Create a token with the desired policies.
   ```bash
   vault token create -policy="default"
   ```

3. **Login with Token**:
   Use the token to authenticate.
   ```bash
   vault login token=<token>
   ```

#### Logging in with Token:
You are now authenticated with Vault using the token.

---

### 3. **LDAP Authentication**

**LDAP** authentication allows Vault to authenticate users against an LDAP server, such as Active Directory.

#### Tasks:
1. **Enable the LDAP authentication method**:
   ```bash
   vault auth enable ldap
   ```

2. **Configure the LDAP authentication method**:
   Configure Vault to connect to your LDAP server.
   ```bash
   vault write auth/ldap/config \
     url="ldap://<ldap-server>:389" \
     binddn="cn=admin,dc=example,dc=com" \
     bindpass="<password>" \
     userdn="ou=users,dc=example,dc=com" \
     userattr="uid" \
     groupdn="ou=groups,dc=example,dc=com" \
     groupfilter="(&(objectClass=posixGroup)(memberUid={{.Username}}))" \
     groupattr="cn" \
     insecure_tls=false
   ```

   <!-- - Replace `<ldap-server>` and `<password>` with your LDAP server details. -->

3. **Login with LDAP**:
   After configuring LDAP, you can log in using your LDAP username and password.
   ```bash
   vault login -method=ldap username="<username>" password="<password>"
   ```

   - Replace `<username>` and `<password>` with your LDAP credentials.

#### Logging in with LDAP:
Once successfully authenticated, Vault will return a client token that you can use to interact with Vault.

---

### 4. **Kubernetes Authentication**

**Kubernetes** authentication allows applications running within a Kubernetes cluster to authenticate with Vault.

#### Tasks:
1. **Enable the Kubernetes authentication method**:
   ```bash
   vault auth enable kubernetes
   ```

2. **Configure the Kubernetes authentication method**:
   Set up Vault to authenticate using the Kubernetes service account.

<!-- ```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: default
  namespace: default
  annotations:
    kubernetes.io/service-account.name: default
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default-tokenreview
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
EOF
``` -->
   
   ```bash
   TOKEN_REVIEW_JWT=$(kubectl get secret default -n default -o go-template='{{ .data.token }}' | base64 --decode)
   KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)
   KUBE_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')

   vault write auth/kubernetes/config \
     kubernetes_host=$KUBE_HOST \
     kubernetes_ca_cert=$KUBE_CA_CERT \
     token_reviewer_jwt=$TOKEN_REVIEW_JWT
   ```


3. **Create a Kubernetes role**:
   Define a Vault role that Kubernetes pods can assume.
   ```bash
   vault write auth/kubernetes/role/my-role \
     bound_service_account_names="default" \
     bound_service_account_namespaces="default" \
     policies="default" \
     ttl="1h"
   ```

4. **Login with Kubernetes**:
   Use the Kubernetes service account token to authenticate.
   ```bash
   vault login -method=kubernetes role="my-role" jwt=$TOKEN_REVIEW_JWT
   ```

   - Replace `<service-account-token>` with the token of the Kubernetes service account.

#### Logging in with Kubernetes:
After successful authentication, Vault will return a token that can be used to interact with Vault resources.

---

### Conclusion

In this section, we have covered the process of configuring and logging in with four different authentication methods in Vault: AppRole, Token, LDAP, and Kubernetes. Each method has its specific use cases, and you can use the method that best fits your needs for managing access to Vault.


Next: [Use Vault KV Secret Engine](./tasks/03-vault-secrets-kv.md)