terraform {
  backend "s3" {
    bucket         = "tf-state-juice-shop-james-369042512949"
    key            = "juice-shop/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    use_lockfile   = true
  }
}
