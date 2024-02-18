output "security_group" {
  description = "The ID of the security group to allow services access to the RDS instance"
  value       = try(aws_security_group.external.id, null)
}

output "secrets_arn" {
  description = "The ARN of the SecretsManager which holds secrets for the connection to the RDS instance"
  value       = try(aws_secretsmanager_secret.rds.arn, null)
}

output "get_secrets_policy" {
  description = "An object of IAM policy to allow read access of the SecretsManager"
  value       = try(aws_secretsmanager_secret.rds.arn, null)
}
