# Vault Workshop - Vault Database Secret Engine

In this section, we will configure the **Database Secret Engine** in Vault to dynamically generate database credentials and rotate them. We will set up and configure two databases—**PostgreSQL** and **MongoDB**—on Minikube and integrate them with Vault.

---

## **PostgreSQL on Minikube**

### Deploy PostgreSQL on Minikube**
1. **Create a namespace for PostgreSQL**:
   ```bash
   kubectl create namespace postgres
   ```

2. **Deploy PostgreSQL using Helm**:
   Add the Bitnami Helm chart repository and install PostgreSQL.
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm repo update
   helm install postgres bitnami/postgresql --namespace postgres --set auth.username=admin,auth.password=password123,auth.database=mydb
   ```

3. **Verify the PostgreSQL deployment**:
   Check the status of the PostgreSQL pods.
   ```bash
   kubectl get pods -n postgres
   ```

4. **Forward the PostgreSQL service to your local machine**:
   ```bash
   kubectl port-forward svc/postgres-postgresql -n postgres 5432:5432
   ```

---

### Configure Vault for PostgreSQL**

1. **Enable the Database Secret Engine**:
   ```bash
   vault secrets enable -path postgres database 
   ```

2. **Configure the PostgreSQL database plugin**:
   ```bash
   vault write postgres/config/postgres \
     plugin_name=postgresql-database-plugin \
     connection_url="postgresql://{{username}}:{{password}}@postgres-postgresql.postgres.svc.cluster.local:5432/mydb" \
     allowed_roles="my-role" \
     username="admin" \
     password="password123"
   ```

3. **Rotate root user password**
    After preforming the rotation you will no longer be able to login with the admin user.
    ```bash
    vault write -force postgres/rotate-root/postgres
    ```

    > **Note**: When this is done, the password for the user specified in the previous step is no longer accessible. Because of this, it is highly recommended that a user is created specifically for Vault to use to manage database users.

4. **Create a role for dynamic credential generation**:
   ```bash
   vault write postgres/roles/my-role \
     db_name=postgres \
     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \ GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
     default_ttl="1h" \
     max_ttl="24h"
   ```

5. **Generate dynamic credentials**:
   ```bash
   vault read postgres/creds/my-role
   ```

6. **Access the db with the dynamic credentials**

---

## **MongoDB on Minikube**

### Deploy MongoDB on Minikube**

1. **Create a namespace for MongoDB**:
   ```bash
   kubectl create namespace mongodb
   ```

2. **Deploy MongoDB using Helm**:
   Add the Bitnami Helm chart repository and install MongoDB.
   ```bash
   helm install mongodb bitnami/mongodb --namespace mongodb --set auth.rootPassword=password123,auth.database=mydb
   ```

3. **Verify the MongoDB deployment**:
   Check the status of the MongoDB pods.
   ```bash
   kubectl get pods -n mongodb
   ```

4. **Forward the MongoDB service to your local machine**:
   ```bash
   kubectl port-forward svc/mongodb -n mongodb 27017:27017
   ```

---

### Configure Vault for MongoDB**

1. **Enable the Database Secret Engine**:
   ```bash
   vault secrets enable -path mongodb database
   ```

2. **Configure the MongoDB database plugin**:
   ```bash
   vault write mongodb/config/mongodb \
     plugin_name=mongodb-database-plugin \
     connection_url="mongodb://{{username}}:{{password}}@mongodb.mongodb.svc.cluster.local:27017/admin" \
     allowed_roles="my-role" \
     username="root" \
     password="password123" 
   ```

3. **Rotate root user password**
    After preforming the rotation you will no longer be able to login with the root user.

    ```bash
    vault write -force mongodb/rotate-root/mongodb
    ```

   > **Note**: When this is done, the password for the user specified in the previous step is no longer accessible. Because of this, it is highly recommended that a user is created specifically for Vault to use to manage database users.

4. **Create a role for dynamic credential generation**:
   ```bash
   vault write mongodb/roles/my-role \
     db_name=mongodb \
     creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' \
     default_ttl="1h" \
     max_ttl="24h"
   ```

5. **Generate dynamic credentials**:
   ```bash
   vault read mongodb/creds/my-role
   ```

6. **Access the db with the dynamic credentials**

---

## **Conclusion**

In this section, we deployed PostgreSQL and MongoDB on Minikube and configured the Vault Database Secret Engine to dynamically generate credentials for both databases. These credentials can now be used by applications to securely access the databases.

Next: [Vault Manual Snapshot](./06-vault-manual-backup.md)
