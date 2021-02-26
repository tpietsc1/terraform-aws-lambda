module "source" {
  source = "../fixtures"
}

resource "aws_lambda_alias" "example" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = "prod"
}

module "lambda" {
  source           = "../../"
  description      = "Example usage for an AWS Lambda with Amazon EventBridge (CloudWatch Events) rules."
  filename         = module.source.output_path
  function_name    = "example-with-cloudwatch-events"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  source_code_hash = module.source.output_base64sha256

  cloudwatch_event_rules = {
    scheduled = {
      // optionally overwrite `arn` in case an alias should be used for the event rule
      arn                 = aws_lambda_alias.example.arn
      schedule_expression = "rate(1 minute)"
    }

    pattern = {
      // optionally overwrite arguments like 'description'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule
      description   = "Triggered by CloudTrail"
      event_pattern = <<PATTERN
      {
        "detail-type": [
          "AWS Console Sign In via CloudTrail"
        ]
      }
      PATTERN
    }
  }
}