data "aws_region" "cloudwatch" {}

variable "rds_total_memory" {
  default = 1073741824
}

variable "env" {
  default = "$"
}

resource "aws_cloudwatch_dashboard" "cw" {
  dashboard_name = "apdev-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 5,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "FreeableMemory",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              {"id": "m1","visible": false}
            ],
            [
              {
                "expression": "((((${var.rds_total_memory}-m1) / 1024) / 1024) /1024) * 100", 
                "label": "Memory Utilization: ${var.env}{LAST}",
                "id": "e1"
              }
            ]
          ],
          view = "timeSeries",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS Memory Utilization"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 10,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "FreeableMemory",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              {"id": "m1","visible": false}
            ],
            [
              {
                "expression": "((((${var.rds_total_memory}-m1) / 1024) / 1024) /1024) * 100",
                "label": "Memory Utilization: ${var.env}{LAST}",
                "id": "e1"
              }
            ]
          ],
          view = "gauge",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS Memory Utilization",
          setPeriodToTimeRange = true
          yAxis  = { 
            left = {
              min = 0,
              max = 100,
            }
          }
        }
      },
      {
        type   = "metric",
        x      = 5,
        y      = 5,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              {
                "label": "RDS_CPU: ${var.env}{LAST}"
              }
            ]
          ],
          view = "timeSeries",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS_CPU"
        }
      },
      {
        type   = "metric",
        x      = 5,
        y      = 10,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              {
                "label": "RDS_CPU: ${var.env}{LAST}"
              }
            ]
          ],
          view = "gauge",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS_CPU"
          setPeriodToTimeRange = true
          yAxis  = { 
            left = {
              min = 0,
              max = 100,
            }
          }
        }
      },
      {
        type   = "metric",
        x      = 5,
        y      = 0,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              {
                "expression": "m1 * 1000",
                "label": "ReadLatency (ms): ${var.env}{LAST}",
                "id": "e1"
              }
            ],
            [
              "AWS/RDS",
              "ReadLatency",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              { "id": "m1", "visible": false }
            ]
          ],
          view = "timeSeries",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS ReadLatency"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 5,
        height = 5,
        properties = {
          metrics = [
            [
              {
                "expression": "m1 * 1000",
                "label": "WriteLatency (ms): ${var.env}{LAST}",
                "id": "e1"
              }
            ],
            [
              "AWS/RDS",
              "WriteLatency",
              "DBInstanceIdentifier",
              "${aws_db_instance.db.identifier}",
              { "id": "m1", "visible": false }
            ]
          ],
          view = "timeSeries",
          stacked = true,
          period = 30,
          stat   = "Average",
          region = "${data.aws_region.cloudwatch.name}",
          title  = "RDS WriteLatency"
        }
      }
    ]
  })
}
