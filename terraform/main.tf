terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state"
    key    = "tessro.ai/terraform.tfstate"

    # R2 config - set via: tofu init -backend-config=backend.hcl
    region                      = "auto"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zone" "main" {
  name = var.domain
}

resource "cloudflare_pages_project" "site" {
  account_id        = var.cloudflare_account_id
  name              = "tessro-ai"
  production_branch = "main"

  build_config {
    build_command   = ""
    destination_dir = "site"
  }

  source {
    type = "github"
    config {
      owner                         = var.github_owner
      repo_name                     = var.github_repo
      production_branch             = "main"
      deployments_enabled           = true
      production_deployment_enabled = true
    }
  }
}

resource "cloudflare_pages_domain" "root" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.site.name
  domain       = var.domain
}

resource "cloudflare_record" "root" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  content = cloudflare_pages_project.site.subdomain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www"
  content = var.domain
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Email forwarding via forwardemail.net
resource "cloudflare_record" "mx1" {
  zone_id  = data.cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "mx1.forwardemail.net"
  priority = 10
  ttl      = 1
}

resource "cloudflare_record" "mx2" {
  zone_id  = data.cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "mx2.forwardemail.net"
  priority = 20
  ttl      = 1
}

resource "cloudflare_record" "forward_email_verification" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  type    = "TXT"
  content = "forward-email-site-verification=2DZSgIsTXW"
  ttl     = 1
}

# fab.tessro.ai -> GitHub Pages
resource "cloudflare_record" "fab" {
  zone_id = data.cloudflare_zone.main.id
  name    = "fab"
  content = "tessro.github.io"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# paver.tessro.ai -> GitHub Pages
resource "cloudflare_record" "paver" {
  zone_id = data.cloudflare_zone.main.id
  name    = "paver"
  content = "tessro.github.io"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}
