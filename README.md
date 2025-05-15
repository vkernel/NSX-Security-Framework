# NSX Security Framework

This Terraform project implements a robust security framework for VMware NSX environments. It creates and manages security policies, groups, services, and firewall rules based on a tenant-centric configuration model defined in YAML.

## Features

- Multi-tenancy with separate configuration per tenant
- Tag-based microsegmentation aligned with NSX best practices
- Emergency access policies for critical situations
- Environment isolation with controlled cross-environment communication
- Application-centric security policies with granular access controls
- Support for external services and communication
- Custom context profiles and services defined in inventory

## Architecture

The security framework follows the concept of hierarchical security with policies implemented at different levels:

1. **Emergency Policies**: Highest priority policies for critical access
2. **Environment Policies**: Control communication between environments (e.g., Production, Test)
3. **Application Policies**: Define allowed communications between application tiers and components

## Configuration Files

Each tenant requires two YAML configuration files:

### 1. Inventory Configuration (inventory.yaml)

Defines all resources (VMs, external services) organized by tenant, environment, and application tier, as well as custom service and context profile definitions.

```yaml
tenant_id:
  internal:
    env-{tenant}-{environment}:
      app-{tenant}-{environment}-{app}:
        app-{tenant}-{environment}-{app}-{component}:
          - vm-name-1
          - vm-name-2
  external:
    ext-{tenant}-{service}:
      - ip-address-1
  emergency:
    {tenant}-emergency:
      - vm-name-1
  custom_context_profiles:
    cp-{tenant}-custom-profile-name:
      app_id: 
        - "ACTIVDIR"   
        - "AMQP"   
      domain:
        - "*.microsoft.com"      
        - "*.office365.com"
  custom_services:  
    svc-{tenant}-custom-service-name:
      ports:
        - 8443
      protocol: tcp
```

### 2. Authorized Flows Configuration (authorized-flows.yaml)

Defines the allowed and blocked communication patterns between resources, using references to custom services and context profiles.

```yaml
tenant_id:
  emergency_policy:
    - name: Allow emergency rule on VMs with this tag
      source: emg-wld01
      destination: any
  environment_policy:
    allowed_communications:
      - name: Allow prod to test 
        source: env-{tenant}-prod
        destination: env-{tenant}-test
        scope_enabled: true 
    blocked_communications:
      - name: Block test from prod
        source: env-{tenant}-test
        destination: env-{tenant}-prod
        scope_enabled: true 
  application_policy:
    - name: Rule name
      source: 
        - app-{tenant}-{env}-{component1}
      destination: 
        - app-{tenant}-{env}-{component2}
      services:
        - HTTPS
      custom_services:
        - svc-{tenant}-custom-service-name
      context_profiles:
        - SSL
      custom_context_profiles:
        - cp-{tenant}-custom-profile-name
      scope_enabled: true
```

## Tagging Strategy

The framework implements a comprehensive tagging strategy:

1. **Tenant Tags**: All resources are tagged with their tenant identifier (`ten-{tenant-id}`)
2. **Environment Tags**: Resources are tagged with their environment (`env-{tenant}-{environment}`)
3. **Application Tags**: Resources are tagged with the application they belong to (`app-{tenant}-{env}-{app}`)
4. **Sub-Application Tags**: Resources are tagged with specific components within an application
5. **Emergency Tags**: Resources that need emergency access are tagged accordingly

### Tagging Hierarchy Diagram

```
┌───────────────────────┐
│       Tenant Tag      │
│    (ten-{tenant-id})  │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│    Environment Tag    │
│(env-{tenant}-{env})   │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│    Application Tag    │
│(app-{tenant}-{env}-   │
│        {app})         │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  Sub-Application Tag  │
│(app-{tenant}-{env}-   │
│  {app}-{component})   │
└───────────────────────┘
```

### VM Tagging Example

```
VM: web-server-01
├── Tenant Tag: ten-wld01
├── Environment Tag: env-wld01-prod
├── Application Tag: app-wld01-prod-3holapp
└── Sub-Application Tag: app-wld01-prod-3holapp-database
```

## Groups

Based on the tagging strategy, the following security groups are created:

- Tenant groups (all resources in a tenant)
- Environment groups (all resources in an environment)
- Application groups (all resources in an application)
- Sub-application groups (all resources in a component)
- External service groups (IP-based groups for external services)
- Emergency groups (VMs that need emergency access)

### Groups and Tags Relationship Diagram

```
                  ┌────────────────────┐
                  │   NSX-T Platform   │
                  └─────────┬──────────┘
                            │
                            ▼
          ┌─────────────────────────────────┐
          │        VM Inventory Tags        │
          └──────────────┬──────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────┐
│                  NSX-T Groups                   │
├─────────────────┬─────────────┬─────────────────┤
│  Tenant Groups  │Environment  │  Application    │
│ten-{tenant-id}  │   Groups    │    Groups       │
└─────────────────┴──────┬──────┴─────────────────┘
                         │               ▲
                         │               │
                         ▼               │
┌─────────────────────────────────────────────────┐
│               Security Policies                 │
├─────────────────┬─────────────┬─────────────────┤
│   Emergency     │Environment  │  Application    │
│    Policy       │   Policy    │    Policy       │
└─────────────────┴─────────────┴─────────────────┘
```

