terraform {
 backend "aws" {
   bucket  = "none_your_business"
   prefix  = "terraform/state"
 }
}
