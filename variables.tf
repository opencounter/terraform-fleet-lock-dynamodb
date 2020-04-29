variable name {
  default = "fleetlock"
  type    = string
}

variable purpose {
  default = "fleetlock"
  type    = string
}

variable stage {
  description = "dev|production"
  type        = string
  default     = "dev"
}

variable debug_logging {
  type    = bool
  default = false
}

variable alarm_topic_arn {
  type        = string
  description = "ARN of SNS topic to send monitoring alarms to"
}

variable lease_duration {
  type        = number
  default     = 900
  description = "Duration (TTL) of Fleet Lock mutex leases, in seconds"
}
