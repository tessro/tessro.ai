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

# DKIM for forwardemail.net
resource "cloudflare_record" "dkim" {
  zone_id = data.cloudflare_zone.main.id
  name    = "fe-02c0d68cb1._domainkey"
  type    = "TXT"
  content = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDfNIzDX70nEv+FxCmakzMRE5bWe5ffcAVJ57DVmBFI/0n2RRZ62lig4X/O/5o08H3nnmV3euUwqp/T8g3MQni+P9W+BbmoyLm/KD1mmYSOk5BcUnanbuZAhYwIKpPeN0bMvTN5QQ3acFQA013nUOcy568/zzX3cBnWPfZvtI0NYQIDAQAB;"
  ttl     = 1
}

# Bounce handling for forwardemail.net
resource "cloudflare_record" "bounces" {
  zone_id = data.cloudflare_zone.main.id
  name    = "fe-bounces"
  type    = "CNAME"
  content = "forwardemail.net"
  proxied = false
  ttl     = 1
}

# DMARC policy
resource "cloudflare_record" "dmarc" {
  zone_id = data.cloudflare_zone.main.id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=reject; pct=100; rua=mailto:dmarc-6956fb6de60bf37d1162e8e6@forwardemail.net;"
  ttl     = 1
}

# SPF record for forwardemail.net
resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:spf.forwardemail.net -all"
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

# pave.tessro.ai -> GitHub Pages
resource "cloudflare_record" "pave" {
  zone_id = data.cloudflare_zone.main.id
  name    = "pave"
  content = "tessro.github.io"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# war.tessro.ai -> GitHub Pages
resource "cloudflare_record" "war" {
  zone_id = data.cloudflare_zone.main.id
  name    = "war"
  content = "tessro.github.io"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# sierra.tessro.ai -> Tailscale node
resource "cloudflare_record" "sierra" {
  zone_id = data.cloudflare_zone.main.id
  name    = "sierra"
  content = "100.105.42.127"
  type    = "A"
  proxied = false
  ttl     = 1
}

# *.sierra.tessro.ai -> sierra.tessro.ai
resource "cloudflare_record" "sierra_wildcard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "*.sierra"
  content = "sierra.${var.domain}"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# panopticon.tessro.ai -> GitHub Pages
resource "cloudflare_record" "panopticon" {
  zone_id = data.cloudflare_zone.main.id
  name    = "panopticon"
  content = "tessro.github.io"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}
