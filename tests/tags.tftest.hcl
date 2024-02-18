provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Environment = "Test"
    }
  }
}

run "invalid_tags" {
  command = plan

  variables {
    identifier  = "test"
    vpc_id      = "vpc-01234567890abcdef"
    subnets     = ["subnet-1242421", "subnet-2344898"]
    db_password = "password"

    tags = {
      Name = "Foo"
    }
  }

  expect_failures = [var.tags]
}

run "valid_tags" {
  command = plan

  variables {
    identifier  = "test"
    vpc_id      = "vpc-01234567890abcdef"
    subnets     = ["subnet-1242421", "subnet-2344898"]
    db_password = "password"

    tags = {
      Project = "Foo"
    }
  }
}
