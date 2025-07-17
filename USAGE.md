# Usage Guide: NSX Security Framework Terraform Implementation

This guide provides step-by-step instructions for deploying the NSX Security Framework using Terraform.

## Prerequisites

- Terraform v1.0.0 or higher installed
- Access to an NSX Manager with valid credentials
- Virtual machines already deployed in NSX that match the names in your inventory YAML files
- NSX Projects created in NSX Manager if you plan to use project-based tenant isolation

## Deployment Steps

### 1. Prepare Your Environment

1. Clone or download this repository to your local machine.
2. Change to the project root directory (where Terraform configuration files are located).

### 2. Configure Tenant-Specific YAML Files

For each tenant you want to deploy:

1. Review and modify the tenant YAML files in the `tenants/<tenant_id>` directory:
   - `inventory.yaml`: Defines the tenant structure (environments, applications, VMs, custom services, and custom context profiles)
   - `authorized-flows.yaml`: Defines the allowed traffic flows with references to services and context profiles

2. Make sure the VM names in your YAML files match the display names of your actual VMs in NSX.

**Important**: Application policies in `authorized-flows.yaml` are created in the exact order they appear in the file. Plan your policy order carefully as it affects NSX processing sequence.

### 3. Configure NSX Connection Parameters

Edit the `terraform.tfvars` file with your NSX Manager details and tenants:

```hcl
# NSX Connection Parameters
nsx_manager_host = "your-nsx-manager.example.com"
nsx_username     = "your-username"
nsx_password     = "your-password"

# Tenants to deploy simultaneously
tenants = ["wld01", "wld02"]

# Optional: Custom file paths (defaults shown)
# inventory_file        = "./tenants/{tenant_id}/inventory.yaml"
# authorized_flows_file = "./tenants/{tenant_id}/authorized-flows.yaml"
```

### Optional: Custom File Paths

If your tenant configuration files are located in non-standard paths, you can specify custom paths:

```hcl
# Custom paths for all tenants
inventory_file        = "./config/inventory.yaml"
authorized_flows_file = "./config/flows.yaml"

# Or use environment-specific paths
inventory_file        = "./environments/${terraform.workspace}/inventory.yaml"
authorized_flows_file = "./environments/${terraform.workspace}/flows.yaml"
```

### 4. Initialize Terraform

Initialize the Terraform configuration to download the required providers:

```bash
terraform init
```

If you encounter any provider-related errors, make sure you're using the correct version of Terraform and that the NSX provider is properly specified.

### 5. Plan the Deployment

Generate and review a Terraform execution plan:

```bash
terraform plan -out=tfplan
```

This will show you what resources will be created without making any actual changes.

### 6. Apply the Configuration

Apply the Terraform configuration to create the NSX resources:

```bash
terraform apply tfplan
```

Or to plan and apply in one step:

```bash
terraform apply
```

### 7. Verify the Deployment

After Terraform completes, verify the deployment:

1. Log into your NSX Manager
2. Check that the following resources have been created:
   - VM tags for tenant, environment, application, and sub-application
   - Groups based on tags and IP addresses
   - Services for allowed protocols and ports (both predefined and custom)
   - Context profiles for application-level inspection (both predefined and custom)
   - Security policies with rules for environment and application traffic

## Using NSX Projects with Tenants

The NSX Security Framework supports NSX Projects for tenant isolation. This allows you to associate a tenant with an NSX Project, and all resources created for that tenant will be contained within the project context.

### Project Configuration Steps

1. **Create the Project in NSX Manager**:
   - Create the project through the NSX Manager UI or API before using it with the framework
   - Note the exact project name (case-sensitive)

2. **Configure the Tenant to Use the Project**:
   - Add the `project_name` field to the tenant's inventory.yaml file:
     ```yaml
     tenant_id:
       project_name: "Exact-Project-Name"  # Must match exactly (case-sensitive)
       internal:
         # Rest of tenant configuration...
     ```

3. **Considerations When Using Projects**:
   - Emergency policies are not supported in project context and will be skipped
   - Make sure your project has the necessary permissions configured
   - All tenant resources (groups, services, context profiles, policies) will be created in the project context
   - Resources in a project are isolated from resources in other projects or the default domain

### Troubleshooting Project Issues

If you encounter errors related to projects, check the following:
- Verify the project name in inventory.yaml matches exactly (case-sensitive) with the project in NSX Manager
- Ensure the project exists in NSX Manager before running Terraform
- Check that your NSX user account has sufficient permissions for the project

## Deploying for Multiple Tenants

The NSX Security Framework is designed to deploy configurations for multiple tenants simultaneously. All tenants specified in the `tenants` list in terraform.tfvars will be configured when you run terraform apply.

