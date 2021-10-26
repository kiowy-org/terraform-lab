# resource "aws_key_pair" "my_ec2" {
#     key_name   = "terraform-key"
#     public_key = file("./terraform.pub")
# }

resource "aws_security_group" "instance_sg" {
  name = "terraform-test-sg"
  
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "my_ec2" {
    # key_name      = aws_key_pair.my_ec2.key_name
    ami           = "ami-03e15a55e7067db82"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance_sg.id]

    # connection {
    #     type        = "ssh"
    #     user        = "ubuntu"
    #     private_key = file("./terraform")
    #     host        = self.public_ip
    # }

    # provisioner "remote-exec" {
    #     inline = [
    #       "sudo apt-get -f -y update",
    #       "sudo apt-get install -f -y apache2",
    #       "sudo systemctl start apache2",
    #       "sudo systemctl enable apache2",
    #       "sudo sh -c 'echo \"<h1>Hello Terraform</h1>\" > /var/www/html/index.html'",
    #     ]
    # }
}