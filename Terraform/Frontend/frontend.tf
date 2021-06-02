resource "aws_security_group" "external-lb-sg" {
  name   = "external-lb-sg"
  vpc_id = "${var.Vpc}"
}

resource "aws_security_group_rule" "inbound-http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.external-lb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound-all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.external-lb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "frontend-sg" {
  name   = "frontend-sg"
  vpc_id = "${var.Vpc}"
}

resource "aws_security_group_rule" "frontend-inbound-http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frontend-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-inbound-ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frontend-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-inbound-mysql" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.frontend-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend-outbound-all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.frontend-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "frontend-ELB" {
  name               = "frontend-ELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external-lb-sg.id]
  subnets            = ["${var.Subnet1}","${var.Subnet2}"]
  tags = {
    Name = "frontend-ELB"
  }
}

resource "aws_lb_target_group" "external-TG" {
  name     = "external-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.Vpc}"
}

resource "aws_lb_listener" "external-listner" {
  load_balancer_arn = aws_lb.frontend-ELB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-TG.arn
  }
}

resource "aws_launch_configuration" "frontend-launch-config" {
  name_prefix   = "terraform-lc-example-"
  image_id      = "ami-01eef4604b9124f74"
  instance_type = "t2.micro"
  key_name = "kunal_123"
  security_groups = [aws_security_group.frontend-sg.id]
  user_data = "${file("frontend_script.sh")}"
}

resource "aws_autoscaling_group" "frontend-asg" {
  name                      = "frontend-asg"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  desired_capacity          = 1
  target_group_arns         = [aws_lb_target_group.external-TG.arn]
  launch_configuration      = aws_launch_configuration.frontend-launch-config.name
  vpc_zone_identifier       = ["${var.Subnet1}"]
}

resource "aws_autoscaling_policy" "frontend-asg-policy" {
  name = "frontend-asg-policy"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
  autoscaling_group_name = aws_autoscaling_group.frontend-asg.name
}