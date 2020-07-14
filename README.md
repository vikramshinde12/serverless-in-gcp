## The Full Stack App using Serverless services on GCP.
Following components are used
* Google Cloud Storage
* Pub/Sub
* Cloud Function
* Cloud Function
* Cloud Firestore
* Cloud Source Repository
* Cloud Build
* Google Container Registry
* Cloud Run

![Architecture](https://github.com/vikramshinde12/serverless-in-gcp/blob/master/Architecture.jpg)

### Create Service Account
1. Create Service Account
2. Assign the Editor, Security Admin and Source Repository Administrator role.
3. Download the key and renamed it as terraform-key.json

### Create Config data in Firestore

1. Go to Firestore
2. Select Native Mode
3. Select a Location (e.g. United States)
4. Click on "Create Database"

### Create Infrastructure using Terraform
1. Create Project
2. Create SA, Assign the roles: Editor 
and download key as terraform.json
3. export GOOGLE_CLOUD_KEYFILE_JSON=terraform-key.json
4. terraform init
5. terraform plan
6. terraform apply


The complete detail about this repo is available in the [please refer the blog](https://medium.com/@vikramshinde/serverless-on-google-cloud-platform-4a8711d592c1)
