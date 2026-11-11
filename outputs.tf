# What Hyper Backup's destination form needs. Read locally with:
#   tofu output synology_server
#   tofu output synology_username
#   tofu output -raw synology_password

output "storage_box_server" {
  description = "FQDN of the Storage Box (main account)."
  value       = hcloud_storage_box.nas_backup.server
}

output "storage_box_username" {
  description = "Main account username. Its password stays in state; use the subaccount for backups."
  value       = hcloud_storage_box.nas_backup.username
}

output "synology_server" {
  description = "FQDN for the Hyper Backup subaccount (rsync over SSH, port 23)."
  value       = hcloud_storage_box_subaccount.synology.server
}

output "synology_username" {
  description = "Username of the Hyper Backup subaccount."
  value       = hcloud_storage_box_subaccount.synology.username
}

output "synology_password" {
  description = "Password of the Hyper Backup subaccount."
  value       = random_password.synology.result
  sensitive   = true
}
