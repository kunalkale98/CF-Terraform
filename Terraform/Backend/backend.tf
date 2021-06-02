resource "aws_security_group" "internal-lb-sg" {
  name   = "internal-lb-sg"
  vpc_id = "${var.Vpc}"
}

resource "aws_security_group_rule" "inbound-http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.internal-lb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound-all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.internal-lb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "backend-sg" {
  name   = "backend-sg"
  vpc_id = "${var.Vpc}"
}

resource "aws_security_group_rule" "backend-inbound-http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.backend-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend-inbound-app" {
  from_port         = 8000
  protocol          = "tcp"
  security_group_id = "${aws_security_group.backend-sg.id}"
  to_port           = 8000
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend-inbound-ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.backend-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend-inbound-mysql" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.backend-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend-outbound-all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.backend-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "backend-ELB" {
  name               = "backend-ELB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal-lb-sg.id]
  subnets            = ["${var.Subnet1}","${var.Subnet2}"]
  tags = {
    Name = "backend-ELB"
  }
}

resource "aws_lb_target_group" "internal-TG" {
  name     = "internal-TG"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "${var.Vpc}"
}

resource "aws_lb_listener" "internal-listner" {
  load_balancer_arn = aws_lb.backend-ELB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal-TG.arn
  }
}

resource "aws_launch_configuration" "backend-launch-config" {
  name_prefix   = "terraform-lc-example-"
  image_id      = "ami-0b2ebc26bab5bc68d"
  instance_type = "t2.micro"
  key_name = "kunal_123"
  security_groups = [aws_security_group.backend-sg.id]
  user_data = "${file("backend_script.sh")}"
}

resource "aws_autoscaling_group" "backend-asg" {
  name                      = "backend-asg"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  desired_capacity          = 1
  target_group_arns         = [aws_lb_target_group.internal-TG.arn]
  launch_configuration      = aws_launch_configuration.backend-launch-config.name
  vpc_zone_identifier       = ["${var.Subnet1}"]
}

resource "aws_autoscaling_policy" "backend-asg-policy" {
  name = "backend-asg-policy"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
  autoscaling_group_name = aws_autoscaling_group.backend-asg.name
}