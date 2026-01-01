output "pages_url" {
  description = "Cloudflare Pages URL"
  value       = "https://${cloudflare_pages_project.site.subdomain}"
}

output "site_url" {
  description = "Live site URL"
  value       = "https://${var.domain}"
}
