# NSX Security Framework

This Terraform project implements a robust security framework for VMware NSX environments. It creates and manages security policies, groups, services, and firewall rules based on a tenant-centric configuration model defined in YAML.

## Features

- Multi-tenancy with separate configuration per tenant
- NSX Project support for tenant isolation
- Tag-based microsegmentation aligned with NSX best practices
- **Policy Order Preservation**: Application policies are created in the exact order specified in YAML files
- **Consumer/Provider Groups**: Support for consumer and provider relationship modeling
- Emergency access policies for critical situations
- Environment isolation with controlled cross-environment communication
- Application-centric security policies with granular access controls
- Support for external services and communication
- Custom context profiles and services defined in inventory
- **Stable Policy Identity**: Policy modifications result in updates rather than replacements

## Architecture

The security framework follows the concept of hierarchical security with policies implemented at different levels:

1. **Emergency Policies**: Highest priority policies for critical access (sequence: 1)
2. **Environment Policies**: Control communication between environments (sequence: 2)
3. **Application Policies**: Define allowed communications between application tiers and components (sequence: 3+)

### Policy Sequence Numbering

The framework implements intelligent sequence numbering to ensure policies are processed by NSX in the intended order:

- **Emergency Policy**: Sequence number 1 (highest priority)
- **Environment Policy**: Sequence number 2 
- **Application Policies**: Sequence numbers 3+ based on YAML order
  - First application policy in YAML: sequence 3
  - Second application policy in YAML: sequence 4
  - And so on...

This ensures that policies are processed by NSX in the exact order you define them in your YAML configuration.

## NSX Project Support

The framework now supports NSX Projects for tenant isolation. When a tenant is associated with an NSX Project, all resources for that tenant (groups, services, context profiles, and policies) are created within the project context, providing proper isolation.

To use a tenant with an NSX Project:

1. Add a `project_name` field to the tenant's inventory.yaml file
2. Ensure the project already exists in NSX Manager
3. Note that emergency policies are not supported in project context and will be skipped

Example configuration:

```yaml
tenant_id:
  project_name: "Project-Name"  # Existing NSX Project name
  internal:
    env-{tenant}-{environment}:
      app-{tenant}-{environment}-{app}:
        app-{tenant}-{environment}-{app}-{component}:
          - vm-name-1
          - vm-name-2
  external:
    ext-{tenant}-{service}:
      - ip-address-1
  consumer:  # Consumer groups - who consumes services
    cons-{tenant}-{environment}-{component}:
      - ext-{tenant}-jumphosts  # External consumers
      - app-{tenant}-{env}-{component}  # Internal consumers
  provider:  # Provider groups - who provides services
    prov-{tenant}-{environment}-{component}:
      - app-{tenant}-{environment}-{component}  # Internal providers
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

## Configuration Files

Each tenant requires two YAML configuration files:

### 1. Inventory Configuration (inventory.yaml)

Defines all resources (VMs, external services) organized by tenant, environment, and application tier, as well as custom service and context profile definitions.

```yaml
tenant_id:
  project_name: "Project-Name"  # Optional - NSX Project for tenant isolation
  internal:
    env-{tenant}-{environment}:
      app-{tenant}-{environment}-{app}:
        app-{tenant}-{environment}-{app}-{component}:
          - vm-name-1
          - vm-name-2
  external:
    ext-{tenant}-{service}:
      - ip-address-1
  consumer:  # Consumer groups - who consumes services
    cons-{tenant}-{environment}-{component}:
      - ext-{tenant}-jumphosts  # External consumers
      - app-{tenant}-{env}-{component}  # Internal consumers
  provider:  # Provider groups - who provides services
    prov-{tenant}-{environment}-{component}:
      - app-{tenant}-{environment}-{component}  # Internal providers
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

