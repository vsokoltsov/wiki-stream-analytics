variable "files" {
  type = map(string)
}

output "files" {
  value = var.files
}
