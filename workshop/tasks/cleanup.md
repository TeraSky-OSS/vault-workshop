# Vault Workshop - Cleanup

To remove all resources deployed in this workshop from your Minikube cluster, run the following command:

```bash
helm uninstall vault -n vault
helm uninstall mongodb -n mongodb
helm uninstall postgres -n postgres
kubectl delete pv,pvc -n vault --all
kubectl delete pv,pvc -n mongodb --all
kubectl delete pv,pvc -n postgres --all

# OR

minikube delete

```

Those commands will clean up all resources deployed in this workshop.
