# create random string for database password if it is not provided
resource "random_string" "db_password" {
  count   = var.db_password != null ? 0 : 1
  length  = 32
  special = true
}

locals {
  engine        = "postgres"
  engine_family = "POSTGRESQL"
  port          = 5432
  db_password   = var.db_password != null ? var.db_password : random_string.db_password[0].result
}

################################
# Security Groups              #
################################

resource "aws_security_group" "proxy" {
  count       = var.proxy != null ? 1 : 0
  name        = "${var.identifier}-rds-proxy"
  description = "Allows RDS proxy to access the RDS instance and other services to access the RDS proxy"
  vpc_id      = var.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds"
  description = var.proxy != null ? "Allows RDS instance to be accessed by RDS proxy" : "Allows RDS instance to be accessed by services"
  vpc_id      = var.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_security_group" "external" {
  name        = "${var.identifier}-external"
  description = var.proxy != null ? "Allows services to access the RDS proxy" : "Allows services to access the RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "proxy" {
  count                        = var.proxy != null ? 1 : 0
  security_group_id            = aws_security_group.proxy[0].id
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_ingress_rule" "proxy" {
  count                        = var.proxy != null ? 1 : 0
  security_group_id            = aws_security_group.proxy[0].id
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.external.id
}

resource "aws_vpc_security_group_ingress_rule" "rds" {
  security_group_id            = aws_security_group.rds.id
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.proxy != null ? aws_security_group.proxy[0].id : aws_security_group.external.id
}

resource "aws_vpc_security_group_egress_rule" "external" {
  security_group_id            = aws_security_group.external.id
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.proxy != null ? aws_security_group.proxy[0].id : aws_security_group.rds.id
}

################################
# RDS Instance                 #
################################

resource "aws_db_subnet_group" "main" {
  name        = var.identifier
  description = "Groups subnets for RDS instance"
  subnet_ids  = var.subnets

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_db_instance" "main" {
  identifier             = var.identifier
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  engine                 = local.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  username               = var.db_username
  password               = local.db_password
  port                   = local.port
  skip_final_snapshot    = var.skip_final_snapshot
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

################################
# RDS Proxy                    #
################################

resource "aws_secretsmanager_secret" "proxy" {
  count                   = var.proxy != null ? 1 : 0
  name                    = "${var.identifier}-rds-proxy"
  recovery_window_in_days = 0

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

# RDS Proxy uses these secrets with exact key match to connect to the RDS instance
resource "aws_secretsmanager_secret_version" "proxy" {
  count     = var.proxy != null ? 1 : 0
  secret_id = aws_secretsmanager_secret.proxy[0].id
  secret_string = jsonencode(
    {
      username             = var.db_username
      password             = local.db_password
      engine               = local.engine
      host                 = aws_db_instance.main.address
      port                 = tostring(local.port)
      dbInstanceIdentifier = aws_db_instance.main.id
    }
  )
}

data "aws_iam_policy_document" "assume_role" {
  count = var.proxy != null ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "proxy" {
  count = var.proxy != null ? 1 : 0

  statement {
    effect = "Allow"

    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_secretsmanager_secret.proxy[0].arn]
  }
}

resource "aws_iam_role" "proxy" {
  count              = var.proxy != null ? 1 : 0
  name               = "${var.identifier}-ServiceRoleForRDSProxy"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  inline_policy {
    name   = "${var.identifier}-GetRDSProxySecrets"
    policy = data.aws_iam_policy_document.proxy[0].json
  }

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_db_proxy" "main" {
  count                  = var.proxy != null ? 1 : 0
  name                   = var.identifier
  debug_logging          = try(var.proxy["debug_logging"], false)
  engine_family          = local.engine_family
  idle_client_timeout    = try(var.proxy["idle_client_timeout"], 1800)
  require_tls            = true
  role_arn               = aws_iam_role.proxy[0].arn
  vpc_security_group_ids = [aws_security_group.proxy[0].id]
  vpc_subnet_ids         = var.subnets

  auth {
    auth_scheme = "SECRETS"
    description = "RDS proxy authentificates through secrets from RDS' SecretsManager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.proxy[0].arn
  }

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_db_proxy_default_target_group" "main" {
  count         = var.proxy != null ? 1 : 0
  db_proxy_name = aws_db_proxy.main[0].name

  connection_pool_config {
    connection_borrow_timeout    = try(var.proxy["connection_borrow_timeout"], 120)
    max_connections_percent      = try(var.proxy["max_connections_percent"], 100)
    max_idle_connections_percent = try(var.proxy["max_idle_connections_percent"], 50)
  }
}

resource "aws_db_proxy_target" "main" {
  count                  = var.proxy != null ? 1 : 0
  db_instance_identifier = aws_db_instance.main.identifier
  db_proxy_name          = aws_db_proxy.main[0].name
  target_group_name      = aws_db_proxy_default_target_group.main[0].name
}

################################
# Exported Secrets             #
################################

resource "aws_secretsmanager_secret" "rds" {
  name                    = "${var.identifier}-rds"
  recovery_window_in_days = 0

  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    DB_HOST = var.proxy != null ? aws_db_proxy.main[0].endpoint : aws_db_instance.main.address
    DB_PORT = tostring(local.port)
    DB_NAME = var.db_name
    DB_USER = var.db_username
    DB_PASS = local.db_password
  })
}

# IAM policy document which is exported from this module through outputs.tf
locals {
  policy_name = "${var.identifier}-GetRDSSecrets"
}

data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"

    actions = ["secretsmanager:GetSecretValue"]

    resources = [aws_secretsmanager_secret.rds.arn]
  }
}
