data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
  }
  
  resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = false
  
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "${var.project_name}-alb-sg"
  }
}


resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    self      = true
  }
  
  ingress {
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
    Name = "${var.project_name}-ec2-sg"
  }
}



resource "aws_ebs_volume" "frontend_data" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  size              = 20
  type              = "gp3"
  
  tags = {
    Name = "${var.project_name}-frontend-data-${count.index + 1}"
  }
}

resource "aws_ebs_volume" "backend_data" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  size              = 20
  type              = "gp3"
  
  tags = {
    Name = "${var.project_name}-backend-data-${count.index + 1}"
  }
}

resource "aws_instance" "frontend" {
  count                   = 2
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public[count.index].id
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  
  user_data = templatefile("${path.module}/user_data_frontend.sh", {
    git_repo_url = var.git_repo_url
  })
  
  tags = {
    Name = "${var.project_name}-frontend-${count.index + 1}"
    Type = "frontend"
  }
}

resource "aws_instance" "backend" {
  count                   = 2
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public[count.index].id
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  
  user_data = templatefile("${path.module}/user_data_backend.sh", {
    git_repo_url = var.git_repo_url
  })
  
  tags = {
    Name = "${var.project_name}-backend-${count.index + 1}"
    Type = "backend"
  }
}

resource "aws_volume_attachment" "frontend_ebs" {
  count       = 2
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.frontend_data[count.index].id
  instance_id = aws_instance.frontend[count.index].id
}

resource "aws_volume_attachment" "backend_ebs" {
  count       = 2
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.backend_data[count.index].id
  instance_id = aws_instance.backend[count.index].id
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id
  
  enable_deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-frontend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }
  
  tags = {
    Name = "${var.project_name}-frontend-tg"
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-backend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 3
  }
  
  tags = {
    Name = "${var.project_name}-backend-tg"
  }
}

resource "aws_lb_target_group_attachment" "frontend" {
  count            = length(aws_instance.frontend)
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.frontend[count.index].id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "backend" {
  count            = length(aws_instance.backend)
  target_group_arn = aws_lb_target_group.backend.arn
  target_id        = aws_instance.backend[count.index].id
  port             = 3000
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    
    forward {
      target_group {
        arn = aws_lb_target_group.frontend.arn
      }
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100
  
  action {
    type = "forward"
    
    forward {
      target_group {
        arn = aws_lb_target_group.backend.arn
      }
    }
  }
  
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}