terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

variable "http_port" {
  type    = number
  default = 8080
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "fqdn" {
  type    = string
  default = "fls.silphco.net"
}

resource "aws_instance" "jetbrains_server" {
  ami           = "ami-045b0a05944af45c1"
  instance_type = "t2.medium"

  vpc_security_group_ids = [aws_security_group.jetbrains_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    useradd jetbrains-user --create-home --shell /bin/bash
    mkdir /home/jetbrains-user/.ssh
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwCGzyrD5cZKROThH8fxQfNAla4o4eYA6ZkBfKxvWiqRbD6SInI4fJ9JXspoLQT57G19Us10A9RtNPZHG4VTPETiiPYveOf4R3rB/un16/UQ8JjhRTWGvGMr/egSU4v1wRbHN0wk0CZlFrf6ezxoJrEbohh6Ri7Fxix7hMuAoKVeLz1xCLThbF274vGG9CPA5K1LHqO+ECao/LuRVzDyGgsUInR+lHrxinabq2GANCkdfAVvTc4CmTI7sBgvxHL5lyn3s8ZZGoKimPEnj2p1vKPlGTTLrAktrrTZK9cfhZ0YPrWUswaaTfkI6ocBvqkbEnwWYPuKx1B+VQgwHWFKi6F4JikfD7M80YhVikb4XeZgMFUdh+fLQwsT73FyjRWCYQiebm4VqIkrcDxL0eHySx1O+3VaL6I8O4DueMllLoo+6l5GuyW9ZbL4ewO/ck3u7NeIfckg1qLdXcUIw/GkLZdE0druxt7cSxTCun8PGK+Df5qklI5b4eRzQNeVBsK8cPzZVd7jqicyuL5mGe9Rp97nIoJsCeZW8Fd6kUdk4FG3f1A9i0eXQmjgt8Rk39xHuSOrB+JGjixpymhnJzDL5Qs3k3RlwSoJb8yYEEXpdYuJ9wPpPxNDdboedqZwHgQoDS8fcI3MOfFj4gsPjjD8LODKTErTqK6J5DgRgsEjuqAw==' > /home/jetbrains-user/.ssh/authorized_keys
    chown -R jetbrains-user.jetbrains-user /home/jetbrains-user/.ssh
    chmod 700 /home/jetbrains-user/.ssh
    chmod 600 /home/jetbrains-user/.ssh/authorized_keys
    echo "jetbrains-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jetbrains-user
  EOF
  /*
    provisioner "remote-exec" {
    inline = ["sudo dnf -y install python"]

    connection {
      type        = "ssh"
      user        = "centos"
      private_key = "${file(var.ssh_key_private)}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u centos -i '${self.public_ip},' --private-key ${var.ssh_key_private} fls.yml" 
  }
  */

  tags = {
    Name = "jetbrains-server"
  }
}

resource "aws_security_group" "jetbrains_sg" {
  name = " jetbrains-security-group"

  ingress {
    from_port = var.http_port
    to_port   = var.http_port
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  ingress {
    from_port = var.ssh_port
    to_port   = var.ssh_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"
    ]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"
    ]
  }
}

resource "aws_route53_record" "fls" {
  zone_id = "Z01042843KU2X1UBFH8NL" /* Need to pull the data from AWS via API to do this via variables */
  name    = var.fqdn
  type    = "A"
  ttl     = "60"
  records = [aws_instance.jetbrains_server.public_ip]
}

output "public_ip" {
  value       = [aws_instance.jetbrains_server.public_ip]
  description = "The public IP address of the website"
}