variable "location" {
  description = "Azure region for this single-region lab."
  type        = string
  default     = "uksouth"
}

variable "project" {
  description = "Short resource-name prefix; a generated suffix makes global names distinct."
  type        = string
  default     = "junior-web"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,29}[a-z0-9]$", var.project))
    error_message = "Use 3 to 31 lowercase letters, digits or hyphens; start with a letter and end with a letter or digit."
  }
}