Defines the allowed and blocked communication patterns between resources. **Important**: Application policies are created in the exact order they appear in this file.

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
        applied_to: 
          - env-{tenant}-prod
          - env-{tenant}-test
    blocked_communications:
      - name: Block test from prod
        source: env-{tenant}-test
        destination: env-{tenant}-prod
        applied_to:
          - env-{tenant}-test
          - env-{tenant}-prod
  application_policy:
    # Named application firewalls - ORDER MATTERS!
    # These will be created as separate NSX policies in this exact order
    pol-{tenant}-consume-provider:  # First policy (sequence: 3)
      - name: Consumer to provider access
        source: 
          - cons-{tenant}-{component}
        destination: 
          - prov-{tenant}-{component}
        services:
          - HTTPS
        applied_to:
          - cons-{tenant}-{component}
          - prov-{tenant}-{component}
    pol-{tenant}-app-communication:  # Second policy (sequence: 4)
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
        applied_to:
          - app-{tenant}-{env}-{component1}
          - app-{tenant}-{env}-{component2}
```

## Consumer/Provider Model

The framework supports a consumer/provider relationship model that simplifies defining access patterns:

### Consumer Groups
- **Purpose**: Represent entities that consume services
- **Examples**: External jump hosts, client applications, users
- **Naming**: `cons-{tenant}-{descriptive-name}`

### Provider Groups  
- **Purpose**: Represent entities that provide services
- **Examples**: Web servers, databases, APIs
- **Naming**: `prov-{tenant}-{descriptive-name}`

### Benefits
- **Clear Intent**: Makes it obvious who consumes and who provides services
- **Simplified Rules**: Reduces complexity in policy definitions
- **Reusable Groups**: Same consumer/provider can be used across multiple policies

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
- **Consumer groups** (entities that consume services)
- **Provider groups** (entities that provide services)
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
- **policies**: Creates security policies and firewall rules with order preservation

### Advanced Features

#### YAML Order Preservation
The framework implements sophisticated YAML order preservation for application policies:

```hcl
# Extracts policy keys in original YAML order using regex
application_policy_keys_ordered = flatten([
  for match in regexall("(?m)^    (pol-[^:]+):", local.authorized_flows_text) : match
])

# Maps each policy to its original order index
application_policy_order_map = {
  for idx, key in local.application_policy_keys_ordered : key => idx
}
```

This ensures that policy sequence numbers reflect the exact order in your YAML files.

#### File Path Configuration
You can customize the paths to your tenant configuration files:

```hcl
# In terraform.tfvars or variables
inventory_file        = "./custom/path/inventory.yaml"
authorized_flows_file = "./custom/path/authorized-flows.yaml"

# Or use default paths
# tenants/{tenant_id}/inventory.yaml
# tenants/{tenant_id}/authorized-flows.yaml
```

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

The framework supports comprehensive custom service definitions for all NSX service types including TCP, UDP, ICMPv4, ICMPv6, IP protocol, IGMP, and ALG services. Custom services use **numeric values** for protocol numbers and ICMP types, providing direct compatibility with the NSX Terraform provider.

```yaml
# In inventory.yaml
custom_services:  
  # TCP/UDP Services
  svc-wld01-custom-service-name:
    ports:
      - 8443
    protocol: tcp
  
  # ICMP Services
  svc-wld01-ping-monitoring:
    protocol: icmp
    icmp_type: 8  # Echo Request
    icmp_code: 0
  
  # IP Protocol Services
  svc-wld01-gre-tunnel:
    protocol: ip
    protocol_number: 47  # GRE
  
  # ICMPv6 Services
  svc-wld01-ipv6-neighbor:
    protocol: icmpv6
    icmp_type: 135  # Neighbor Solicitation
  
  # ALG Services (implemented as TCP)
  svc-wld01-oracle-alg:
    protocol: alg
    destination_port: 1521

# In authorized-flows.yaml
- name: Example rule with custom services
  source: ext-wld01-jumphosts
  destination: app-wld01-prod-web
  custom_services:
    - svc-wld01-custom-service-name