### Detailed Component Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                             YAML Configuration                          │
├────────────────────────────────┬────────────────────────────────────────┤
│         inventory.yaml         │       authorized-flows.yaml            │
│  (VM, service, and context     │  (Policy and rule definitions)         │
│   profile definitions)         │                                        │
└──────────────┬─────────────────┴─────────────────┬────────────────────┬─┘
               │                                   │                    │
               ▼                                   │                    │
┌──────────────────────────┐                       │                    │
│       Tags Module        │                       │                    │
│ (Creates NSX-T VM Tags)  │                       │                    │
└──────────────┬───────────┘                       │                    │
               │                                   │                    │
               ▼                                   │                    │
┌──────────────────────────┐                       │                    │
│      Groups Module       │◄──────────────────────┘                    │
│ (Creates NSX-T Groups    │                                            │
│  based on tags)          │                                            │
└──────────────┬───────────┘                                            │
               │                                                        │
               │           ┌──────────────────────────┐                 │
               │           │     Services Module      │◄────────────────┘
               │           │ (Creates predefined &    │
               │           │  custom service defs)    │
               │           │                          │
               │           └─────────────┬────────────┘
               │                         │
               │           ┌──────────────────────────┐
               │           │ Context Profiles Module  │◄────────────────┘
               │           │ (Creates predefined &    │
               │           │  custom context profiles)│
               │           └─────────────┬────────────┘
               │                         │
               ▼                         ▼
┌─────────────────────────────────────────────────────┐
│                Policies Module                      │
│ (Creates security policies and firewall rules       │
│  using groups, services and context profiles)       │
└─────────────────────────────────────────────────────┘
```

### Security Policy Hierarchy

```
┌───────────────────────────────────────────┐
│         NSX Security Framework            │
└───────────────────┬───────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Security Policy Hierarchy                     │
├─────────────────────┬─────────────────────┬──────────────────────┤
│ Emergency Policy    │ Environment Policy  │ Application Policy   │
│ (Highest Priority)  │ (Medium Priority)   │ (Lowest Priority)    │
├─────────────────────┼─────────────────────┼──────────────────────┤
│ - Emergency access  │ - Env isolation     │ - App tier comms     │
│ - Critical systems  │ - Dev/Test/Prod     │ - Service access     │
│                     │   boundaries        │ - Custom & predefined│
│                     │                     │   service definitions│
└─────────────────────┴─────────────────────┴──────────────────────┘
```

## Implementation

The framework is organized into Terraform modules:

- **tags**: Creates and manages NSX tags for all resources
- **groups**: Creates NSX security groups based on tags and IP addresses
- **services**: Defines NSX services for protocol and port combinations
- **context_profiles**: Creates and manages context profiles for deeper application inspection
- **policies**: Creates security policies and firewall rules

## Usage

1. At the project root, create a directory for each tenant under `tenants/{tenant-id}/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and update the NSX connection parameters (`nsx_manager_host`, `nsx_username`, `nsx_password`) and the `tenants` list.
3. In each tenant directory (`tenants/{tenant-id}`), create `inventory.yaml` and `authorized-flows.yaml` with your configurations.
4. Initialize and apply the Terraform configuration:

```bash
terraform init
terraform apply
```

## Multi-Tenancy

The framework supports multiple tenants with complete isolation between them. Each tenant has:

- Separate YAML configuration files
- Dedicated security groups and policies
- Isolated firewall rules

All tenants are deployed simultaneously, allowing for multiple tenant configurations to exist without conflicts. When you run terraform apply, it will create and maintain configurations for all tenants defined in the `tenants` variable.

To create a new tenant, simply:
1. Create a new directory under `tenants/{new-tenant-id}/`
2. Create inventory.yaml and authorized-flows.yaml files for the tenant
3. Add the new tenant ID to the `tenants` list in terraform.tfvars
4. Run `terraform apply` to deploy the new tenant along with existing tenants 

## Predefined NSX Services

NSX provides approximately 400+ predefined services that can be used directly in your security policies. The NSX-Security-Framework allows you to reference these predefined services by name in the `services` section of your authorized-flows.yaml file.

### Using Predefined Services

To use predefined services in your security policies, specify them in the `services` section:

```yaml
- name: Example rule with predefined services
  source: ext-wld01-jumphosts
  destination: app-wld01-prod-web
  services:
    - HTTPS
    - SSH
    - ICMPv4
```

### Custom Services

Custom services are defined in the inventory.yaml file and referenced in the authorized-flows.yaml file:

```yaml
# In inventory.yaml
custom_services:  
  svc-wld01-custom-service-name:
    ports:
      - 8443
    protocol: tcp

# In authorized-flows.yaml
- name: Example rule with custom services
  source: ext-wld01-jumphosts
  destination: app-wld01-prod-web
  custom_services:
    - svc-wld01-custom-service-name
```

## Context Profiles Usage

Context profiles in NSX allow for deeper application-level traffic inspection. The framework supports both predefined context profiles and custom context profiles.

### Using Predefined Context Profiles

To use a predefined context profile in a security rule:

```yaml
- name: Allow web traffic
  source: app-source-group
  destination: app-destination-group
  services:
    - HTTPS
  context_profiles:
    - HTTPS
    - SSL
  scope_enabled: true
```

### Custom Context Profiles

Custom context profiles are defined in the inventory.yaml file and referenced in the authorized-flows.yaml file:

```yaml
# In inventory.yaml
custom_context_profiles:
  cp-wld01-custom-context-profile-name:
    app_id: 
      - "ACTIVDIR"   
      - "AMQP"   
    domain:
      - "*.microsoft.com"      
      - "*.office365.com"

# In authorized-flows.yaml
- name: Example with custom context profiles
  source: app-source-group
  destination: app-destination-group
  custom_context_profiles:
    - cp-wld01-custom-context-profile-name
```

### Emergency Policy

The emergency policy contains rules that have the highest priority. These rules provide access during emergencies or for critical administrative purposes. Emergency groups can exist even without VMs assigned to them, providing flexibility to add VMs to them when needed without changing the infrastructure.

```yaml
tenant_id:
  emergency_policy:
    - name: Allow emergency rule on VMs with this tag
      source: emg-wld01
      destination: any
```

### Environment Policy

The environment policy contains rules that control communication between different environments. These rules can be used to isolate environments or allow controlled communication between them.

```yaml
tenant_id:
  environment_policy:
    allowed_communications:
      - name: Allow prod to test 
        source: env-{tenant}-prod
        destination: env-{tenant}-test
        scope_enabled: true 
    blocked_communications:
      - name: Block test from prod
        source: env-{tenant}-test
        destination: env-{tenant}-prod
        scope_enabled: true 
```

### Application Policy

The application policy contains rules that define allowed communications between application tiers and components.

```yaml
tenant_id:
  application_policy:
    - name: Rule name
      source: 
        - app-{tenant}-{env}-{component1}
      destination: 
        - app-{tenant}-{env}-{component2}
      services:
        - HTTPS
      custom_services:
        - svc-{tenant}-custom-service-name
      context_profiles:
        - SSL
      custom_context_profiles:
        - cp-{tenant}-custom-profile-name
      scope_enabled: true
```

## Module Structure and Outputs

The NSX Security Framework is organized into modular components, each responsible for specific NSX resources:

### Module Organization

1. **Tags Module** - Manages VM tags and tag-based grouping
2. **Groups Module** - Creates and manages NSX groups for applications, environments, and services
3. **Services Module** - Handles NSX service definitions used in security policies
4. **Context Profiles Module** - Manages application context profiles for deeper traffic inspection
5. **Policies Module** - Creates and configures security policies and rules

### Available Outputs

Each module exposes specific outputs that can be used for reference or in other modules:

#### Root-level Outputs

- `tenant_tags` - Tags created for each tenant
- `tenant_vms` - List of VMs in each tenant
- `tenant_group_ids` - ID of each tenant group
- `environment_groups` - Environment groups for each tenant
- `application_groups` - Application groups for each tenant
- `services` - Services created for each tenant
- `context_profiles` - Context profiles created for each tenant
- `policy_ids` - IDs of security policies created for each tenant
- `rule_counts` - Number of rules created for each policy type and tenant

#### Module-specific Outputs

- **Tags Module**
  - `tenant_tag` - The tag used for the tenant
  - `tenant_vms` - List of VMs in the tenant

- **Groups Module**
  - `tenant_group_id` - ID of the tenant group
  - `environment_groups` - IDs of environment groups
  - `application_groups` - IDs of application groups
  - `sub_application_groups` - IDs of sub-application groups
  - `external_service_groups` - IDs of external service groups
  - `emergency_groups` - IDs of emergency groups

- **Services Module**
  - `services` - Map of service names to service details

- **Context Profiles Module**
  - `predefined_context_profiles` - Map of predefined context profiles
  - `custom_context_profiles` - Map of custom context profiles
  - `all_context_profiles` - Combined map of all context profiles
  - `context_profiles` - Map of context profile names to NSX paths

- **Policies Module**
  - `emergency_policy_id` - ID of the emergency security policy
  - `environment_policy_id` - ID of the environment security policy
  - `application_policy_id` - ID of the application security policy
  - `policy_count` - Count of policies created for each tenant
  - `rule_count` - Count of rules created for each policy type

These outputs can be useful for debugging, reporting, or integrating with other systems.
