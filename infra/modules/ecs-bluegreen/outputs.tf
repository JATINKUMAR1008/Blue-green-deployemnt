
output "alb_dns_name" { value = aws_lb.this.dns_name }
output "listener_arn" { value = aws_lb_listener.http.arn }
output "tg_blue_arn"  { value = aws_lb_target_group.blue.arn }
output "tg_green_arn" { value = aws_lb_target_group.green.arn }
output "cluster_name" { value = aws_ecs_cluster.this.name }
output "service_name" { value = aws_ecs_service.app.name }
output "task_family"  { value = aws_ecs_task_definition.app.family }
output "cd_app"       { value = aws_codedeploy_app.ecs.name }
output "cd_group"     { value = aws_codedeploy_deployment_group.ecs.deployment_group_name }