**Policy Order Preservation**: Each tenant's application policies are created in the order they appear in their respective `authorized-flows.yaml` files. This ensures consistent policy processing across all tenants.

To add a new tenant:
1. Create a directory for the tenant under `tenants/<tenant_id>/`
2. Add the necessary inventory.yaml and authorized-flows.yaml files
3. Add the tenant ID to the `tenants` list in terraform.tfvars
4. Run terraform apply

To remove a tenant, simply remove it from the `tenants` list in terraform.tfvars and run terraform apply again.

## Advanced: Working with Tenants

All tenants specified in the `tenants` list are managed together and configurations for all tenants are preserved when applying changes. This allows for:

1. Multiple tenant configurations to exist without conflicts
2. Adding new tenants without affecting existing ones
3. Managing all tenant configurations through a single terraform apply operation
4. **Maintaining policy order**: Each tenant's policies maintain their intended order independently

There is no need to use workspaces or separate state files for different tenants, as the framework now supports managing multiple tenants simultaneously in a single Terraform state.

## YAML File Structure

### Structure of inventory.yaml

The `inventory.yaml` file for each tenant defines the tenant structure, resources, custom services, and custom context profiles:

```yaml
tenant_id:  # e.g., wld01
  internal:  # Internal resources organized by environment and application
    env-{tenant}-{environment}:  # Environment (e.g., env-wld01-prod)
      app-{tenant}-{environment}-{app}:  # Application (e.g., app-wld01-prod-3holapp)
        app-{tenant}-{environment}-{app}-{component}:  # Sub-application (e.g., app-wld01-prod-3holapp-web)
          - vm-name-1  # VM names that belong to this component
          - vm-name-2
      app-{tenant}-{environment}-{app2}:  # Another application
        - vm-name-3  # VMs directly under the application (no sub-application)
  external:  # External services defined by IP addresses
    ext-{tenant}-{service}:  # External service (e.g., ext-wld01-dns)
      - 192.168.12.10  # IP addresses for this service
  consumer:  # NEW: Consumer groups - entities that consume services
    cons-{tenant}-{descriptive-name}:  # Consumer group (e.g., cons-wld01-web-clients)
      - ext-{tenant}-jumphosts  # External consumers
      - app-{tenant}-{env}-{component}  # Internal consumers
  provider:  # NEW: Provider groups - entities that provide services  
    prov-{tenant}-{descriptive-name}:  # Provider group (e.g., prov-wld01-web-servers)
      - app-{tenant}-{environment}-{component}  # Internal providers
  emergency:  # Emergency access groups
    emg-{tenant}:  # Emergency group (e.g., emg-wld01)
      - vm-name-4  # VMs that need emergency access
  custom_context_profiles:  # Custom context profiles for deeper traffic inspection
    cp-{tenant}-{profile-name}:  # Custom context profile (e.g., cp-wld01-custom-profile)
      app_id:  # Application IDs for this profile
        - "ACTIVDIR"
        - "AMQP"
      domain:  # Domain patterns for this profile
        - "*.microsoft.com"
        - "*.office365.com"
  custom_services:  # Custom services with protocol and ports
    svc-{tenant}-{service-name}:  # Custom service (e.g., svc-wld01-custom-service)
      ports:  # Ports for this service
        - 8443
      protocol: tcp  # Protocol (tcp, udp, or icmp)
```

### Structure of authorized-flows.yaml

The `authorized-flows.yaml` file for each tenant defines the allowed traffic flows between different groups. It consists of several sections:

### Policies Structure Diagram

```
authorized-flows.yaml
├── tenant_id: (e.g., wld01, wld02)
│   ├── emergency_policy:
│   │   └── [list of emergency rules]
│   ├── environment_policy:
│   │   ├── allowed_communications:
│   │   │   └── [list of allowed env rules]
│   │   └── blocked_communications:
│   │       └── [list of blocked env rules]
│   └── application_policy:
│       ├── pol-{tenant}-{name1}:  # FIRST - Sequence 3
│       │   └── [list of rules for application firewall 1]
│       ├── pol-{tenant}-{name2}:  # SECOND - Sequence 4
│       │   └── [list of rules for application firewall 2]
│       └── pol-{tenant}-{nameN}:  # LAST - Sequence N+2
│           └── [list of rules for application firewall N]
```

**Critical: Policy Order Matters!**

The order of application policies in the YAML file determines their NSX sequence numbers:
- First policy in YAML → NSX sequence number 3
- Second policy in YAML → NSX sequence number 4  
- And so on...

This order is preserved through sophisticated YAML parsing that extracts policy keys in their original order.

### Emergency Policy

The emergency policy contains rules that have the highest priority:

```yaml
emergency_policy:
  - name: Allow emergency rule on VMs with this tag
    source: emg-wld01
    destination: any
```

Emergency policies can reference emergency groups even when they have no VMs assigned. This provides flexibility to add VMs to these groups when needed without requiring changes to the policies or infrastructure. The framework automatically maintains empty emergency groups in the NSX-T inventory.

### Environment Policy

The environment policy controls communication between different environments (e.g., production, test, etc.):

```yaml
environment_policy:
  allowed_communications:
    - name: Allow prod environment to test environment
      source: env-wld01-prod
      destination: env-wld01-test
  blocked_communications:
    - name: Block test environment from prod environment
      source: env-wld01-test
      destination: env-wld01-prod
```

### Application Policy

The application policy defines allowed traffic between specific application components. Starting with the updated framework, application policies now support **multiple named application firewalls** within a single tenant, where each application firewall creates its own separate NSX security policy.

#### Application Policy Structure

The application policy is now structured as a map where each key represents an application firewall name, and each value contains a list of rules for that specific firewall:

```yaml
application_policy:
  # IMPORTANT: Order of these policies determines NSX sequence numbers!
  pol-wld01-consume-provider:  # First application firewall - Sequence 3
    - name: Allow remote access to 3holapp web servers
      source: 
        - cons-wld01-prod-3holapp-web  # Consumer group
      destination: 
        - prov-wld01-prod-3holapp-web  # Provider group
      services:  
        - HTTPS
      action: ALLOW
      applied_to:
        -  cons-wld01-prod-3holapp-web
        -  prov-wld01-prod-3holapp-web
    - name: Allow remote access to prod web servers
      source: 
        - cons-wld01-prod-web
      destination: 
        - prov-wld01-prod-web
      services:  
        - HTTPS
      action: ALLOW
      applied_to:
        -  cons-wld01-prod-web
        -  prov-wld01-prod-web
  
  pol-wld01-prod-3holapp-app:  # Second application firewall - Sequence 4
    - name: Allow web servers to application servers
      source: 
        - app-wld01-prod-3holapp-web
      destination: 
        - app-wld01-prod-3holapp-application
      custom_services:  
        - svc-wld01-custom-service-name1
      action: ALLOW
      applied_to:
        - app-wld01-prod-3holapp-web
        - app-wld01-prod-3holapp-application
    - name: Allow application servers to database servers
      source: 
        - app-wld01-prod-3holapp-application
      destination: 
        - app-wld01-prod-3holapp-database
      services:
        - MySQL
      action: ALLOW
      applied_to:
        - app-wld01-prod-3holapp-application
        - app-wld01-prod-3holapp-database

  pol-wld01-prod-app:  # Third application firewall - Sequence 5
    - name: Allow database access for production app
      source: 
        - app-wld01-prod-application
      destination: 
        - app-wld01-prod-database
      services:
        - MySQL
      action: ALLOW
      applied_to:
        - app-wld01-prod-application
        - app-wld01-prod-database
```

#### Benefits of Multiple Application Firewalls

1. **Separation of Concerns**: Different application components can have their own dedicated firewall policies
2. **Independent Management**: Each application firewall can be modified independently without affecting others
3. **Clearer Organization**: Rules are logically grouped by application or function
4. **Granular Control**: Each application firewall creates its own NSX security policy with its own sequence number
5. **Order Preservation**: Policies are created in exact YAML order for predictable NSX processing

#### NSX Security Policy Creation

When using multiple application firewalls, the framework creates:
- One NSX security policy per application firewall key
- Policy names follow the pattern: `{application-firewall-key}`
- Example: `pol-wld01-consume-provider` and `pol-wld01-prod-3holapp-app`
- Sequence numbers based on YAML order: 3, 4, 5, etc.

#### Consumer/Provider Model Usage

The consumer/provider model simplifies policy definition:

**Consumer Groups** (`cons-*`):
- Represent entities that need to access services
- Examples: Jump hosts, client applications, user groups
- Can include both internal and external resources

**Provider Groups** (`prov-*`):
- Represent entities that provide services
- Examples: Web servers, databases, APIs
- Typically contain internal application components

**Example Consumer/Provider Policy**:
```yaml
- name: Allow external access to web services
  source: 
    - cons-wld01-external-users  # Consumer: External users via jump hosts
  destination: 
    - prov-wld01-web-services    # Provider: Web servers
  services:
    - HTTPS
  applied_to:
    - cons-wld01-external-users
    - prov-wld01-web-services
```

## Troubleshooting

### Common Issues

1. **Provider Not Found Error**:
   - Make sure you've run `terraform init`
   - Check that the provider block in `main.tf` is correctly specified

2. **VM Tagging Failures**:
   - Verify that VM display names exactly match those in your YAML files
   - Check that your NSX service account has sufficient permissions

