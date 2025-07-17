# Custom Services Configuration Guide

This guide provides detailed instructions for configuring custom services in the NSX Security Framework using all supported service types from the NSX UI.

## Overview

The NSX Security Framework supports creating custom services for various protocols and service types that match the options available in the NSX Manager UI. This includes Layer 3, Layer 4, and application-specific services.

## Supported Service Types

Based on the NSX Manager UI, the following service types are supported:

1. **TCP** - Transmission Control Protocol services with port specifications
2. **UDP** - User Datagram Protocol services with port specifications  
3. **ICMPv4** - Internet Control Message Protocol version 4
4. **ICMPv6** - Internet Control Message Protocol version 6
5. **IP** - IP Protocol services for specific protocol numbers
6. **IGMP** - Internet Group Management Protocol
7. **ALG** - Application Layer Gateway services

## Configuration Structure

Custom services are defined in the `inventory.yaml` file under the `custom_services` section:

```yaml
tenant_id:
  custom_services:
    service-name:
      protocol: service_type
      # Additional parameters based on service type
```

## Service Type Configurations

### 1. TCP Services

Used for TCP-based applications with specific port requirements.

```yaml
custom_services:
  svc-custom-web-alt:
    protocol: tcp
    ports:
      - 8080
      - 8443
  
  svc-custom-database:
    protocol: tcp
    ports:
      - 1521
      - 1522
```

**Use Cases:**
- Custom web applications on non-standard ports
- Database services with specific port ranges
- Application servers with custom configurations

### 2. UDP Services

Used for UDP-based applications and services.

```yaml
custom_services:
  svc-custom-dns:
    protocol: udp
    ports:
      - 5353
  
  svc-custom-syslog:
    protocol: udp
    ports:
      - 1514
      - 2514
```

**Use Cases:**
- Custom DNS services (multicast DNS)
- Syslog servers on non-standard ports
- Voice over IP (VoIP) applications
- Gaming services
- Network monitoring tools

### 3. ICMPv4 Services

Used for IPv4 ICMP traffic with specific type and code combinations.

```yaml
custom_services:
  svc-custom-icmp-ping:
    protocol: icmp  # or icmpv4
    icmp_type: 8
    icmp_code: 0
  
  svc-custom-icmp-unreachable:
    protocol: icmpv4
    icmp_type: 3
    # icmp_code is optional - omit to allow all codes for the type
```

**Common ICMP Types:**
- Type 0: Echo Reply (ping response)
- Type 3: Destination Unreachable
- Type 8: Echo Request (ping)
- Type 11: Time Exceeded
- Type 12: Parameter Problem

**Use Cases:**
- Network troubleshooting tools
- Custom ping applications
- Network monitoring systems
- Path MTU discovery

### 4. ICMPv6 Services

Used for IPv6 ICMP traffic with specific type and code combinations.

```yaml
custom_services:
  svc-custom-icmpv6-ping:
    protocol: icmpv6
    icmp_type: 128
    # Note: icmp_code omitted - NSX validates type/code combinations
  
  svc-custom-icmpv6-neighbor:
    protocol: icmpv6
    icmp_type: 135
    # Note: icmp_code typically omitted for this type
  
  svc-custom-icmpv6-reply:
    protocol: icmpv6
    icmp_type: 129
    icmp_code: 0  # Code can be specified for reply messages
```

**Common ICMPv6 Types:**
- Type 128: Echo Request
- Type 129: Echo Reply
- Type 133: Router Solicitation
- Type 134: Router Advertisement
- Type 135: Neighbor Solicitation
- Type 136: Neighbor Advertisement

**Important Notes:**
- NSX validates ICMPv6 type/code combinations strictly
- For many ICMPv6 types (128, 135, 134), omit `icmp_code` unless specifically required
- Test your ICMPv6 service configurations as NSX may reject invalid combinations

**Use Cases:**
- IPv6 network discovery
- IPv6 neighbor discovery protocol
- IPv6 router advertisement filtering
- IPv6 troubleshooting tools

### 5. IP Protocol Services

Used for services that operate on specific IP protocol numbers (Layer 3 protocols).

```yaml
custom_services:
  svc-custom-gre:
    protocol: ip
    protocol_number: 47
  
  svc-custom-esp:
    protocol: ip
    protocol_number: 50
  
  svc-custom-ospf:
    protocol: ip
    protocol_number: 89
```

**Common IP Protocol Numbers:**
- 1: ICMP
- 2: IGMP
- 6: TCP
- 17: UDP
- 47: GRE (Generic Routing Encapsulation)
- 50: ESP (Encapsulating Security Payload)
- 51: AH (Authentication Header)
- 89: OSPF
- 103: PIM (Protocol Independent Multicast)

**Use Cases:**
- VPN tunneling protocols (GRE, ESP, AH)
- Routing protocols (OSPF, PIM)
- Custom Layer 3 protocols
- Network overlay technologies

### 6. IGMP Services

Used for Internet Group Management Protocol traffic (multicast group management).

```yaml
custom_services:
  svc-custom-igmp:
    protocol: igmp
```

**Use Cases:**
- Multicast video streaming
- IPTV services
- Multicast routing protocols
- Video conferencing systems
- Network discovery protocols

### 7. ALG (Application Layer Gateway) Services

**Note**: ALG services in the current implementation are created as TCP port services due to Terraform provider limitations. Full ALG functionality may require NSX Manager UI configuration.

