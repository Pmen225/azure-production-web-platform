output "web_url" {
  description = "App Service URL; application code must be deployed separately."
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "web_app_name" {
  value = azurerm_linux_web_app.main.name
}
