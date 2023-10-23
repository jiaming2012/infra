## Secret
Postgres requires a password to log in. The password is injected as a kubernetes secret. The following command creates the secret:
``` bash
echo -n 'your-actual-password' | base64
```

## Install
The postgres cluster can be brought up with the following commands:

### Create a separate namespace
``` bash
kubectl create namespace data
```

### Deploy manifests
``` bash
cd path/to/infra
kubectl apply -f k8s/postgres/deployment.yaml --namespace data
kubectl apply -f k8s/postgres/service.yaml --namespace data
kubectl apply -f k8s/postgres/pvc.yaml --namespace data
kubectl apply -f k8s/postgres/secret.yaml --namespace data
kubectl apply -f k8s/postgres/config.yaml --namespace data
```

## Setup ngrok as ingress controller for receiving web traffic
If using microk8s:
``` bash
microk8s enable dns
```

Link to download ngrok cmd client: https://ngrok.com/download
Link to install kubernetes ingress controller: https://ngrok.com/docs/using-ngrok-with/k8s/. Note: use helm3
``` bash
microk8s helm3 repo update
```

As mentioned in the tutorial, apply the ngrok-manifest file with:
``` bash
kubectl apply -f ngrok-manifest.yaml
```
