data "aws_instance" "bastion" {
  instance_id = aws_instance.bastion.id
}

resource "aws_cloudwatch_log_group" "cw_log_group" {
  name = "/ec2/deny/port"

  tags = {
    Name = "/ec2/deny/port"
  }
}

resource "aws_cloudwatch_log_stream" "cw_log_stream" {
  name = "deny-${data.aws_instance.bastion.id}"
  log_group_name = aws_cloudwatch_log_group.cw_log_group.name
}