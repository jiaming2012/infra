
## Check loclx 
In a terminal:
``` bash
/snap/bin/loclx
```

### Start a new terminal
Currently, whenever the computer is restarted, a new tunnel needs to be created. It can be created via the GUI. In the future, I think this can be automated via command line.

### Setup tunnel on loclx
Go to dashboard and set up two tunnels for eventstoreDB and postgreSQL.

#### EventstoreDB
Create a tunnel:
Type: TCP
Region: United States
Tunnel name: eventstoredb
Local service: localhost:2113
Endpoint (Use a reserve subdomain/domain):
 Reserved subdomain/domain: us.loclx.io:21133

#### PostgreSQL
Create a tunnel:
Type: TCP
Region: United States
Tunnel name: postgres
Local service: localhost:5432
Endpoint (Use a reserve subdomain/domain):
 Reserved subdomain/domain: us.loclx.io:54329

### Check eventstoredb is running
Install golang: https://go.dev/doc/install

Run golang script:
``` bash
cd infra/test/eventstoredb
go run main.go
```

### Check Postgres is running
In terminal 1:
``` bash
kubectl port-forward -n data svc/postgres 5432:5432
```

In terminal 2:
``` bash
sudo apt-get install -y postgresql-client
psql -h localhost -U myuser -d mydb
```

## Install eventstore db
``` bash
microk8s enable storage
microk8s kubectl create namespace eventstoredb
microk8s kubectl apply -f k8s/eventstoredb/pvc.yaml
microk8s kubectl apply -f k8s/eventstoredb/service.yaml
microk8s kubectl apply -f k8s/eventstoredb/deployment.yaml
microk8s kubectl apply -f k8s/eventstoredb/config.yaml
```

