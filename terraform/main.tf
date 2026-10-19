# In this file put all the logic to crete the proper infraestructure
terraform {
    required_version = ">= 1.5"
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "8.7.0"
        }

    }

    backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region = var.region
}

locals {
  env       = terraform.workspace
  build_dir = "${path.module}/../build"

  labels = {
    app        = "fullstack"
    env        = local.env
    managed_by = "terraform"
  }

  mime_types = {
    html = "text/html"
    js   = "application/javascript"
    css  = "text/css"
    json = "application/json"
    map  = "application/json"
    svg  = "image/svg+xml"
    png  = "image/png"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "google_storage_bucket" "logs" {
  name                        = "${var.project_id}-fullstack-${local.env}-logs"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
  labels                      = local.labels

  lifecycle {
    precondition {
      condition     = contains(["devel", "stage"], terraform.workspace)
      error_message = "Select a valid workspace: 'devel' or 'stage'."
    }
  }
}

resource "google_storage_bucket_iam_member" "log_writer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}

resource "google_storage_bucket" "site" {
  name                        = "${var.project_id}-fullstack-${local.env}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = var.public_access ? "inherited" : "enforced"
  force_destroy               = true
  labels                      = local.labels

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "site-${local.env}"
  }

  versioning {
    enabled = true
  }

  depends_on = [google_storage_bucket_iam_member.log_writer]
}

resource "google_storage_bucket_iam_member" "public_read" {
  count = var.public_access ? 1 : 0

  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "app" {
  for_each = fileset(local.build_dir, "**")

  bucket        = google_storage_bucket.site.name
  name          = each.value
  source        = "${local.build_dir}/${each.value}"
  content_type  = lookup(local.mime_types, lower(reverse(split(".", each.value))[0]), "application/octet-stream")
  cache_control = each.value == "index.html" ? "no-cache" : "public, max-age=3600"
}
