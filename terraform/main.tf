provider "google" {
  project = var.project_name
  region = var.region
  zone = var.zone
}

#----------------------------------------------------------------------------------------------
#  Enable APIs
#      - Cloud Function
#      - Pub/Sub
#      - Firestore
#----------------------------------------------------------------------------------------------


module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "3.3.0"

  project_id    = var.project_name
  activate_apis =  [
    "cloudresourcemanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "firestore.googleapis.com",
    "run.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
  ]

  disable_services_on_destroy = false
  disable_dependent_services  = false
}


#----------------------------------------------------------------------------------------------
#  Loader Function
#      - Create Source Bucket
#      - Create temp code bucket
#      - Copy Code
#      - Create loader function based on source code and trigger from cloud bucket
#----------------------------------------------------------------------------------------------


resource "google_storage_bucket" "source_bucket" {
  name = "${var.project_name}-source-bucket"
}


resource "google_storage_bucket" "function-code-bucket" {
  name = "${var.project_name}-archive-bucket"
}

resource "google_storage_bucket_object" "archive" {
  bucket = google_storage_bucket.function-code-bucket.name
  name = "loader.zip"
  source = "../source-functions/loader.zip"
}

resource "google_cloudfunctions_function" "loader" {
  name = "loader"
  runtime = "python37"

  source_archive_bucket = google_storage_bucket.function-code-bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  entry_point = "loader"

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource = google_storage_bucket.source_bucket.name
  }
  environment_variables = {
    TOPIC_NAME = google_pubsub_topic.pubsub.name
  }
}



#---------------------------------------------------------
# Create Subscriber function
#   - Copy source code to same Archive bucket
#   - Create subscriber function based on trigger on pub/sub
#---------------------------------------------------------


resource "google_storage_bucket_object" "archive2" {
  bucket = google_storage_bucket.function-code-bucket.name
  name = "subscriber.zip"
  source = "../source-functions/subscriber.zip"
}

resource "google_cloudfunctions_function" "subscriber" {
  name = "subscriber"
  runtime = "python37"
  source_archive_bucket = google_storage_bucket.function-code-bucket.name
  source_archive_object = google_storage_bucket_object.archive2.name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.pubsub.name
  }

  entry_point = "hello_pubsub"
}

#---------------------------------------------------------
# Create Pub/Sub Topic
#   - NOTIFICATION
#---------------------------------------------------------


resource "google_pubsub_topic" "pubsub" {
  name = "emp-notification"
}


#----------------------------------------------------------------------------------------------
#  CLOUD RUN
#      - Enable API
#      - Create Service
#      - Expose the service to the public
#----------------------------------------------------------------------------------------------

resource "google_cloud_run_service" "my-service" {
  name = var.service_name
  location = var.region

  template  {
    spec {
    containers {
            image = "gcr.io/cloudrun/hello"
    }
  }
  }
}

resource "google_cloud_run_service_iam_member" "allUsers" {
  service  = google_cloud_run_service.my-service.name
  location = google_cloud_run_service.my-service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}


resource "google_sourcerepo_repository" "repo" {
  name = var.repository_name
  depends_on = [module.project_services.project_id]
}


#----------------------------------------------------------------------------------------------
#  Cloud Build
#  -  Create trigger
#  -  set permission
#----------------------------------------------------------------------------------------------

data "google_project" "project" {
}

resource "google_cloudbuild_trigger" "cloud_build_trigger" {
  name = var.repository_name
  description = "Cloud Source Repository Trigger ${var.repository_name} (${var.branch_name})"
  trigger_template {
    repo_name = var.repository_name
    branch_name = var.branch_name
  }

  filename = "cloudbuild.yaml"
  substitutions = {
    _SERVICE_NAME= var.service_name
    _REGION = var.region
  }
}


resource "google_project_iam_binding" "binding" {
  members = ["serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"]
  role = "roles/run.admin"
  depends_on = [module.project_services.project_id]
}

resource "google_project_iam_binding" "sa" {
  members = ["serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"]
  role = "roles/iam.serviceAccountUser"
  depends_on = [module.project_services.project_id]
}
