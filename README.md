
## Start loclx 
### Method 1: automatically (recommended)
Check if the loclx dashboard is already running via a systemd service file

``` bash
sudo systemctl status loclx.service
```

#### Install systemd service (if not already present)
``` bash
sudo nano /etc/systemd/system/loclx.service
```

Paste the following file
```
[Unit]
Description=LocalXpose Service
After=network.target

[Service]
ExecStart=/snap/bin/loclx
Restart=always

[Install]
WantedBy=multi-user.target
```

``` bash
sudo systemctl daemon-reload               
sudo systemctl enable loclx.service
sudo systemctl status loclx.service
```

### Method 2: manually
In a terminal:
``` bash
/snap/bin/loclx
```

### Setup tunnel on loclx
We currently use a paid service, loclx, to expose our db services to the outside world.

#### Method 1: automatically (recommended)
Check if the tcp tunnels service is running 

``` bash
sudo systemctl status loclx-tunnels.service
```

#### Install systemd service (if not already present)
``` bash
sudo nano /etc/systemd/system/loclx-tunnels.service
```

Paste the following file
```                                                  
[Unit]
Description=LocalXpose Service
After=network-online.target

[Service]
User=jamal
ExecStart=/snap/bin/loclx tunnel config -f /home/jamal/projects/infra/loclx/config.yaml
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
```

``` bash
sudo systemctl daemon-reload               
sudo systemctl enable loclx-tunnels.service
sudo systemctl status loclx-tunnels.service
```

#### Method 2: manually
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

