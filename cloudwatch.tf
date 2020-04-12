resource "aws_cloudwatch_event_rule" "CreateSnapshotEC2" {
  name        = "CreateSnapshotEC2"
  description = "create snapshot EC2 instances"
  schedule_expression = "cron(45 12 ? * SUN *)"
 
}

resource "aws_cloudwatch_event_target" "CreateSnapshotEC2EventTarget" {
  rule      = "${aws_cloudwatch_event_rule.CreateSnapshotEC2.name}"
  target_id = "CreateSnapshotEC2"
  arn       = "${aws_lambda_function.LambdaCreateSnapshotEC2.arn}"

  depends_on = [
      aws_lambda_function.LambdaCreateSnapshotEC2,
  ]

}

resource "aws_cloudwatch_event_rule" "PruneSnapshotEC2" {
  name        = "PruneSnapshotEC2"
  description = "Start instances midnight"
  schedule_expression = "cron(0 13 ? * SUN *)"
 
}

resource "aws_cloudwatch_event_target" "PruneSnapshotEC2EventTarget" {
  rule      = "${aws_cloudwatch_event_rule.PruneSnapshotEC2.name}"
  target_id = "PruneSnapshotEC2"
  arn       = "${aws_lambda_function.LambdaPruneSnapshotEC2.arn}"

  depends_on = [
      aws_lambda_function.LambdaPruneSnapshotEC2,
  ]

}

