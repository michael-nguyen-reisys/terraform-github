#Provider is who is provider you are using e.g aws

provider "aws" {
    region = "us-east-2"
}

/* 

Syntax for creating a resource in Terraform is: 

resource "<PROVIDER>_<TYPE>" "<NAME>" {
    [CONFIG ...]
} 

PROVIDER = name of provider (e.g aws)
TYPE = type of resource created in provider (e.g my_instance)
CONFIG = consists of one or more arguments specific to the resource 

*/

resource "aws_instance" "example" {
    ami           = "ami-0dacb0c129b49f529"
    instance_type = "t2.micro"

    tags = {
        Name = "terraform-example"
    }

}

#Use and refer to Terraform documentation frequently