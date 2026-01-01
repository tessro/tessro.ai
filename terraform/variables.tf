variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit and Pages:Edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "tessro.ai"
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "tessro.ai"
}
