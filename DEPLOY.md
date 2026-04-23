# Trading Stack Deployment Guide

## Architecture

```
Hetzner CX22 (2 vCPU, 4 GB RAM, 40 GB SSD)
├── Docker Compose
│   ├── trading-server   (Go, port 8080 → internet)
│   ├── postgres          (port 5432 → localhost only)
│   ├── eventstoredb      (port 2113/1113 → localhost only)
│   ├── bot-1             (Python)
│   └── bot-2             (Python)
└── WAL archiving → Hetzner Object Storage (S3)
```

---

## Prerequisites

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform version
```

### 2. Get a Hetzner Cloud API Token

1. Go to https://console.hetzner.cloud
2. Create a project (e.g., "Trading")
3. Go to **Security → API Tokens → Generate API Token**
4. Select **Read & Write** permissions
5. Copy the token — you'll need it for Terraform

### 3. Generate an SSH Key (if you don't have one)

```bash
ssh-keygen -t ed25519 -C "trading-server" -f ~/.ssh/id_ed25519
```

### 4. Create Hetzner Object Storage Bucket

1. Hetzner Console → **Object Storage → Create Bucket**
2. Name: `trading-wal-backups`
3. Region: same as your server (eu-central)
4. Go to **S3 Credentials → Generate Credentials**
5. Save the Access Key and Secret Key

---

## Step 1: Provision the Server with Terraform

```bash
cd terraform/

# Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Hetzner token and SSH key path

# Initialize and deploy
terraform init
terraform plan        # Review what will be created
terraform apply       # Type 'yes' to confirm
```

Terraform will output your server's IP address. Wait 2-3 minutes for cloud-init to finish installing Docker.

---

## Step 2: Deploy the Trading Stack

```bash
# SSH into the server
ssh root@$(terraform output -raw server_ip)

# On the server: clone your repo or copy files
cd /opt/trading

# Copy the docker/ directory contents here, then:
cp .env.example .env
nano .env              # Fill in real passwords and S3 credentials

# Build and start everything
docker compose up -d --build

# Verify all services are running
docker compose ps
docker compose logs -f   # Watch logs (Ctrl+C to exit)
```

---

## Step 3: Verify WAL Archiving

For the WAL archive script to work, install awscli inside the Postgres container:

```bash
docker compose exec postgres sh -c "apk add --no-cache aws-cli"
```

Or better: create a custom Postgres Dockerfile that includes awscli:

```dockerfile
FROM postgres:16-alpine
RUN apk add --no-cache aws-cli
```

Test archiving manually:

```bash
# Force a WAL switch
docker compose exec postgres psql -U trading -c "SELECT pg_switch_wal();"

# Check the archive log
docker compose exec postgres cat /var/log/postgresql/wal-archive.log
```

---

## Day-to-Day Operations

### Check service status
```bash
docker compose ps
docker compose logs --tail=50 trading-server
docker compose logs --tail=50 bot-1
```

### Restart a single service
```bash
docker compose restart bot-1
```

### Update and redeploy
```bash
git pull
docker compose up -d --build trading-server   # Rebuild only what changed
```

### Add a new bot
Duplicate the `bot-2` block in `docker-compose.yml`, rename to `bot-3`, and:
```bash
docker compose up -d bot-3
```

### Database backup (full, on top of WAL archiving)
```bash
docker compose exec postgres pg_dump -U trading -Fc trading > backup_$(date +%Y%m%d).dump
```

### Monitor resource usage
```bash
docker stats
htop
```

---

## MCP Integration (Optional)

### Terraform MCP
Add to your Claude Desktop `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "terraform": {
      "command": "npx",
      "args": ["-y", "@anthropic/terraform-mcp"]
    }
  }
}
```

### Hetzner MCP
```json
{
  "mcpServers": {
    "hetzner": {
      "command": "npx",
      "args": ["-y", "hcloud-mcp"],
      "env": {
        "HCLOUD_TOKEN": "your-hetzner-api-token"
      }
    }
  }
}
```

With both connected, you can ask Claude to manage your infrastructure conversationally — check server status, resize, create snapshots, etc.

---

## Security Notes

- Postgres and EventStoreDB are bound to `127.0.0.1` — not exposed to the internet
- SSH + fail2ban are configured by cloud-init
- The trading API port (8080) is the only service exposed externally — add authentication
- Store secrets in `.env`, never commit it to git
- EventStoreDB runs in insecure mode — add TLS certs for production
- Consider adding Caddy or nginx as a reverse proxy with automatic HTTPS
