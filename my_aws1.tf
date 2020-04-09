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

variable "git_config" {
  type = string
  default = <<-EOT
    Content-Type: multipart/mixed; boundary="//"
    MIME-Version: 1.0

    --//
    Content-Type: text/cloud-config; charset="us-ascii"
    MIME-Version: 1.0
    Content-Transfer-Encoding: 7bit
    Content-Disposition: attachment; filename="cloud-config.txt"
    
    #cloud-config
    cloud_final_modules:
    - [scripts-user, always]
    
    --//
    Content-Type: text/x-shellscript; charset="UTF-8"
    MIME-Version: 1.0
    Content-Disposition: attachment; filename="userdata.txt"
    
    #!/bin/bash
    HOME=/home/ec2-user
    yum install -y git zip unzip
    curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip
    unzip /tmp/terraform.zip -d /usr/sbin/

    mkdir $HOME/.aws

    cat << EOF > $HOME/.aws/credentials
    [default]
    aws_access_key_id = #################
    aws_secret_access_key = ###################
    EOF
    
    chmod 600 $HOME/.aws/credentials

    cat << EOF > $HOME/.aws/config
    [default]
    region = eu-central-1
    output = json
    EOF

    cat << EOF > $HOME/.gitconfig
    [user]
        email = 
        name = 
    [alias]
        graph = log --all --decorate --graph --oneline
    [diff "sopsdiffer"]
        textconv = sops -d
    EOF

    cat << EOF > $HOME/.git-credentials
    EOF

    chown ec2-user:ec2-user -R $HOME

    su ec2-user -c "cd $HOME && git clone https://github.com/hrapovd/udemy_10_cases.git"

    --//
  EOT
}

resource "aws_instance" "hd_bastion" {
  ami                         = data.aws_ami.amazon2.image_id
  instance_type               = "t2.micro"
  key_name                    = "dima_note"
  associate_public_ip_address = true
  user_data = var.git_config
}

output "public_ip" {
  value = aws_instance.hd_bastion.public_ip
}
