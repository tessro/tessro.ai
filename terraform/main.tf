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

# Email routing
resource "cloudflare_email_routing_settings" "main" {
  zone_id = data.cloudflare_zone.main.id
  enabled = true
}

resource "cloudflare_email_routing_address" "destination" {
  account_id = var.cloudflare_account_id
  email      = var.email_forward_to
}

resource "cloudflare_email_routing_rule" "hi" {
  zone_id = data.cloudflare_zone.main.id
  name    = "forward hi@"
  enabled = true

  matcher {
    type  = "literal"
    field = "to"
    value = "hi@${var.domain}"
  }

  action {
    type  = "forward"
    value = [var.email_forward_to]
  }

  depends_on = [cloudflare_email_routing_settings.main]
}
