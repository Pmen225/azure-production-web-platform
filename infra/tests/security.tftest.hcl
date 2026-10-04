mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "random" {}

run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_linux_web_app.main.https_only && !azurerm_linux_web_app.main.ftp_publish_basic_authentication_enabled && !azurerm_linux_web_app.main.webdeploy_publish_basic_authentication_enabled
    error_message = "The web app must require HTTPS and disable basic publishing authentication."
  }

  assert {
    condition     = azurerm_linux_web_app.main.site_config[0].minimum_tls_version == "1.2" && azurerm_linux_web_app.main.site_config[0].ftps_state == "Disabled"
    error_message = "TLS 1.2 and disabled FTP are required."
  }

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled && azurerm_key_vault.main.purge_protection_enabled
    error_message = "Key Vault must use RBAC and purge protection."
  }

  assert {
    condition     = !azurerm_storage_account.main.allow_nested_items_to_be_public && !azurerm_storage_account.main.shared_access_key_enabled && azurerm_storage_container.uploads.container_access_type == "private"
    error_message = "Storage must reject anonymous blob access and shared keys."
  }

  assert {
    condition     = azurerm_subnet.app.delegation[0].service_delegation[0].name == "Microsoft.Web/serverFarms"
    error_message = "The integration subnet must be delegated to App Service."
  }
}

run "reject_invalid_project_name" {
  command = plan
  variables {
    project = "Invalid Project!"
  }
  expect_failures = [var.project]
}
