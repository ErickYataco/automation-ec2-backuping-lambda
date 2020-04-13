resource "aws_iam_role" "LambdaPruneSnapshotEC2Role" {
  name = "LambdaPruneSnapshotEC2Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "LambdaPruneSnapshotEC2Policy" {
  name        = "LambdaPruneSnapshotEC2Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "arn:aws:logs:*:*:*",
    "Effect": "Allow"
  },
  {
    "Action": [
      "ec2:PruneSnapshot",
      "ec2:CreateTags",
      "ec2:DeleteSnapshot",
      "ec2:Describe*",
      "ec2:ModifySnapshotAttribute",
      "ec2:ResetSnapshotAttribute"
    ],
    "Resource": "*",
    "Effect": "Allow"
  }]
}
EOF
}



resource "aws_iam_role_policy_attachment" "LambdaPruneSnapshotAttachment" {
  role   = "${aws_iam_role.LambdaPruneSnapshotEC2Role.id}"
  policy_arn = "${aws_iam_policy.LambdaPruneSnapshotEC2Policy.arn}"
}

data "null_data_source" "lambdaPruneSnapshotFile" {
  inputs = {
    filename = "/lambda/LambdaPruneSnapshotEC2.js"
  }
}

data "null_data_source" "lambdaPruneSnapshotArchive" {
  inputs = {
    filename = "${path.module}/lambda/LambdaPruneSnapshotEC2.zip"
  }
} 

data "archive_file" "lambdaPruneSnapshot" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  source_file = "${data.null_data_source.lambdaPruneSnapshotFile.outputs.filename}"
  output_path = "${data.null_data_source.lambdaPruneSnapshotArchive.outputs.filename}"
}

resource "aws_cloudwatch_log_group" "lambdaPruneSnapshotLoggingGroup" {
  name = "/aws/lambda/LambdaPruneSnapshotEC2"
}

resource "aws_lambda_function" "LambdaPruneSnapshotEC2" {
  filename         = "${data.archive_file.lambdaPruneSnapshot.output_path}"
  function_name    = "LambdaPruneSnapshotEC2"
  role             = "${aws_iam_role.LambdaPruneSnapshotEC2Role.arn}"
  handler          = "LambdaPruneSnapshotEC2.handler"
  source_code_hash = "${data.archive_file.lambdaPruneSnapshot.output_base64sha256}"
  runtime          = "nodejs10.x"
  timeout          = 120

}

resource "aws_lambda_permission" "allowPruneSnapshotEC2Rule" {
    statement_id = "AllowExecutionFromCloudWatchPruneSnapshotEC2Rule"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.LambdaPruneSnapshotEC2.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.PruneSnapshotEC2.arn}"
}




