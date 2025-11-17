output "key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.this.key_name
}

output "key_pair_id" {
  description = "ID of the SSH key pair"
  value       = aws_key_pair.this.id
}

output "fingerprint" {
  description = "Fingerprint of the SSH key pair"
  value       = aws_key_pair.this.fingerprint
}
