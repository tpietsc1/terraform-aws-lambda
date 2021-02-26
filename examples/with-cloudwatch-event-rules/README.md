# Example with DynamoDb event source mappings

Creates an AWS Lambda function triggered by EventBridge (CloudWatch Events) [rules](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents.html).

## Usage

To run this example execute:

```
$ terraform init
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` to destroy those resources.

## bootstrap with func

In case you are using [go](https://golang.org/) for developing your Lambda functions, you can also use [func](https://github.com/moritzzimmer/func) to bootstrap your project and get started quickly:

```
$ func new example-with-cloudwatch
$ cd example-with-cloudwatch && make init package plan
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |
| aws | >= 3.19 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.19 |

## Inputs

No input.

## Outputs

No output.
