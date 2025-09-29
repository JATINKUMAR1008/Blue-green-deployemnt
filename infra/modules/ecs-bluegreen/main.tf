resource "aws_cloudwatch_log_group" "app" { 
  name = "/ecs/${var.name}" 
  retention_in_days = 14 
  }

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB access"
  vpc_id      = var.vpc_id
  ingress { 
    from_port = 80  
    to_port = 80  
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  egress  { 
    from_port = 0   
    to_port = 0   
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
    }
}

resource "aws_security_group" "svc" {
  name        = "${var.name}-svc-sg"
  description = "Fargate service"
  vpc_id      = var.vpc_id
  ingress { 
    from_port = var.container_port 
    to_port = var.container_port 
    protocol = "tcp" 
    security_groups = [aws_security_group.alb.id] 
    }
  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.name}-blue"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { 
    path = var.health_check_path 
    interval = 15 
    matcher = "200" 
    healthy_threshold = 2 
    unhealthy_threshold = 2 
    }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.name}-green"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check { 
    path = var.health_check_path 
    interval = 15 
    matcher = "200" 
    healthy_threshold = 2 
    unhealthy_threshold = 2 
    }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action { 
    type = "forward" 
    target_group_arn = aws_lb_target_group.blue.arn 
    }
}

resource "aws_ecs_cluster" "this" { name = "${var.name}-cluster" }

resource "aws_iam_role" "task_execution" {
  name = "${var.name}-task-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.name}-task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name}-td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = jsonencode([
    {
      name      = "app",
      image     = "${var.image}:${var.image_tag}",
      essential = true,
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }],
      environment = [
        { name = "APP_VERSION", value = var.image_tag },
        { name = "APP_ENV",     value = var.environment },
        { name = "GIT_SHA",     value = var.image_tag }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "app"
        }
      },
      healthCheck = {
        command     = ["CMD-SHELL", "curl -fsS http://localhost:${var.container_port}${var.health_check_path} || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  deployment_controller { type = "CODE_DEPLOY" }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.svc.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_codedeploy_app" "ecs" { 
  name = "${var.name}-cd-app" 
  compute_platform = "ECS" 
  }

resource "aws_iam_role" "codedeploy" {
  name = "${var.name}-cd-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "codedeploy.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "cd_attach" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = data.aws_iam_policy.codedeploy_ecs.arn
}

data "aws_iam_policy" "codedeploy_ecs" {
  name = "AWSCodeDeployRoleForECS"
}

# Alarms for auto-rollback
resource "aws_cloudwatch_metric_alarm" "tg_blue_5xx" {
  alarm_name          = "${var.name}-blue-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    TargetGroup  = aws_lb_target_group.blue.arn_suffix
    LoadBalancer = aws_lb.this.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "tg_green_5xx" {
  alarm_name          = "${var.name}-green-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    TargetGroup  = aws_lb_target_group.green.arn_suffix
    LoadBalancer = aws_lb.this.arn_suffix
  }
}

resource "aws_codedeploy_deployment_group" "ecs" {
  app_name              = aws_codedeploy_app.ecs.name
  deployment_group_name = "${var.name}-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.app.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route { listener_arns = [aws_lb_listener.http.arn] }
      target_group { name = aws_lb_target_group.blue.name }
      target_group { name = aws_lb_target_group.green.name }
    }
  }

  alarm_configuration {
    alarms                    = [aws_cloudwatch_metric_alarm.tg_blue_5xx.alarm_name, aws_cloudwatch_metric_alarm.tg_green_5xx.alarm_name]
    enabled                   = true
    ignore_poll_alarm_failure = false
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE","DEPLOYMENT_STOP_ON_ALARM","DEPLOYMENT_STOP_ON_REQUEST"]
  }
}
