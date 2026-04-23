provider "hcloud" {
  token = var.hcloud_token
}

# ---------------------------------------------------------------------------
# SSH Key
# ---------------------------------------------------------------------------
resource "hcloud_ssh_key" "trading" {
  name       = "trading-server-key"
  public_key = file(var.ssh_public_key_path)
}

# ---------------------------------------------------------------------------
# Firewall
# ---------------------------------------------------------------------------
resource "hcloud_firewall" "trading" {
  name = "trading-firewall"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Trading API
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = tostring(var.trading_api_port)
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP (ping)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# ---------------------------------------------------------------------------
# Server — CX22 (2 vCPU, 4 GB RAM, 40 GB SSD)
# ---------------------------------------------------------------------------
resource "hcloud_server" "trading" {
  name        = "trading-prod"
  server_type = "cx22"
  image       = "ubuntu-24.04"
  location    = var.server_location

  ssh_keys    = [hcloud_ssh_key.trading.id]
  firewall_ids = [hcloud_firewall.trading.id]

  user_data = file("${path.module}/cloud-init.yml")

  labels = {
    environment = "production"
    role        = "trading"
  }
}

# ---------------------------------------------------------------------------
# Object Storage bucket (S3-compatible — for WAL archiving & backups)
# ---------------------------------------------------------------------------
# NOTE: Hetzner Object Storage is managed outside the hcloud provider as of
# early 2026. You create buckets via the Hetzner Cloud Console or Robot API.
# The Terraform config below uses a placeholder to document the intent.
# If Hetzner adds native Terraform support, swap this out.
#
# For now, create the bucket manually:
#   1. Hetzner Console → Object Storage → Create Bucket
#   2. Name: trading-wal-backups
#   3. Region: same as your server (eu-central)
#   4. Generate S3 credentials (Access Key + Secret Key)

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "server_ip" {
  description = "Public IPv4 of the trading server"
  value       = hcloud_server.trading.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 of the trading server"
  value       = hcloud_server.trading.ipv6_address
}

output "server_status" {
  value = hcloud_server.trading.status
}
