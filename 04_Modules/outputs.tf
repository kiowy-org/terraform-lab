output "website_bucket_name" {
    description = "Nom du bucket (id)"
    value       = module.website_bucket.name
}
  
output "website_endpoint" {
    description = "Nom de domaine du bucket"
    value       = module.website_bucket.website_endpoint
}