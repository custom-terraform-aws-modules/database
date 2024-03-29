provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

run "invalid_identifier" {
  command = plan

  variables {
    identifier = "ab"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-2344898", "subnet-2344898"]
  }

  expect_failures = [var.identifier]
}

run "valid_identifier" {
  command = plan

  variables {
    identifier = "abc"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-2344898", "subnet-2344898"]
  }
}

run "invalid_vpc_id" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "abc-01234567890abcdef"
    subnets    = ["subnet-1242421", "subnet-2344898"]
  }

  expect_failures = [var.vpc]
}

run "invalid_subnets_length" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-2344898"]
  }

  expect_failures = [var.subnets]
}

run "invalid_subnets" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-2344898", "foobar-2344898"]
  }

  expect_failures = [var.subnets]
}

run "invalid_db_name" {
  command = plan

  variables {
    identifier = "test"
    vpc        = "vpc-01234567890abcdef"
    subnets    = ["subnet-2344898", "subnet-2344898"]
    db_name    = "ab"
  }

  expect_failures = [var.db_name]
}

run "invalid_db_username" {
  command = plan

  variables {
    identifier  = "test"
    vpc         = "vpc-01234567890abcdef"
    subnets     = ["subnet-2344898", "subnet-2344898"]
    db_username = "ab"
  }

  expect_failures = [var.db_username]
}

run "invalid_db_password" {
  command = plan

  variables {
    identifier  = "test"
    vpc         = "vpc-01234567890abcdef"
    subnets     = ["subnet-2344898", "subnet-2344898"]
    db_password = "passwor"
  }

  expect_failures = [var.db_password]
}
