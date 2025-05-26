variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "eu-north-1"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS"
  default     = "ami-0c1ac8a41498c1a9c"
}

variable "instance_type" {
  description = "Instance type"
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  default     = "your-key-pair-name"
}
