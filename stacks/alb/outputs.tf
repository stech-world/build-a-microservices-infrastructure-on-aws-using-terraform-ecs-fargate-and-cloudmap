output "fgms_alb_sg_id" {
  description = "fgms private subnets ids"
  value       = aws_security_group.fgms_alb_sg.id
}

output "fgms_alb_id" {
  description = "fgms public alb"
  value       = aws_lb.fgms_alb.id
}

output "fgms_alb_dns_name" {
  description = "fgms public alb dns name"
  value       = aws_lb.fgms_alb.dns_name
}

output "fgms_alb_zone_id" {
  description = "fgms public alb zone id"
  value       = aws_lb.fgms_alb.zone_id
}

