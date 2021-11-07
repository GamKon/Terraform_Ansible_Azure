output "VM-1-PubIP" {
  value = azurerm_public_ip.example_app_pubip.ip_address
}
output "admin-name" {
  value = azurerm_linux_virtual_machine.vm_1.admin_username
}