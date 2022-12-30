output "fgms_vpc_id" {
  description = "fgms subnet private 1"
  value       = module.vpc.vpc_id
}

output "fgms_private_subnets_ids" {
  description = "fgms private subnets ids"
  value       = module.vpc.private_subnets
}

output "fgms_public_subnets_ids" {
  description = "fgms public subnets ids"
  value       = module.vpc.public_subnets
}

