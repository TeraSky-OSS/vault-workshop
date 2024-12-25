# Vault Workshop - Cleanup

To remove the Vault deployment from your Minikube cluster, run the following command:

```bash
helm uninstall vault -n vault
helm uninstall mongodb -n mongodb
helm uninstall postgres -n postgres

kubectl delete pv,pvc -n vault --all
kubectl delete pv,pvc -n mongodb --all
kubectl delete pv,pvc -n postgres --all
```

This command will uninstall the Vault Helm release from the `vault` namespace, cleaning up all associated resources.
