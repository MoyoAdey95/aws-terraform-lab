variable "name_prefix" {
  description = "Prefix for the repository name."
  type        = string
}

variable "keep_image_count" {
  description = "Number of most recent images to keep."
  type        = number
  default     = 10
}
