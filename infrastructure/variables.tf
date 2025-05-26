variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS"
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "Instance type"
  default     = "t2.medium"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  default     = "your-key-pair-name"
}
