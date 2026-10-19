output "site_url" {
    value = "https://storage.googleapis.com/${google_storage_bucket.site.name}/index.html"
}

output "site_bucket" {
    value = google_storage_bucket.site.name
}

output "logs_bucket" {
    value = google_storage_bucket.logs.name
}