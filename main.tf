terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = lookup(var.props, "region")
}

data "aws_ssm_parameter" "activation_code" {
  name = "/prem/mi/activation_code"
}

data "aws_ssm_parameter" "activation_id" {
  name = "/prem/mi/activation_id"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_instance" "ec2_resource" {

  ami = lookup(var.props, "ami")
  instance_type = lookup(var.props, "type")
  subnet_id = lookup(var.props, "subnet")
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "JosephKP_dernier"

  user_data = <<EOF
#!/bin/bash
mkdir /tmp/ssm
curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm -o /tmp/ssm/amazon-ssm-agent.rpm
sudo yum install -y /tmp/ssm/amazon-ssm-agent.rpm
sudo systemctl stop amazon-ssm-agent
# edit the code, id and region in the command below
sudo amazon-ssm-agent -register -code "${data.aws_ssm_parameter.activation_code.value}" -id "${data.aws_ssm_parameter.activation_id.value}" -region "${lookup(var.props, "region")}"
sudo systemctl start amazon-ssm-agent
  EOF

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name ="MI-01"
    Environment = "DEV"
    OS = "REDHAT"
    IaC = "Terraform"
  }

} 


resource "aws_iam_role" "instance_role" {
  name = "instance_role"
  assume_role_policy = "${file("policy/ec2-assume-role.json")}"
  tags = {
      IaC = "Terraform"
  }
}


resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm_policy"
  role = "${aws_iam_role.instance_role.id}"
  policy = "${file("policy/ssm-policy.json")}"
}


output "ec2instance" {
  value = aws_instance.ec2_resource.public_ip
}