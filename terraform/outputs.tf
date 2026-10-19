output "site_url" {
    value = ""
}

output "site_bucket" {
    value = google_storage_bucket.site_bucket.name
}

output "logs_bucket" {
    value = google_storage_bucket.logs.name
}