```

**Key Features:**
- **Direct NSX Integration**: Values passed directly to NSX Terraform provider
- **No Hardcoded Mappings**: Clean, maintainable implementation
- **Complete Protocol Support**: All IP protocols and ICMP types supported
- **ALG Limitation**: ALG services implemented as TCP services (provider limitation)

**Documentation:**
- **[Custom Services Configuration](USAGE.md#custom-services-configuration)** - Complete configuration guide and examples in USAGE.md
- **[Protocol Reference](PROTOCOL-REFERENCE.md)** - Comprehensive list of all protocol numbers and ICMP types

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
  applied_to:
    - app-source-group
    - app-destination-group
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
  applied_to:
    - app-source-group
    - app-destination-group
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
        applied_to: 
          - env-{tenant}-prod
          - env-{tenant}-test
    blocked_communications:
      - name: Block test from prod
        source: env-{tenant}-test
        destination: env-{tenant}-prod
        applied_to:
          - env-{tenant}-test
          - env-{tenant}-prod
```

### Application Policy

The application policy defines allowed traffic between specific application components. Application policies use **named application firewalls** where each key represents a separate NSX security policy.

**Critical Feature: Order Preservation**

The framework preserves the exact order of application policies as they appear in the YAML file. This is achieved through:

1. **Direct YAML Parsing**: Reads the YAML file as text and extracts policy keys using regex
2. **Sequence Number Assignment**: Assigns sequence numbers based on YAML order (starting from 3)
3. **Stable Identity**: Uses `for_each` instead of `count` to prevent policy replacements

```yaml
application_policy:
  pol-wld01-consume-provider:    # First - gets sequence number 3
    - name: Consumer access rules
      # ... rules
  pol-wld01-prod-3holapp-app:    # Second - gets sequence number 4  
    - name: 3-tier app rules
      # ... rules
  pol-wld01-prod-app:            # Third - gets sequence number 5
    - name: Production app rules  
      # ... rules
```

**Key Benefits:**
- ✅ **No Policy Replacements**: Modifications are updates, not replacements
- ✅ **Preserves YAML Order**: NSX processes policies in intended sequence
- ✅ **Stable Identity**: Each policy maintains consistent identity
- ✅ **Predictable Processing**: Guaranteed processing order by NSX

## Module Structure and Outputs

The NSX Security Framework is organized into modular components, each responsible for specific NSX resources:

### Module Organization

1. **Tags Module** - Manages VM tags and tag-based grouping
2. **Groups Module** - Creates and manages NSX groups for applications, environments, and services
3. **Services Module** - Handles NSX service definitions used in security policies
4. **Context Profiles Module** - Manages application context profiles for deeper traffic inspection
5. **Policies Module** - Creates and configures security policies and rules with order preservation

### Available Outputs

Each module exposes specific outputs that can be used for reference or in other modules:

#### Root-level Outputs

- `tenant_tags` - Tags created for each tenant
- `tenant_vms` - List of VMs in each tenant
- `vm_tag_details` - Detailed mapping of tag assignments for each VM
- `tag_hierarchy` - Hierarchical structure showing tag relationships
- `emergency_vm_assignments` - Emergency group to VM mappings
- `tenant_group_ids` - ID of each tenant group
- `tenant_group_details` - Detailed tenant group configuration
- `environment_groups` - Environment groups for each tenant
- `environment_groups_details` - Detailed environment group configuration
- `application_groups` - Application groups for each tenant
- `application_groups_details` - Detailed application group configuration
- `sub_application_groups_details` - Sub-application group details
- `external_service_groups_details` - External service group details with IP addresses
- `emergency_groups_details` - Emergency group configuration details
- `services` - Services created for each tenant
- `context_profiles` - Context profiles created for each tenant
- `policy_ids` - IDs of security policies created for each tenant
- `rule_counts` - Number of rules created for each policy type and tenant

#### Module-specific Outputs

- **Tags Module**
  - `tenant_tag` - The tag used for the tenant
  - `tenant_vms` - List of VMs in the tenant
  - `vm_tag_assignments` - Detailed VM tag assignments
  - `tag_hierarchy_summary` - Summary of tag hierarchy
  - `emergency_vm_assignments` - Emergency group VM assignments

