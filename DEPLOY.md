# Deploy

## Setup

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
cp .mise.local.toml.example .mise.local.toml
# Edit both files with your credentials

tofu init
tofu apply
```

## Deploy

Push to `main` - Cloudflare Pages auto-deploys.
