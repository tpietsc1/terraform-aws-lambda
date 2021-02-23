resource "aws_dynamodb_table" "table_1" {
  name             = "example-dynamodb-table-1"
  hash_key         = "UserId"
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"
  write_capacity   = 1

  attribute {
    name = "UserId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "table_2" {
  name             = "example-dynamodb-table-2"
  hash_key         = "UserId"
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "KEYS_ONLY"
  write_capacity   = 1

  attribute {
    name = "UserId"
    type = "S"
  }
}

resource "aws_lambda_alias" "example" {
  function_name    = module.lambda.function_name
  function_version = module.lambda.version
  name             = "prod"
}

data "archive_file" "dynamodb_handler" {
  output_path = "${path.module}/dynamodb.zip"
  type        = "zip"

  source {
    content  = "exports.handler = function(event, context, callback) { console.log(JSON.stringify(event, null, 2)); event.Records.forEach(function(record) { console.log(record.eventID); console.log(record.eventName); console.log('DynamoDB Record: %j', record.dynamodb);  }); callback(null, 'message');  };"
    filename = "index.js"
  }
}

module "lambda" {
  source = "../../.."

  description      = "Example usage for an AWS Lambda with a DynamoDb event source mapping"
  filename         = data.archive_file.dynamodb_handler.output_path
  function_name    = "example-with-dynamodb-event-source-mapping"
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.dynamodb_handler.output_base64sha256

  event_source_mappings = {
    table_1 = {
      // optionally overwrite arguments like 'batch_size'
      // from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
      batch_size        = 50
      event_source_arn  = aws_dynamodb_table.table_1.stream_arn
      starting_position = "LATEST"

      destination_config = {
        on_failure = {
          destination_arn = module.errors.this_sqs_queue_arn
        }
      }

      // optionally overwrite function_name in case an alias should be used in the
      // event source mapping, see https://docs.aws.amazon.com/lambda/latest/dg/configuration-aliases.html
      function_name = aws_lambda_alias.example.arn
    }

    table_2 = {
      event_source_arn = aws_dynamodb_table.table_2.stream_arn
      function_name    = aws_lambda_alias.example.arn
    }
  }
}

module "errors" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "2.1.0"

  message_retention_seconds = 1209600
  name                      = "${module.lambda.function_name}-processing-errors"
}

data "aws_iam_policy_document" "sqs" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      module.errors.this_sqs_queue_arn
    ]
  }
}

resource "aws_iam_policy" "sqs_policy" {
  policy = data.aws_iam_policy_document.sqs.json
}

resource "aws_iam_role_policy_attachment" "sqs_policy_attachment" {
  role       = module.lambda.role_name
  policy_arn = aws_iam_policy.sqs_policy.arn
}

