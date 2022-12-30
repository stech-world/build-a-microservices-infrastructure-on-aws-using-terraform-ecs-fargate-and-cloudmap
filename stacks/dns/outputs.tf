output "fgms_dns_discovery_id" {
  description = "fgms service discovery id"
  value       = aws_service_discovery_private_dns_namespace.fgms_dns_discovery.id
}

output "fgms_private_dns_namespace" {
  description = "fgms service discovery id"
  value       = var.fgms_private_dns_namespace
}
