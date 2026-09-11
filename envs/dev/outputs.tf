output "alb_dns_name" {
  description = "Nom DNS public du Load Balancer"
  value       = aws_lb.main.dns_name
}
