provider "aws" {
    region = "us-east-2"
}

#Module test
module "webserver_cluster" {
  source = ".//../../../modules/services/webserver-cluster"  
}

