# CloudFront's own IP ranges, maintained by AWS (so we never copy IPs by hand)
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ---------------------------------------------------------------------------
# Security group: only CloudFront can reach the ALB
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB: only CloudFront in, only backend pods out"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from CloudFront origin-facing IPs only"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "to_pods" {
  security_group_id = aws_security_group.alb.id
  description       = "Backend pods (targets and health checks)"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = var.target_port
  to_port           = var.target_port
}

# ---------------------------------------------------------------------------
# Load balancer
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  drop_invalid_header_fields = true
  enable_deletion_protection = false # we destroy the stack after every work session
}

# Terraform owns the target group. Kubernetes (TargetGroupBinding) registers the
# backend pod IPs in it, so it must be target_type = "ip".
resource "aws_lb_target_group" "backend" {
  name        = "${var.name}-backend"
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ---------------------------------------------------------------------------
# Listener: 403 unless the secret header from CloudFront is present
# ---------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "origin_verify" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [var.origin_verify_secret]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}