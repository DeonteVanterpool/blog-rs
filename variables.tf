variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "asims-notebook"
}

variable "instance_type" {
  description = "The EC2 instance's type."
  type        = string
  default     = "t3a.nano"
}

variable "region" {
  description = "The region we're deploying to"
  type        = string
  default     = "us-east-1"
}
