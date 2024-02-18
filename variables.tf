variable "identifier" {
  description = "Unique identifier to differentiate global resources"
  type        = string
}

variable "name" {
  description = "Name of this module which is used as identifier on all resources"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "The instance class of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "The PostgreSQL engine version for the RDS instance"
  type        = string
  default     = "16.1"
}

variable "allocated_storage" {
  description = "Storage capacity of the RDS instance in GigiBytes"
  type        = number
  default     = 20
}

variable "vpc_id" {
  description = "ID of the subnets' VPC"
  type        = string
  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "Must be valid VPC ID"
  }
}

variable "subnets" {
  description = "A list of IDs of subnets for the subnet group and potentially the RDS proxy"
  type        = list(string)
  validation {
    condition     = length(var.subnets) > 1
    error_message = "List of subnets must contain at least 2 elements"
  }
  validation {
    condition     = !contains([for v in var.subnets : startswith(v, "subnet-")], false)
    error_message = "Elements must be valid subnet IDs"
  }
}

variable "skip_final_snapshot" {
  description = "A flag for wether or not skipping the creation of a final snapshot befor deletion of the RDS instance"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Name of the database initially created in the RDS instance"
  type        = string
  default     = "postgres"
  validation {
    condition     = length(var.db_name) > 2
    error_message = "Name of database must be at least 3 characters"
  }
}

variable "db_username" {
  description = "Username of the master user in the RDS instance"
  type        = string
  default     = "postgres"
  validation {
    condition     = length(var.db_username) > 2
    error_message = "Username of master user must be at least 3 characters"
  }
}

variable "db_password" {
  description = "Password of the master user in the RDS instance"
  type        = string
  default     = null
  validation {
    condition     = length(coalesce(var.db_password, "password")) > 7
    error_message = "Password of master user must be at least 8 characters"
  }
}

variable "proxy" {
  description = "An object for the definition of a RDS proxy for the RDS instance"
  type = object({
    debug_logging                = bool
    idle_client_timeout          = number
    connection_borrow_timeout    = number
    max_connections_percent      = number
    max_idle_connections_percent = number
  })
  default = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
  validation {
    condition     = !contains(keys(var.tags), "Name")
    error_message = "Name tag is reserved and will be used automatically"
  }
}
