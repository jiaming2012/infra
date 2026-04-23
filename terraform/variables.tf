variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "server_location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "nbg1" # Nuremberg — cheapest, also: fsn1 (Falkenstein), hel1 (Helsinki)
}

variable "trading_api_port" {
  description = "Port your Go trading server exposes"
  type        = number
  default     = 8080
}
