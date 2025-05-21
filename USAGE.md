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

### 3. Configure NSX Connection Parameters

Edit the `terraform.tfvars` file with your NSX Manager details and tenants:

```hcl
# NSX Connection Parameters
nsx_manager_host = "your-nsx-manager.example.com"
nsx_username     = "your-username"
nsx_password     = "your-password"

# Tenants to deploy simultaneously
tenants = ["wld01", "wld02"]
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
│       └── [list of application rules]
```

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

The application policy defines allowed traffic between specific application components. You can specify traffic flows using several methods:

#### Application Policy Methods Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             Application Policy Methods                          │
├────────────────────┬────────────────────┬───────────────────┬───────────────────┤
│     Method 1       │     Method 2       │     Method 3      │     Method 4      │
│ Predefined Services│  Custom Services   │Context Profiles   │  Combined Approach │
├────────────────────┼────────────────────┼───────────────────┼───────────────────┤
│ - services:        │ - custom_services: │ - context_profiles:│ - services:       │
│   - HTTPS          │   - svc-name       │   - SSL           │   - HTTPS         │
│   - SSH            │                    │ - custom_context_ │ - custom_services: │
│                    │                    │   profiles:       │   - svc-name      │
│                    │                    │   - cp-name       │ - context_profiles:│
│                    │                    │                   │   - SSL           │
└────────────────────┴────────────────────┴───────────────────┴───────────────────┘
```

#### Method 1: Using predefined NSX services

```yaml
- name: Allow HTTPS and SSH access to web servers
  source: ext-wld01-jumphosts
  destination: 
    - app-wld01-prod-web
  services:
    - HTTPS
    - SSH
    - ICMPv4
```

#### Method 2: Using custom services defined in inventory.yaml

```yaml
- name: Allow custom service access
  source: ext-wld01-jumphosts
  destination: 
    - app-wld01-prod-web
  custom_services:
    - svc-wld01-custom-service-name
```

#### Method 3: Using context profiles (predefined and custom)

```yaml
- name: Allow web traffic with context profiles
  source: ext-wld01-jumphosts
  destination:
    - app-wld01-prod-web
  context_profiles:
    - SSL
    - DNS
  custom_context_profiles:
    - cp-wld01-custom-context-profile
```

#### Method 4: Combined approach

You can combine multiple approaches in a single rule:

```yaml
- name: Combined rule with services and context profiles
  source: ext-wld01-jumphosts
  destination: 
    - app-wld01-prod-web
  services:
    - HTTPS
  custom_services:
    - svc-wld01-custom-service-name
  context_profiles:
    - SSL
  custom_context_profiles:
    - cp-wld01-custom-context-profile
```

### Controlling Scope for Security Rules

Each rule can optionally control whether the tenant scope is applied:

```yaml
- name: Allow web servers to application servers
  source: 
    - app-wld01-prod-web
  destination: 
    - app-wld01-prod-application
  services:
    - HTTPS
  scope_enabled: true  # Optional: Set to false to disable tenant scope (defaults to true)
```

When `scope_enabled` is set to:
- `true` (default): The rule is applied only to resources with the tenant tag
- `false`: The scope is not applied, which means the rule applies globally regardless of tenant tag

The `scope_enabled` parameter can be applied to:
- Emergency policy rules
- Environment policy rules (both allowed and blocked communications)
- Application policy rules

Use this feature when you need to create rules that should apply to resources without the tenant tag or that require global application.

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
   
6. **Context Profile Issues**:
   - Ensure your App IDs and domain names are formatted correctly
   - Verify that context profile names match exactly as shown in NSX UI
   - Remember that when using multiple context profiles, services must be set to ANY

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
└──────────────┴──────────────┴───────────────┴────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│         Security Policies Created       │
├──────────────┬──────────────┬───────────┤
│ Emergency    │ Environment  │ Application│
└──────────────┴──────────────┴───────────┘
```

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

3. **Groups**: View the created NSX groups and their paths
   ```bash
   terraform output application_groups
   ```

4. **Context Profiles**: View the custom and predefined context profiles
   ```bash
   terraform output context_profiles
   ```

5. **Services**: View all services (predefined and custom)
   ```bash
   terraform output services
   ```

### Using Outputs for Integration

Outputs can be used for integration with other systems or for documentation:

1. **Export to JSON**: 
   ```bash
   terraform output -json > nsx_security_resources.json
   ```

2. **Usage in Scripts**:
   ```bash
   POLICY_ID=$(terraform output -raw 'policy_ids.wld01.application_policy')
   # Use the policy ID in scripts or other tools
   ```

### Note about Empty Emergency Groups

Emergency policies can reference emergency groups even when they have no VMs assigned. This allows you to add VMs to these groups later without requiring changes to the policies or infrastructure. 