- **Groups Module**
  - `tenant_group_id` - ID of the tenant group
  - `tenant_group_details` - Detailed tenant group configuration
  - `environment_groups` - IDs of environment groups
  - `environment_groups_details` - Detailed environment group configuration
  - `application_groups` - IDs of application groups
  - `application_groups_details` - Detailed application group configuration
  - `sub_application_groups` - IDs of sub-application groups
  - `sub_application_groups_details` - Detailed sub-application group configuration
  - `external_service_groups` - IDs of external service groups
  - `external_service_groups_details` - External service group details with IP addresses
  - `emergency_groups` - IDs of emergency groups
  - `emergency_groups_details` - Emergency group configuration details
  - `consumer_groups` - IDs of consumer groups
  - `provider_groups` - IDs of provider groups

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
  - `application_policy_ids` - Map of application policy IDs by key
  - `application_policy_ids_ordered` - List of application policy IDs in YAML order
  - `application_policy_keys_ordered` - List of application policy keys in YAML order
  - `policy_count` - Count of policies created for each tenant
  - `rule_count` - Count of rules created for each policy type

These outputs can be useful for debugging, reporting, or integrating with other systems. The order-related outputs are particularly valuable for validating that policies are created in the intended sequence.

## VM Name Exact Matching

The framework requires **exact VM name matching** to prevent issues with similar VM names. This addresses common problems where partial name matches can cause confusion.

### The Problem
When you have VMs with similar names like:
- `LMBB-AZT-PRTG` (the VM you want)
- `LMBB-AZT-PRTG04` (a different VM)  
- `LMBB-AZT-PRTG06` (another different VM)

The NSX Terraform provider may match multiple VMs when you specify `LMBB-AZT-PRTG` in your YAML, causing this error:
```
Error: Found 3 Virtual Machines with name prefix: LMBB-AZT-PRTG
```

### The Solution
To resolve this issue:

1. **Identify the Exact VM Name**: Check NSX Manager → Inventory → Virtual Machines
2. **Search for Similar Names**: Use the search feature to find all VMs with similar names
3. **Choose the Correct VM**: Identify which VM is the one you actually want to configure
4. **Update YAML with Exact Name**: Use the complete, exact display name in your YAML files

### Example Fix

**Problem**: Your YAML has `LMBB-AZT-PRTG` but NSX has these VMs:
- `LMBB-AZT-PRTG04`
- `LMBB-AZT-PRTG06` 
- `LMBB-AZT-PRTG-BACKUP`

**Solution**: Update your YAML to use the exact name:
```yaml
# Before (causes error)
internal:
  env-wld09-prod:
    app-wld09-prod-monitoring:
      - LMBB-AZT-PRTG  # This matches multiple VMs

# After (works correctly)  
internal:
  env-wld09-prod:
    app-wld09-prod-monitoring:
      - LMBB-AZT-PRTG04  # Exact match
```

### Common Error Messages and Solutions

#### "Found X Virtual Machines with name prefix"
```
Error: Found 3 Virtual Machines with name prefix: LMBB-AZT-PRTG
```

**Cause**: Multiple VMs in NSX have names that start with your specified VM name.

**Solution**:
1. Open NSX Manager → Inventory → Virtual Machines
2. Search for your VM name (e.g., "LMBB-AZT-PRTG")
3. Review all matching VMs in the results
4. Choose the correct VM and copy its exact display name
5. Update your YAML file with the exact name

#### Best Practices for VM Names

1. **Use Complete Names**: Always use the full VM display name as it appears in NSX
2. **Verify in NSX Manager**: Double-check VM names in the NSX Manager UI before adding to YAML
3. **Be Case-Sensitive**: VM names are case-sensitive - match exactly
4. **No Wildcards**: Don't use partial names or wildcards
5. **Copy-Paste**: Copy VM names directly from NSX Manager to avoid typos

### Troubleshooting Steps

If you encounter VM name matching errors:

1. **Check the Error Message**: Note which VM names are causing issues
2. **Search NSX Manager**: 
   - Go to Inventory → Virtual Machines
   - Search for each problematic VM name
   - Note all VMs that appear in search results
3. **Identify the Correct VM**: Determine which VM you actually want to configure
4. **Update YAML Files**: Replace the problematic names with exact matches
5. **Test the Fix**: Run `terraform validate` to check for syntax errors
6. **Deploy**: Run `terraform plan` to verify the changes before applying

This validation ensures that your policies are applied to the correct VMs and prevents accidental misconfigurations caused by ambiguous VM names.
