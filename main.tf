terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "5.18.1"
      }
  }
}
provider "aws" {
    region = "us-east-1"

}

variable "cidr" {
  default = "10.0.0.0/16"
}

/*variable "ami" {
    description = "AMI for EC2 instance"
}*/

variable "instance_type_value" {
    description = "Type of instance" 
    type = map(string)

    default = {
      "Dev" = "t2.micro"
      "PROD" = "t2.micro"
    }
}

variable "ec2_instance_name" {
    description = "Name of instance"  
    type = map(string)

    default = {
      "Dev" = "terraform-ec2-dev"
      "PROD" = "terraform-ec2-prod"
    }
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "server" {
    key_name = "DevSecOps_1"
    ami = "ami-053b0d53c279acc90"
    instance_type = lookup(var.instance_type_value , terraform.workspace, "t2.micro")
    tags = {
        Name = terraform.workspace
    }
     

    vpc_security_group_ids = [aws_security_group.webSg.id]
    subnet_id              = aws_subnet.sub1.id
    sh "pwd"
    sh "self.public_ip"

    connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = "./DevSecOps_1.pem"  # Replace with the path to your private key /workspaces/terraform-manifests/terraform-project/DevSecOps_1.pem
    
  }

  /*provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }*/

/*  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      #"sudo apt-get install -y python3-pip",  # Example package installation
      #"cd /home/ubuntu",
      #"sudo pip3 install flask",
      #"sudo python3 app.py &",
    ]
  } */
}

