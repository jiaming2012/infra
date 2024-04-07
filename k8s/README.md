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

## Setup ingress controller for receiving web traffic
If using microk8s:
``` bash
microk8s enable dns
microk8s enable ingress
```

Install the ingress resource
``` bash
k apply -f k8s/ingress/nginx-ingress-microk8s-tcp-controller.yaml
```

https://stackoverflow.com/questions/29142/getting-ssh-to-execute-a-command-in-the-background-on-target-machine

Start the program
``` bash
./run.sh   
```

## Pinggy
Pinggy is used to expose our database to the world.

```bash
cd path/to/infra
./start-infra.sh
```
