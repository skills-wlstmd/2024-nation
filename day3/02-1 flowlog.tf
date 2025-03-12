resource "aws_cloudwatch_log_group" "flow_log" {
  name = "apdev-traffic-logs"

  tags = {
    Name = "apdev-traffic-logs"
  }
}

resource "aws_flow_log" "flow_log" {
    iam_role_arn    = aws_iam_role.role.arn
    log_destination = aws_cloudwatch_log_group.flow_log.arn
    traffic_type    = "ALL"
    vpc_id          = aws_vpc.main.id
    log_format      = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status}"

    tags = {
      Name = "apdev-traffic-logs"
    }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
    name               = "apdev-traffic-logs"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "role_policy" {
  name   = "apdev-traffic-logs"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.policy.json
}