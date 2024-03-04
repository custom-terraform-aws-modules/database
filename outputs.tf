output "security_group" {
  description = "The ID of the security group to allow services access to the RDS instance."
  value       = try(aws_security_group.external.id, null)
}

output "secrets_arn" {
  description = "The ARN of the SecretsManager which holds secrets for the connection to the RDS instance."
  value       = try(aws_secretsmanager_secret.rds.arn, null)
}