```yaml
custom_services:
  svc-custom-oracle-tns:
    protocol: alg
    destination_port: 1521
    # Creates a TCP service on port 1521
  
  svc-custom-ftp-data:
    protocol: alg
    destination_port: 21
    # Creates a TCP service on port 21
  
  svc-custom-ms-rpc:
    protocol: alg
    destination_port: 135
    # Creates a TCP service on port 135
```

**Implementation Note:**
ALG services are currently implemented as TCP port services. For full Application Layer Gateway functionality with protocol inspection and dynamic port handling, you may need to:
1. Use predefined NSX services that include ALG support
2. Configure ALG services directly in NSX Manager UI
3. Wait for future Terraform provider updates

**Use Cases:**
- Basic port-based filtering for ALG applications
- Placeholder services for applications requiring ALG support
- Services that primarily use fixed ports

## Complete Example Configuration

Here's a comprehensive example showing multiple service types in a single tenant configuration:

```yaml
wld01:
  # ... other tenant configuration ...
  
  custom_services:
    # TCP Services
    svc-wld01-custom-web:
      protocol: tcp
      ports:
        - 8080
        - 8443
    
    svc-wld01-oracle-db:
      protocol: tcp
      ports:
        - 1521
        - 1522
    
    # UDP Services  
    svc-wld01-custom-dns:
      protocol: udp
      ports:
        - 5353
    
    svc-wld01-syslog:
      protocol: udp
      ports:
        - 1514
    
    # ICMP Services
    svc-wld01-ping-monitoring:
      protocol: icmp
      icmp_type: 8
      icmp_code: 0
    
    svc-wld01-icmp-unreachable:
      protocol: icmpv4
      icmp_type: 3
    
    # ICMPv6 Services
    svc-wld01-ipv6-ping:
      protocol: icmpv6
      icmp_type: 128
      # icmp_code omitted for Echo Request
    
    svc-wld01-ipv6-neighbor:
      protocol: icmpv6
      icmp_type: 135
      # icmp_code omitted for Neighbor Solicitation
    
    # IP Protocol Services
    svc-wld01-gre-tunnel:
      protocol: ip
      protocol_number: 47
    
    svc-wld01-esp-vpn:
      protocol: ip
      protocol_number: 50
    
    svc-wld01-ospf-routing:
      protocol: ip
      protocol_number: 89
    
    # IGMP Services
    svc-wld01-multicast:
      protocol: igmp
    
    # ALG Services (implemented as TCP services)
    svc-wld01-oracle-alg:
      protocol: alg
      destination_port: 1521
    
    svc-wld01-ftp-service:
      protocol: alg
      destination_port: 21
    
    svc-wld01-ms-rpc:
      protocol: alg
      destination_port: 135
```

## Using Custom Services in Security Policies

Once defined in the inventory, custom services can be referenced in the `authorized-flows.yaml` file:

```yaml
wld01:
  application_policy:
    pol-wld01-custom-services:
      - name: Allow custom web traffic
        source:
          - app-wld01-prod-web
        destination:
          - app-wld01-prod-app
        custom_services:
          - svc-wld01-custom-web
        action: ALLOW
      
      - name: Allow database connections
        source:
          - app-wld01-prod-app
        destination:
          - app-wld01-prod-db
        custom_services:
          - svc-wld01-oracle-db
          - svc-wld01-oracle-alg
        action: ALLOW
      
      - name: Allow multicast traffic
        source:
          - app-wld01-prod-app
        destination:
          - ext-wld01-multicast
        custom_services:
          - svc-wld01-multicast
        action: ALLOW
```

## Best Practices

### 1. Naming Conventions
- Use descriptive names that include the tenant ID: `svc-{tenant}-{purpose}`
- Include the protocol or service type in the name for clarity
- Be consistent across all tenants

### 2. Service Organization
- Group related services logically
- Document the purpose of each custom service
- Use comments in YAML to explain complex configurations

### 3. Security Considerations
- Only create custom services for legitimate business requirements
- Avoid overly broad port ranges
- Document the applications that use each custom service
- Regular review and cleanup of unused services

### 4. Protocol Selection
- Choose the most specific protocol type possible
- Use ALG services when applications require special protocol handling
- Consider using predefined NSX services before creating custom ones

### 5. Testing and Validation
- Test custom services in non-production environments first
- Validate that applications work correctly with custom service definitions
- Monitor traffic to ensure services are being used as expected

## Troubleshooting

### Common Issues

1. **Service Not Applied**: Ensure the custom service is referenced correctly in `authorized-flows.yaml`
2. **Invalid Protocol Number**: Verify IP protocol numbers are valid (0-255)
3. **ICMP/ICMPv6 Type/Code Mismatch**: 
   - Check ICMP type and code combinations are valid
   - For ICMPv6, omit `icmp_code` for types like 128 (Echo Request), 135 (Neighbor Solicitation), 134 (Router Advertisement)
   - NSX has strict validation for ICMPv6 type/code combinations
4. **ALG Type Not Supported**: Verify the ALG type is supported by your NSX version
5. **Port Format Issues**: Ensure ports are specified as integers in YAML

### Validation Steps

1. Check Terraform plan output for any validation errors
2. Verify service creation in NSX Manager UI
3. Test connectivity using the custom service
4. Review NSX logs for any service-related errors

## Version Compatibility

This implementation is compatible with:
- NSX-T 3.0+
- NSX 4.0+
- Terraform NSX Provider 3.0+

Note: Some ALG types may require specific NSX versions. Consult VMware documentation for detailed compatibility information. 