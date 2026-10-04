# Azure web platform

[![Source validation](https://github.com/Pmen225/azure-production-web-platform/actions/workflows/terraform.yml/badge.svg?branch=main)](https://github.com/Pmen225/azure-production-web-platform/actions/workflows/terraform.yml)

Terraform configuration for an Azure App Service platform with managed identity, Key Vault RBAC, Blob Storage and monitoring resources. A small Express application provides HTTP endpoints and automated route tests. The default configuration uses UK South, a Linux B1 plan and Node.js 24 LTS.

## Architecture

The App Service has a public HTTPS endpoint and outbound VNet integration through a delegated subnet. Its system assigned identity receives the Key Vault Secrets User role at the vault scope. Application settings contain the vault URI, Storage account name and Application Insights connection string.

```text
Public HTTPS endpoint
  -> Linux App Service
       -> delegated subnet for outbound VNet integration
       -> managed identity with Key Vault RBAC assignment
       -> configuration for Storage and Application Insights

Application Insights -> Log Analytics workspace
Sample application -> / and /health
```

Terraform defines the Azure resources separately from the application package. Application deployment, Azure data access and telemetry instrumentation are outside the implemented application scope.

## Implemented controls

- HTTPS and TLS 1.2 for App Service, with FTP and basic publishing authentication disabled
- Key Vault RBAC, purge protection and seven day soft delete retention
- Storage with HTTPS and TLS 1.2, shared key access disabled and anonymous Blob access disabled
- An empty uploads container with private container access
- Application Insights backed by a Log Analytics workspace with 30 day retention
- HTTP route tests and mocked Terraform tests for security settings, subnet delegation and resource name validation
- Committed Terraform provider and npm dependency lock files

## Validation

The workflow runs Terraform formatting, locked provider initialisation, schema validation, mocked configuration tests and Node.js HTTP tests without Azure credentials. The badge reports the latest workflow status on `main`.

The application currently returns HTTP responses only: it does not read vault secrets, use Blob Storage or emit Application Insights telemetry. `/health` reports process liveness and has no downstream dependency checks.

## Design and operations

App Service, Key Vault and Storage have public network endpoints. Storage container privacy restricts anonymous data access; it does not create a private endpoint. VNet integration applies to outbound App Service traffic, with no private inbound endpoint or firewall enforcement defined.

The configuration has no deployment slots or availability zone guarantee. Terraform uses local state, and CI has no Azure deployment identity or apply job. Shared deployment would require secured remote state, locking and deployment controls. Resource provisioning also depends on subscription permissions, resource provider registration and permission to create the Key Vault role assignment.

B1 compute, Storage usage and log ingestion can incur charges. Stopping the application does not remove its App Service plan cost. State and saved plans can contain sensitive values and are excluded from version control. Key Vault purge protection persists after deletion for the retention period; the provider does not attempt to purge the vault during destruction.

## Source layout

- [`infra/`](infra/): Terraform resources, inputs, outputs and mocked configuration tests
- [`app/`](app/): Express application, dependency lock and HTTP tests
- [Validation workflow](.github/workflows/terraform.yml): automated source checks
