resource "aws_iam_role" "LambdaCreateSnapshotEC2Role" {
  name = "LambdaCreateSnapshotEC2Role"

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

resource "aws_iam_policy" "LambdaCreateSnapshotEC2Policy" {
  name        = "LambdaCreateSnapshotEC2Policy"

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
      "ec2:CreateSnapshot",
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



resource "aws_iam_role_policy_attachment" "LambdaCreateSnapshotAttachment" {
  role   = "${aws_iam_role.LambdaCreateSnapshotEC2Role.id}"
  policy_arn = "${aws_iam_policy.LambdaCreateSnapshotEC2Policy.arn}"
}

data "null_data_source" "lambdaCreateSnapshotFile" {
  inputs = {
    filename = "/lambda/LambdaCreateSnapshotEC2.js"
  }
}

data "null_data_source" "lambdaCreateSnapshotArchive" {
  inputs = {
    filename = "${path.module}/lambda/LambdaCreateSnapshotEC2.zip"
  }
} 

data "archive_file" "lambdaCreateSnapshot" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  source_file = "${data.null_data_source.lambdaCreateSnapshotFile.outputs.filename}"
  output_path = "${data.null_data_source.lambdaCreateSnapshotArchive.outputs.filename}"
}

resource "aws_cloudwatch_log_group" "lambdaCreateSnapshotLoggingGroup" {
  name = "/aws/lambda/LambdaCreateSnapshotEC2"
}

resource "aws_lambda_function" "LambdaCreateSnapshotEC2" {
  filename         = "${data.archive_file.lambdaCreateSnapshot.output_path}"
  function_name    = "LambdaCreateSnapshotEC2"
  role             = "${aws_iam_role.LambdaCreateSnapshotEC2Role.arn}"
  handler          = "LambdaCreateSnapshotEC2.handler"
  source_code_hash = "${data.archive_file.lambdaCreateSnapshot.output_base64sha256}"
  runtime          = "nodejs10.x"
  timeout          = 60

}

resource "aws_lambda_permission" "allowCreateSnapshotEC2Rule" {
    statement_id = "AllowExecutionFromCloudWatchCreateSnapshotEC2Rule"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.LambdaCreateSnapshotEC2.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.CreateSnapshotEC2.arn}"
}




