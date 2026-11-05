# Load balancer: only the allowed IPs can reach port 80.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP to the load balancer from approved IPs"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(local.alb_allowed_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from approved IP"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Tasks: only the load balancer can reach the container port.
resource "aws_security_group" "task" {
  name        = "${var.project_name}-task-sg"
  description = "Allow traffic to the container only from the load balancer"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "task_from_alb" {
  security_group_id            = aws_security_group.task.id
  description                  = "App port from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# Tasks need outbound access to pull the image from ECR and send logs.
resource "aws_vpc_security_group_egress_rule" "task_all" {
  security_group_id = aws_security_group.task.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
