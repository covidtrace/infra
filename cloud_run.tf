resource "google_cloud_run_service" "operator" {
  name                       = "operator"
  location                   = "us-central1"
  autogenerate_revision_name = true

  template {
    spec {
      service_account_name = google_service_account.cloudrun.email
      containers {
        image = "gcr.io/covidtrace/operator@sha256:8a42d06d7d5887b43204d0a9e22c314183648a0ac4560d21df99424a1632340b"
        env {
          name  = "TWILIO_FROM_NUMBER"
          value = data.google_kms_secret.twilio_from_number.plaintext
        }
        env {
          name  = "TWILIO_ACCOUNT_SID"
          value = data.google_kms_secret.twilio_account_sid.plaintext
        }
        env {
          name  = "TWILIO_AUTH_TOKEN"
          value = data.google_kms_secret.twilio_auth_token.plaintext
        }
        env {
          name  = "JWT_SIGNING_KEY"
          value = data.google_kms_secret.jwt_signing_key.plaintext
        }
        env {
          name  = "JWT_TOKEN_DURATION"
          value = "24h"
        }
        env {
          name  = "JWT_REFRESH_DURATION"
          value = "2016h"
        }
        env {
          name  = "CLOUD_STORAGE_BUCKET"
          value = google_storage_bucket.operator.name
        }
        env {
          name  = "JWT_NAMESPACE"
          value = "covidtrace"
        }
        env {
          name  = "HASH_SALT"
          value = data.google_kms_secret.hash_salt.plaintext
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service" "notary" {
  name                       = "notary"
  location                   = "us-central1"
  autogenerate_revision_name = true

  template {
    spec {
      service_account_name = google_service_account.cloudrun.email
      containers {
        image = "gcr.io/covidtrace/notary@sha256:c4d74b549bd4d5247aed234346455ac6693252db08c10e585911ca1b928a75c2"
        env {
          name  = "GOOGLE_SERVICE_ACCOUNT"
          value = base64decode(google_service_account_key.notary.private_key)
        }
        env {
          name  = "CLOUD_STORAGE_BUCKETS"
          value = "covidtrace-holding,covidtrace-symptoms,covidtrace-exposures,covidtrace-tokens"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service" "aggregator" {
  name                       = "aggregator"
  location                   = "us-central1"
  autogenerate_revision_name = true

  template {
    spec {
      service_account_name = google_service_account.cloudrun.email
      containers {
        image = "gcr.io/covidtrace/aggregator@sha256:7aedef535829317a9eeb8acd87185b1a76bc0bca3e9d2143412ed01f0f572cad"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "aggregator_cloudscheduler" {
  location = google_cloud_run_service.aggregator.location
  project  = google_cloud_run_service.aggregator.project
  service  = google_cloud_run_service.aggregator.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cloudscheduler.email}"
}
