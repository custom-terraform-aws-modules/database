provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

run "valid_proxy" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-1242421", "subnet-2344898"]

    proxy = {
      debug_logging                = false
      idle_client_timeout          = 1800
      connection_borrow_timeout    = 120
      max_connections_percent      = 100
      max_idle_connections_percent = 50
    }
  }

  assert {
    condition     = length(aws_security_group.proxy) == 1
    error_message = "Proxy security group was not created"
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.proxy) == 1
    error_message = "Proxy security group egress rule was not created"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.proxy) == 1
    error_message = "Proxy security group ingress rule was not created"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.proxy) == 1
    error_message = "Proxy SecretsManager was not created"
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.proxy) == 1
    error_message = "Proxy secret version was not created"
  }

  assert {
    condition     = length(aws_iam_role.proxy) == 1
    error_message = "Proxy IAM role was not created"
  }

  assert {
    condition     = length(aws_db_proxy.main) == 1
    error_message = "Proxy was not created"
  }

  assert {
    condition     = length(aws_db_proxy_default_target_group.main) == 1
    error_message = "Proxy target group was not created"
  }

  assert {
    condition     = length(aws_db_proxy_target.main) == 1
    error_message = "Proxy target connection was not created"
  }
}

run "no_proxy" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-1242421", "subnet-2344898"]

    proxy = null
  }

  assert {
    condition     = length(aws_security_group.proxy) == 0
    error_message = "Proxy security group was created unexpectedly"
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.proxy) == 0
    error_message = "Proxy security group egress rule was created unexpectedly"
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.proxy) == 0
    error_message = "Proxy security group ingress rule was created unexpectedly"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.proxy) == 0
    error_message = "Proxy SecretsManager was created unexpectedly"
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.proxy) == 0
    error_message = "Proxy secret version was created unexpectedly"
  }

  assert {
    condition     = length(aws_iam_role.proxy) == 0
    error_message = "Proxy IAM role was created unexpectedly"
  }

  assert {
    condition     = length(aws_db_proxy.main) == 0
    error_message = "Proxy was created unexpectedly"
  }

  assert {
    condition     = length(aws_db_proxy_default_target_group.main) == 0
    error_message = "Proxy target group was created unexpectedly"
  }

  assert {
    condition     = length(aws_db_proxy_target.main) == 0
    error_message = "Proxy target connection was created unexpectedly"
  }
}
