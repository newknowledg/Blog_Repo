terraform {
 backend "gcs" {
   bucket  = "none_your_business"
   prefix  = "terraform/state"
 }
}
