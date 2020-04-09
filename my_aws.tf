provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "amazon2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_iam_role" "hd_ec2_cw_agent" {
  name               = "hd_ec2_cw_agent"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
     "Action": "sts:AssumeRole",
     "Principal": {
        "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
  }
  ]
}
EOF
  tags = {
    Target = "ec2WatchAgent"
  }
}

resource "aws_iam_instance_profile" "hd_ec2_cw_agent_profile" {
  name = "hd_ec2_cw_agent_profile"
  role = "${aws_iam_role.hd_ec2_cw_agent.name}"
}

resource "aws_iam_role_policy" "hd_ec2_cw_agent_policy" {
  name   = "hd_ec2_cw_agent_policy"
  role   = "${aws_iam_role.hd_ec2_cw_agent.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOF
}

resource "aws_instance" "hd_bastion" {
  ami                         = data.aws_ami.amazon2.image_id
  instance_type               = "t2.micro"
  key_name                    = "dima_note"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.hd_ec2_cw_agent_profile.name}"
}

output "public_ip" {
  value = aws_instance.hd_bastion.public_ip
}
