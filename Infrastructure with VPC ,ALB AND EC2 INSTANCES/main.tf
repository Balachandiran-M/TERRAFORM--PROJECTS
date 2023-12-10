resource "aws_vpc" "vpc" {
    cidr_block = var.vpc
tags = {
  name="terraform"
}
}
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.vpc.id
  availability_zone = "ap-south-1a"
  cidr_block = var.subnet1
  map_public_ip_on_launch = true
}
resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.vpc.id
  availability_zone = "ap-south-1b"
  cidr_block = var.subnet1
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.ig.id

  }
}
resource "aws_route_table_association" "association1" {
  route_table_id = aws_route_table.route.id
  subnet_id = aws_subnet.subnet1.id
}
resource "aws_route_table_association" "association2" {
  route_table_id = aws_route_table.route.id
  subnet_id = aws_subnet.subnet2.id
}
resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.cidr_block
  }
  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.cidr_block
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = var.cidr_block
  }
}
resource "aws_instance" "ec1" {
  ami ="ami-02a2af70a66af6dfb"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.subnet1.id
  user_data = base64encode(file("userdata.sh"))
}
resource "aws_instance" "ec2" {
  ami ="ami-02a2af70a66af6dfb"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.subnet2.id
  user_data = base64encode(file("userdata1.sh"))
}
resource "aws_lb" "lb" {
  name = "loadbalancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.sg.id]
  subnets = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
}
resource "aws_lb_target_group" "tg" {
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
  health_check {
    path = "/"
    port="traffic-port"
  }


}
resource "aws_lb_target_group_attachment" "target-attachment-1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "target-attachment-2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2.id
  port             = 80
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
output "awslb" {
  value = aws_lb.lb.dns_name
}