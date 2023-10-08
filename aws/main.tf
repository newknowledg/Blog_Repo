provider "google" {
    project = "feisty-proton-401321"
    credentials = "${{ secrets.GCP_SA_KEY }}"
    region = "us-central1"
    zone = "us-central1-c"
}