3. **Security Policy Not Working**:
   - Verify that groups are correctly created
   - Check that services are defined with correct protocols and ports
   - Ensure policies are correctly applied to the right scope

4. **YAML Parsing Errors**:
   - Ensure your YAML files are properly formatted with correct indentation
   - Validate YAML syntax using an online YAML validator

5. **Predefined Service Not Found**:
   - Verify the exact spelling of the service name as shown in NSX UI
   - Check if the service exists in your NSX version

6. **Custom Services Issues**:
   - See the [Custom Services Troubleshooting](#custom-services-troubleshooting) section for detailed guidance
   - Verify protocol numbers are within valid range (0-255)
   - For ICMPv6 issues, remove `icmp_code` parameter for problematic types
   - Remember ALG services are implemented as TCP services only
   
7. **Context Profile Issues**:
   - Ensure your App IDs and domain names are formatted correctly
   - Verify that context profile names match exactly as shown in NSX UI
   - Remember that when using multiple context profiles, services must be set to ANY

8. **Policy Order Issues**:
   - Verify that application policies appear in the correct order in your YAML file
   - Use `terraform output application_policy_keys_ordered` to check the detected order
   - Ensure proper YAML indentation (exactly 4 spaces for policy keys)

9. **Consumer/Provider Group Issues**:
   - Ensure consumer and provider groups are defined in inventory.yaml
   - Verify that group references in policies match the defined group names
   - Check that consumer/provider groups contain the expected resources

10. **VM Name Exact Matching Issues**:
   - **Problem**: Error message about VM names not matching exactly
   - **Cause**: VM names in YAML are partial matches or have slight differences
   - **Example**: YAML has `LMBB-AZT-PRTG` but NSX has `LMBB-AZT-PRTG04`
   - **Solution**: 
     1. Check NSX Manager → Inventory → Virtual Machines for exact names
     2. Update YAML files to use exact VM display names
     3. Ensure no extra spaces, different casing, or partial matches
   - **Prevention**: Always copy VM names directly from NSX Manager UI

### VM Name Validation Error Example

If you encounter a VM name validation error, it will look like this:

```
VM name validation failed! The following VMs in your YAML do not exactly match NSX VM display names:

  - YAML: 'LMBB-AZT-PRTG' -> NSX: 'LMBB-AZT-PRTG04'
  - YAML: 'web-server' -> NSX: 'Web-Server'

This often happens when:
1. VM names in YAML are partial matches (e.g., 'LMBB-AZT-PRTG' matches 'LMBB-AZT-PRTG04')
2. VM names have different casing
3. VM names have extra spaces or characters

Please update your YAML files to use exact VM display names as they appear in NSX Manager.
```

**How to fix**:
1. Open NSX Manager → Inventory → Virtual Machines  
2. Find the VMs mentioned in the error
3. Copy the exact display names from NSX Manager
4. Update your YAML files with the exact names
5. Re-run terraform apply

## Validating Policy Order

To verify that your policies are being created in the correct order:

### 1. Check Policy Key Order
```bash
terraform output application_policy_keys_ordered
```
This shows the order in which policies were extracted from your YAML file.

### 2. Check Policy IDs in Order
```bash
terraform output application_policy_ids_ordered
```
This shows the NSX policy IDs in the order they were created.

### 3. Validate Policy Sequence Numbers
```bash
terraform output policy_ids
```
Look at the policy details in NSX Manager to verify sequence numbers match your intended order.

### 4. Test Order Changes
To test that policy order changes work correctly:
1. Modify the order of application policies in your YAML file
2. Run `terraform plan` to see the expected changes
3. Run `terraform apply` to update the sequence numbers

**Note**: The framework uses `for_each` instead of `count`, so policy order changes result in sequence number updates rather than policy replacements.

## Working with Outputs

After deployment, Terraform provides various outputs that can help you understand and validate the created resources.

### Viewing Outputs

To view all outputs from a Terraform deployment:

```bash
terraform output
```

To view a specific output:

```bash
terraform output tenant_tags
```

### Useful Outputs for Inspection

1. **Rule Counts**: View how many rules were created for each policy type
   ```bash
   terraform output rule_counts
   ```

2. **Policy IDs**: Get the policy IDs for integration with other systems
   ```bash
   terraform output policy_ids
   ```

3. **Application Policy Order**: Validate that policies are in the correct order
   ```bash
   terraform output application_policy_keys_ordered
   terraform output application_policy_ids_ordered
   ```

4. **Groups**: View the created NSX groups and their paths
   ```bash
   terraform output application_groups
   terraform output consumer_groups
   terraform output provider_groups
   ```

5. **Context Profiles**: View the custom and predefined context profiles
   ```bash
   terraform output context_profiles
   ```

6. **Services**: View all services (predefined and custom)
   ```bash
   terraform output services
   ```

7. **VM Tag Details**: View detailed tag assignments for each VM
   ```bash
   terraform output vm_tag_details
   ```

8. **Tag Hierarchy**: View the hierarchical structure of tags
   ```bash
   terraform output tag_hierarchy
   ```

### Using Outputs for Integration

Outputs can be used for integration with other systems or for documentation:

1. **Export to JSON**: 
   ```bash
   terraform output -json > nsx_security_resources.json
   ```

2. **Usage in Scripts**:
   ```bash
   POLICY_ID=$(terraform output -raw 'policy_ids.wld01.application_policies.pol-wld01-consume-provider')
   # Use the policy ID in scripts or other tools
   ```

3. **Validate Policy Order**:
   ```bash
   # Get the order of policies as they appear in YAML
   terraform output -json application_policy_keys_ordered

   # Get the NSX policy IDs in the same order
   terraform output -json application_policy_ids_ordered
   ```

### Advanced Output Usage

For detailed analysis and reporting:

```bash
# Get complete tenant configuration summary
terraform output -json | jq '.tenant_group_details'

# Get application policy sequence information
terraform output -json | jq '.policy_ids[] | .application_policies'

# Get consumer/provider group mappings
terraform output -json | jq '.tenant_group_details[] | {consumer_groups, provider_groups}'

# Get rule count summary across all tenants
terraform output -json rule_counts
```

### Note about Empty Emergency Groups

Emergency policies can reference emergency groups even when they have no VMs assigned. This allows you to add VMs to these groups later without requiring changes to the policies or infrastructure.

You can specify traffic flows using several methods:

### Controlling Scope for Security Rules

Each rule can optionally specify which groups the rule should be applied to using the `applied_to` field:

```yaml
- name: Allow web servers to application servers
  source: 
    - app-wld01-prod-web
  destination: 
    - app-wld01-prod-application
  services:
    - HTTPS
  applied_to:  # Optional: List of groups to apply the rule to
    - app-wld01-prod-web
    - app-wld01-prod-application
```

When `applied_to` is:
- **Empty or not specified**: The rule applies with DFW (Distributed Firewall) scope, meaning it applies globally
- **List of groups**: The rule is applied only to the specified groups, providing more targeted control

The `applied_to` parameter can be applied to:
- Emergency policy rules
- Environment policy rules (both allowed and blocked communications)
- Application policy rules

Examples of different `applied_to` configurations:

```yaml
# Single group
applied_to:
  - app-wld01-prod-web

# Multiple groups
applied_to:
  - app-wld01-prod-web
  - app-wld01-prod-application
  - app-wld01-prod-database

# Tenant-wide scope
applied_to:
  - ten-wld01

# Empty (DFW scope) - rule applies globally
applied_to: []
# OR simply omit the applied_to field entirely
```

Use this feature when you need to create rules that should apply to specific groups or require more granular control over rule application.

## Finding and Using NSX Predefined Resources

### Predefined Services

NSX provides approximately 400+ predefined services that can be used in your security policies. To view and use these services:

1. **View in NSX UI**: 
   - Navigate to Networking → Services → Service Definitions
   - Filter for system-defined services

2. **Export to CSV**:
   - Use the export feature in the NSX UI to get a complete list

3. **Use in Configuration**:
   - Reference the exact service name in your authorized-flows.yaml file
   - Example: `services: ["HTTPS", "SSH"]`

### Custom Services

For services not available in NSX predefined services, see the [Custom Services Configuration](#custom-services-configuration) section for comprehensive guidance on creating TCP, UDP, ICMP, ICMPv6, IP protocol, IGMP, and ALG services.

### Predefined Context Profiles

NSX provides predefined context profiles that can be used for deeper traffic inspection:

1. **View in NSX UI**:
   - Navigate to Security → Profiles → Context Profiles
   - Filter for system-defined profiles

2. **Common Predefined Context Profiles**:
   - DNS
   - FTP
   - HTTP
   - HTTPS
   - SSL
   - SSH

3. **Use in Configuration**:
   - Reference the exact context profile name in your authorized-flows.yaml file
   - Example: `context_profiles: ["DNS", "SSL"]`

## Modifying Existing Deployments

To modify an existing deployment:

1. Update the relevant YAML files with your changes
2. Run Terraform again:
   ```bash
   terraform apply
   ```

**Note**: Thanks to the order preservation features, modifying application policies will result in updates rather than replacements, maintaining stable policy identities.

## Resource Cleanup

To remove all resources created by Terraform:

```bash
terraform destroy
```

**Caution**: This will remove all the NSX resources created by this Terraform configuration. Make sure this is what you want before confirming the destroy operation.

## Deployment Workflow

The following diagram illustrates the overall deployment process:

```
┌─────────────────────┐
│ Prepare YAML Files  │
│ for Each Tenant     │
│ (Order Matters!)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Configure           │
│ terraform.tfvars    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Run terraform init  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Run terraform apply │
└──────────┬──────────┘
           │
           ▼
┌───────────────────────────────────────────────────────────────┐
│                    Resources Created                          │
├──────────────┬──────────────┬───────────────┬────────────────┐
│ VM Tags      │ NSX Groups   │ Services      │ Context Profiles│
│ (Hierarchy)  │ (Inc. Cons/  │ (Predefined & │ (Predefined &  │
│              │  Providers)  │  Custom)      │  Custom)       │
└──────────────┴──────────────┴───────────────┴────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│         Security Policies Created       │
├──────────────┬──────────────┬───────────┤
│ Emergency    │ Environment  │ Application│
│ (Seq: 1)     │ (Seq: 2)     │ (Seq: 3+)  │
│              │              │ (YAML Order│
│              │              │ Preserved) │
└──────────────┴──────────────┴───────────┘ 
```

## Custom Services Configuration

### Overview

The NSX Security Framework supports creating custom services for all major service types available in NSX Manager. This includes TCP/UDP ports, ICMP types, IP protocols, IGMP, ICMPv6, and ALG (Application Layer Gateway) services.

### Supported Service Types

#### 1. TCP/UDP Services
Traditional layer 4 services with port specifications.

**Configuration:**
```yaml
custom_services:
  svc-web-alt:
    protocol: tcp
    ports: [8080, 8443]
  
  svc-custom-udp:
    protocol: udp
    ports: [9999, 10000, 10001]
```

#### 2. ICMPv4 Services
Internet Control Message Protocol version 4 services.

**Configuration:**
```yaml
custom_services:
  svc-ping:
    protocol: icmp
    icmp_type: 8  # Echo Request
    icmp_code: 0  # Optional
  
  svc-dest-unreachable:
    protocol: icmp
    icmp_type: 3  # Destination Unreachable
```

**Common ICMP Types:**
- Echo Request: 8
- Echo Reply: 0
- Destination Unreachable: 3
- Time Exceeded: 11
- Redirect: 5

**Complete Reference:** See [PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md) for all ICMP types.

#### 3. ICMPv6 Services
Internet Control Message Protocol version 6 services.

**Configuration:**
```yaml
custom_services:
  svc-ipv6-ping:
    protocol: icmpv6
    icmp_type: 128  # Echo Request
  
  svc-neighbor-discovery:
    protocol: icmpv6
    icmp_type: 135  # Neighbor Solicitation
```

**Important Notes for ICMPv6:**
- Some ICMPv6 types have strict validation in NSX
- Avoid using `icmp_code` for types like Echo Request (128), Neighbor Solicitation (135), etc.
- Test with your NSX version for compatibility

**Common ICMPv6 Types:**
- Echo Request: 128
- Echo Reply: 129
- Neighbor Solicitation: 135
- Neighbor Advertisement: 136
- Router Advertisement: 134

**Complete Reference:** See [PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md) for all ICMPv6 types.

#### 4. IP Protocol Services
Services based on IP protocol numbers (Layer 3).

**Configuration:**
```yaml
custom_services:
  svc-gre:
    protocol: ip
    protocol_number: 47  # GRE protocol
  
  svc-esp:
    protocol: ip
    protocol_number: 50  # ESP
```

**Common IP Protocols:**
- ICMP: 1
- IGMP: 2
- TCP: 6
- UDP: 17
- GRE: 47
- ESP: 50
- AH: 51
- OSPF: 89

**Complete Reference:** See [PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md) for all IP protocol numbers.

#### 5. IGMP Services
Internet Group Management Protocol services.

**Configuration:**
```yaml
custom_services:
  svc-multicast:
    protocol: igmp
```

#### 6. ALG Services
Application Layer Gateway services.

**⚠️ IMPORTANT LIMITATION:**
The NSX Terraform provider does not support native ALG service entries. ALG services are implemented as TCP services with the specified destination port. This provides basic port-based filtering but lacks full ALG protocol inspection capabilities.

**Configuration:**
```yaml
custom_services:
  svc-ftp-control:
    protocol: alg
    destination_port: 21
  
  svc-oracle-tns:
    protocol: alg
    destination_port: 1521
```

**What Actually Gets Created:**
- The service will be created as a TCP service on the specified port
- Display name will be prefixed with "alg-tcp-" to indicate the limitation
- No protocol-specific ALG functionality will be available

**For Full ALG Functionality:**
- Configure ALG services directly in NSX Manager UI
- Use predefined NSX services that include ALG support where available
- Consider using multiple custom services (TCP/UDP) to cover ALG application requirements

### Custom Services Configuration Examples

#### Complete Example (wld01/inventory.yaml)
```yaml
tenant_info:
  name: "wld01"
  description: "Workload Domain 01"

groups:
  # ... groups configuration

custom_services:
  # TCP Services
  svc-wld01-web:
    protocol: tcp
    ports: [80, 443]
  
  svc-wld01-database:
    protocol: tcp
    ports: [3306, 5432]
  
  # UDP Services  
  svc-wld01-dns:
    protocol: udp
    ports: [53]
  
  # ICMP Services
  svc-wld01-ping:
    protocol: icmp
    icmp_type: 8
  
  # ICMPv6 Services
  svc-wld01-ipv6-ping:
    protocol: icmpv6
    icmp_type: 128
  
  # IP Protocol Services
  svc-wld01-gre:
    protocol: ip
    protocol_number: 47
  
  # IGMP Services
  svc-wld01-multicast:
    protocol: igmp
  
  # ALG Services (implemented as TCP)
  svc-wld01-ftp:
    protocol: alg
    destination_port: 21
```

#### Value Formats

The framework accepts numeric values for protocol numbers and ICMP types. Values are passed directly to the NSX Terraform provider for validation.

**Protocol Numbers:** Use numeric values: `protocol_number: 47`

**ICMP Types:** Use numeric values: `icmp_type: 8`

**Note:** Values are passed directly to the NSX Terraform provider, which handles the translation and validation. This provides flexibility and ensures compatibility with future NSX versions.

#### Protocol and Type References

For complete lists of all protocol numbers and ICMP types, see:
- **[PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md)** - Comprehensive reference for all IP protocol numbers, ICMP types, and ICMPv6 types

#### Integration with Application Policies

Custom services can be referenced in application policies using the `custom_services` field:

```yaml
application_policy:
  web-tier-policy:
    - name: "allow-web-traffic"
      source_groups: ["web-servers"]
      destination_groups: ["db-servers"]
      custom_services: ["svc-wld01-database"]
      action: "ALLOW"
```

### Custom Services Best Practices

#### 1. Naming Conventions
- Use descriptive names with tenant prefixes
- Follow consistent patterns: `svc-{tenant}-{purpose}`
- Include protocol type for clarity

#### 2. Service Organization
- Group related services together in YAML
- Use comments to document complex configurations
- Consider service reusability across policies

#### 3. Protocol Selection
- Use TCP/UDP for standard application services
- Use ICMP for diagnostic and control protocols
- Use IP protocol services for VPN and tunneling
- Use IGMP for multicast applications

#### 4. Port Management
- Document non-standard ports in comments
- Consider port ranges for applications that use multiple ports
- Validate port assignments with application teams

#### 5. ICMPv6 Considerations
- Test ICMPv6 services in your environment first
- Be aware of NSX version-specific limitations
- Avoid unnecessary `icmp_code` specifications

#### 6. ALG Service Considerations
- Understand that ALG services are implemented as TCP services
- For full ALG functionality, use NSX Manager UI
- Consider creating multiple TCP/UDP services for complex ALG applications
- Document the limitation in your service configurations

### Custom Services Troubleshooting

#### Common Issues

1. **ICMPv6 Type/Code Validation Errors**
   ```
   Error: Invalid ICMP type, code combination
   ```
   - Remove `icmp_code` parameter for problematic types
   - Check NSX documentation for supported combinations

2. **Protocol Number Issues**
   ```
   Error: Invalid protocol number
   ```
   - Verify protocol numbers are within valid range (0-255)
   - Check if the protocol is supported by NSX
   - Refer to [PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md) for valid protocol numbers

3. **Service Not Created**
   - Verify YAML syntax is correct
   - Check that all required fields are provided
   - Ensure service name is unique

4. **ALG Services Not Working as Expected**
   - Remember ALG services are implemented as TCP services
   - Check if full ALG functionality is required
   - Consider configuring ALG services in NSX Manager UI for full functionality

### Custom Services Advanced Configuration

#### Multi-Port Services
```yaml
svc-web-cluster:
  protocol: tcp
  ports: [80, 443, 8080, 8443]
```

#### Multiple ICMP Types
Create separate services for different ICMP types:
```yaml
svc-icmp-echo:
  protocol: icmp
  icmp_type: 8

svc-icmp-unreachable:
  protocol: icmp
  icmp_type: 3
```

#### Complex ALG Applications
For applications requiring ALG functionality:
```yaml
# ALG service (implemented as TCP)
svc-ftp-control:
  protocol: alg
  destination_port: 21

# Additional TCP service for data channel
svc-ftp-data:
  protocol: tcp
  ports: [20]

# Passive FTP range (if needed)
svc-ftp-passive:
  protocol: tcp
  ports: [10000, 10001, 10002, 10003, 10004]
```

### Custom Services Quick Reference

#### Common Values

**IP Protocols:**
- ICMP: 1, IGMP: 2, TCP: 6, UDP: 17
- GRE: 47, ESP: 50, AH: 51, OSPF: 89

**ICMP Types (IPv4):**
- Echo Request: 8, Echo Reply: 0
- Dest Unreachable: 3, Time Exceeded: 11

**ICMPv6 Types:**
- Echo Request: 128, Echo Reply: 129
- Neighbor Solicitation: 135, Router Advertisement: 134

📖 **[PROTOCOL-REFERENCE.md](PROTOCOL-REFERENCE.md)** - Complete protocol numbers and ICMP types reference

#### Important Limitations

**ALG Services:**
- **No native ALG support** in Terraform provider
- ALG services created as **TCP services only**
- For full ALG functionality: **use NSX Manager UI**
- Service name prefixed with "alg-tcp-"

## VM Name Exact Matching Issues

### Problem Description
When VMs have similar names, the NSX Terraform provider may find multiple matches, causing deployment failures.

**Common Error**:
```
Error: Found 3 Virtual Machines with name prefix: LMBB-AZT-PRTG

  with module.tags.data.nsxt_policy_vm.vms["LMBB-AZT-PRTG"],
  on modules/tags/main.tf line 135, in data "nsxt_policy_vm" "vms":
 135: data "nsxt_policy_vm" "vms" {
```

### Root Cause
This happens when:
1. **Partial Names**: Your YAML contains `LMBB-AZT-PRTG` 
2. **Multiple Matches**: NSX has VMs like `LMBB-AZT-PRTG04`, `LMBB-AZT-PRTG06`, etc.
3. **Provider Behavior**: NSX provider does prefix matching and finds multiple VMs

### Solution Steps

#### Step 1: Identify Available VMs
1. Open **NSX Manager** → **Inventory** → **Virtual Machines**
2. Search for your VM name (e.g., "LMBB-AZT-PRTG")
3. Note all VMs that appear in the search results

Example results:
- `LMBB-AZT-PRTG04` 
- `LMBB-AZT-PRTG06`
- `LMBB-AZT-PRTG-BACKUP`

#### Step 2: Choose the Correct VM
Determine which VM you actually want to configure based on:
- VM purpose and function
- Network location
- Resource specifications
- Naming conventions in your environment

#### Step 3: Update YAML Files
Replace the ambiguous name with the exact VM name:

```yaml
# ❌ Before (causes error)
internal:
  env-wld09-prod:
    app-wld09-prod-monitoring:
      - LMBB-AZT-PRTG  # Matches multiple VMs

# ✅ After (works correctly)  
internal:
  env-wld09-prod:
    app-wld09-prod-monitoring:
      - LMBB-AZT-PRTG04  # Exact match
```

#### Step 4: Verify the Fix
```bash
# Validate configuration
terraform validate

# Check planned changes
terraform plan -target=module.tags
```

### Prevention Best Practices

1. **Always Use Full Names**: Use complete VM display names as they appear in NSX Manager
2. **Copy from NSX Manager**: Copy-paste VM names directly to avoid typos
3. **Verify Before Committing**: Double-check VM names in NSX Manager before updating YAML
4. **Document VM Mappings**: Keep a reference of which VMs serve which purposes
5. **Use Consistent Naming**: Work with your VM team to establish clear naming conventions

### Troubleshooting Multiple Environments

If you have similar issues across environments:

```yaml
# Example: Multiple environments with similar VM naming patterns
internal:
  env-wld09-dev:
    app-wld09-dev-monitoring:
      - LMBB-AZT-PRTG-DEV    # Development VM
  
  env-wld09-test:
    app-wld09-test-monitoring:
      - LMBB-AZT-PRTG-TEST   # Test VM
  
  env-wld09-prod:
    app-wld09-prod-monitoring:
      - LMBB-AZT-PRTG04      # Production VM (numbered)
```

### Quick Reference: Error to Solution

| Error Pattern | Likely Cause | Solution |
|---------------|--------------|----------|
| `Found X Virtual Machines with name prefix: VM-NAME` | Multiple VMs start with the same prefix | Use the complete, exact VM name |
| `No Virtual Machine found with display name: VM-NAME` | VM doesn't exist or name is incorrect | Verify VM exists in NSX Manager and check spelling |
| `Error retrieving Virtual Machine ID` | VM exists but has access issues | Check NSX permissions and VM power state |