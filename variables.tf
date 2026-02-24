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

variable "portfolio_entries_bucket" {
  description = "The S3 bucket name we're saving portfolio entries to"
  type        = string
  default     = "deontevanterpool-portfolio-entries-bucket"
}

variable "templates_bucket" {
  description = "The S3 bucket name we're saving templates to"
  type        = string
  default     = "deontevanterpool-templates-bucket"
}

variable "assets_bucket" {
  description = "The S3 bucket name we're saving assets to"
  type        = string
  default     = "deontevanterpool-assets-bucket"
}

variable "env_bucket" {
  description = "The S3 bucket name we're saving env variables to"
  type        = string
  default     = "deontevanterpool-env-bucket"
}
