resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "Node.JS"
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app-integration"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]

  delegation {
    name = "appsvc"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                                           = "app-${var.project}-${random_string.suffix.result}"
  resource_group_name                            = azurerm_resource_group.main.name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.main.id
  https_only                                     = true
  public_network_access_enabled                  = true
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  virtual_network_subnet_id                      = azurerm_subnet.app.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on               = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    ftps_state              = "Disabled"
    app_command_line        = "npm start"
    application_stack {
      node_version = "24-lts"
    }
  }

  # These settings expose configuration only. The sample app is not instrumented
  # and does not call Key Vault or Storage.
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.main.connection_string
    KEY_VAULT_URI                         = azurerm_key_vault.main.vault_uri
    STORAGE_ACCOUNT                       = azurerm_storage_account.main.name
    SCM_DO_BUILD_DURING_DEPLOYMENT        = "true"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                          = "kv-${random_string.suffix.result}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "azurerm_storage_account" "main" {
  name                            = "st${random_string.suffix.result}web"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access           = "Enabled"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
