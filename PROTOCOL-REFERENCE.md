# NSX Security Framework - Protocol Reference Guide

## Overview

This document provides comprehensive reference tables for all protocol numbers and ICMP types supported by the NSX Security Framework.

---

## IP Protocol Numbers

The following table lists all IANA-assigned IP protocol numbers. Use these values in the `protocol_number` field for IP services.

### Core Protocols (0-19)

| Number | Protocol | Description | Common Use |
|--------|----------|-------------|------------|
| 0 | HOPOPT | IPv6 Hop-by-Hop Option Header | IPv6 extension headers |
| 1 | ICMP | Internet Control Message Protocol | Ping, error messages |
| 2 | IGMP | Internet Group Management Protocol | Multicast group management |
| 3 | GGP | Gateway-to-Gateway Protocol | Historic routing |
| 4 | IPv4 | IPv4 encapsulation | Tunneling |
| 5 | ST | Stream | Historic |
| 6 | TCP | Transmission Control Protocol | HTTP, HTTPS, SSH, FTP |
| 7 | CBT | CBT | Core-based trees |
| 8 | EGP | Exterior Gateway Protocol | Historic routing |
| 9 | IGP | any private interior gateway | Internal routing |
| 10 | BBN-RCC-MON | BBN RCC Monitoring | Network monitoring |
| 11 | NVP-II | Network Voice Protocol | Voice over IP |
| 12 | PUP | PUP | PARC Universal Packet |
| 13 | ARGUS | ARGUS | Network monitoring |
| 14 | EMCON | EMCON | Emission Control |
| 15 | XNET | Cross Net Debugger | Network debugging |
| 16 | CHAOS | Chaos | MIT protocol |
| 17 | UDP | User Datagram Protocol | DNS, DHCP, streaming |
| 18 | MUX | Multiplexing | Protocol multiplexing |
| 19 | DCN-MEAS | DCN Measurement Subsystems | Network measurement |

### Common Protocols (20-99)

| Number | Protocol | Description | Common Use |
|--------|----------|-------------|------------|
| 20 | HMP | Host Monitoring | Network monitoring |
| 21 | PRM | Packet Radio Measurement | Radio networks |
| 22 | XNS-IDP | XEROX NS IDP | Xerox networking |
| 23 | TRUNK-1 | Trunk-1 | Multiplexing |
| 24 | TRUNK-2 | Trunk-2 | Multiplexing |
| 25 | LEAF-1 | Leaf-1 | Network protocols |
| 26 | LEAF-2 | Leaf-2 | Network protocols |
| 27 | RDP | Reliable Data Protocol | Reliable transport |
| 28 | IRTP | Internet Reliable Transaction | Transaction protocol |
| 29 | ISO-TP4 | ISO Transport Protocol Class 4 | OSI transport |
| 30 | NETBLT | Bulk Data Transfer Protocol | Bulk transfer |
| 31 | MFE-NSP | MFE Network Services Protocol | Network services |
| 32 | MERIT-INP | MERIT Internodal Protocol | Network protocol |
| 33 | DCCP | Datagram Congestion Control Protocol | Congestion control |
| 34 | 3PC | Third Party Connect Protocol | Connection protocol |
| 35 | IDPR | Inter-Domain Policy Routing Protocol | Policy routing |
| 36 | XTP | XTP | Transport protocol |
| 37 | DDP | Datagram Delivery Protocol | AppleTalk |
| 38 | IDPR-CMTP | IDPR Control Message Transport Proto | Control messages |
| 39 | TP++ | TP++ Transport Protocol | Transport |
| 40 | IL | IL Transport Protocol | Transport |
| 41 | IPv6 | IPv6 encapsulation | IPv6 tunneling |
| 42 | SDRP | Source Demand Routing Protocol | Source routing |
| 43 | IPv6-Route | Routing Header for IPv6 | IPv6 routing |
| 44 | IPv6-Frag | Fragment Header for IPv6 | IPv6 fragmentation |
| 45 | IDRP | Inter-Domain Routing Protocol | Inter-domain routing |
| 46 | RSVP | Reservation Protocol | QoS reservations |
| 47 | GRE | Generic Routing Encapsulation | VPN tunneling |
| 48 | DSR | Dynamic Source Routing Protocol | Mobile ad hoc |
| 49 | BNA | BNA | Burroughs Network Architecture |
| 50 | ESP | Encap Security Payload | IPSec encryption |
| 51 | AH | Authentication Header | IPSec authentication |
| 52 | I-NLSP | Integrated Net Layer Security TUBA | Security |
| 53 | SWIPE | IP with Encryption | Encryption |
| 54 | NARP | NBMA Address Resolution Protocol | Address resolution |
| 55 | MOBILE | IP Mobility | Mobile IP |
| 56 | TLSP | Transport Layer Security Protocol | Security |
| 57 | SKIP | SKIP | Security |
| 58 | IPv6-ICMP | ICMP for IPv6 | IPv6 control messages |
| 59 | IPv6-NoNxt | No Next Header for IPv6 | IPv6 termination |
| 60 | IPv6-Opts | Destination Options for IPv6 | IPv6 options |
| 61 | any host internal protocol | Any host internal protocol | Internal protocols |
| 62 | CFTP | CFTP | File transfer |
| 63 | any local network | Any local network | Local protocols |
| 64 | SAT-EXPAK | SATNET and Backroom EXPAK | Satellite |
| 65 | KRYPTOLAN | Kryptolan | Encryption |
| 66 | RVD | MIT Remote Virtual Disk Protocol | Remote disk |
| 67 | IPPC | Internet Pluribus Packet Core | Packet core |
| 68 | any distributed file system | Any distributed file system | File systems |
| 69 | SAT-MON | SATNET Monitoring | Satellite monitoring |
| 70 | VISA | VISA Protocol | Network protocol |
| 71 | IPCV | Internet Packet Core Utility | Packet utility |
| 72 | CPNX | Computer Protocol Network Executive | Network executive |
| 73 | CPHB | Computer Protocol Heart Beat | Heartbeat |
| 74 | WSN | Wang Span Network | Wang networking |
| 75 | PVP | Packet Video Protocol | Video streaming |
| 76 | BR-SAT-MON | Backroom SATNET Monitoring | Satellite monitoring |
| 77 | SUN-ND | SUN ND PROTOCOL-Temporary | Sun networking |
| 78 | WB-MON | WIDEBAND Monitoring | Wideband monitoring |
| 79 | WB-EXPAK | WIDEBAND EXPAK | Wideband |
| 80 | ISO-IP | ISO Internet Protocol | ISO networking |
| 81 | VMTP | VMTP | Transaction protocol |
| 82 | SECURE-VMTP | SECURE-VMTP | Secure transactions |
| 83 | VINES | VINES | Banyan VINES |
| 84 | TTP/IPTM | Transaction Transport Protocol | Transaction transport |
| 85 | NSFNET-IGP | NSFNET-IGP | Interior gateway |
| 86 | DGP | Dissimilar Gateway Protocol | Gateway protocol |
| 87 | TCF | TCF | Terminal communication |
| 88 | EIGRP | EIGRP | Enhanced interior routing |
| 89 | OSPFIGP | OSPF | Open Shortest Path First |
| 90 | Sprite-RPC | Sprite RPC Protocol | Remote procedure calls |
| 91 | LARP | Locus Address Resolution Protocol | Address resolution |
| 92 | MTP | Multicast Transport Protocol | Multicast transport |
| 93 | AX.25 | AX.25 Frames | Amateur radio |
| 94 | IPIP | IP-within-IP Encapsulation Protocol | IP tunneling |
| 95 | MICP | Mobile Internetworking Control Pro. | Mobile control |
| 96 | SCC-SP | Semaphore Communications Sec. Pro. | Security |
| 97 | ETHERIP | Ethernet-within-IP Encapsulation | Ethernet tunneling |
| 98 | ENCAP | Encapsulation Header | Generic encapsulation |
| 99 | any private encryption scheme | Any private encryption scheme | Private encryption |

### Extended Protocols (100-140)

| Number | Protocol | Description | Common Use |
|--------|----------|-------------|------------|
| 100 | GMTP | GMTP | Group multicast |
| 101 | IFMP | Ipsilon Flow Management Protocol | Flow management |
| 102 | PNNI | PNNI over IP | ATM routing |
| 103 | PIM | Protocol Independent Multicast | Multicast routing |
| 104 | ARIS | ARIS | ATM routing |
| 105 | SCPS | SCPS | Space communications |
| 106 | QNX | QNX | QNX operating system |
| 107 | A/N | Active Networks | Active networking |
| 108 | IPComp | IP Payload Compression Protocol | Compression |
| 109 | SNP | Sitara Networks Protocol | Sitara networking |
| 110 | Compaq-Peer | Compaq Peer Protocol | Compaq networking |
| 111 | IPX-in-IP | IPX in IP | IPX tunneling |
| 112 | VRRP | Virtual Router Redundancy Protocol | Router redundancy |
| 113 | PGM | PGM Reliable Transport Protocol | Reliable multicast |
| 114 | any 0-hop protocol | Any 0-hop protocol | Local protocols |
| 115 | L2TP | Layer Two Tunneling Protocol | VPN tunneling |
| 116 | DDX | D-II Data Exchange (DDX) | Data exchange |
| 117 | IATP | Interactive Agent Transfer Protocol | Agent transfer |
| 118 | STP | Schedule Transfer Protocol | Schedule transfer |
| 119 | SRP | SpectraLink Radio Protocol | Radio protocol |
| 120 | UTI | UTI | Universal transport |
| 121 | SMP | Simple Message Protocol | Simple messaging |
| 122 | SM | Simple Multicast Protocol | Simple multicast |
| 123 | PTP | Performance Transparency Protocol | Performance |
| 124 | ISIS over IPv4 | ISIS over IPv4 | IS-IS routing |
| 125 | FIRE | FIRE | Firewall protocol |
| 126 | CRTP | Combat Radio Transport Protocol | Military radio |
| 127 | CRUDP | Combat Radio User Datagram | Military UDP |
| 128 | SSCOPMCE | SSCOPMCE | ATM signaling |
| 129 | IPLT | IPLT | IP Lightweight |
| 130 | SPS | Secure Packet Shield | Security |
| 131 | PIPE | Private IP Encapsulation within IP | Private tunneling |
| 132 | SCTP | Stream Control Transmission Protocol | Reliable transport |
| 133 | FC | Fibre Channel | Storage networking |
| 134 | RSVP-E2E-IGNORE | RSVP-E2E-IGNORE | QoS signaling |
| 135 | Mobility Header | Mobility Header | Mobile IPv6 |
| 136 | UDPLite | UDPLite | Lightweight UDP |
| 137 | MPLS-in-IP | MPLS-in-IP | MPLS tunneling |
| 138 | manet | MANET Protocols | Mobile ad hoc |
| 139 | HIP | Host Identity Protocol | Host identity |
| 140 | Shim6 | Shim6 Protocol | IPv6 multihoming |

### Reserved and Experimental (141-255)

| Range | Status | Description |
|-------|--------|-------------|
| 141-252 | Unassigned | Available for assignment |
| 253 | RFC3692-style Experiment 1 | Experimental use |
| 254 | RFC3692-style Experiment 2 | Experimental use |
| 255 | Reserved | Reserved for future use |

---

## ICMPv4 Message Types

The following table lists all ICMP message types for IPv4. Use these values in the `icmp_type` field for ICMPv4 services.

### Control Messages (0-19)

| Type | Name | Description | RFC | Common Use |
|------|------|-------------|-----|------------|
| 0 | Echo Reply | Echo Reply | RFC 792 | Ping response |
| 1 | Unassigned | Unassigned | - | Not used |
| 2 | Unassigned | Unassigned | - | Not used |
| 3 | Destination Unreachable | Destination Unreachable | RFC 792 | Network unreachable |
| 4 | Source Quench | Source Quench (Deprecated) | RFC 792 | Flow control (deprecated) |
| 5 | Redirect | Redirect | RFC 792 | Route redirection |
| 6 | Alternate Host Address | Alternate Host Address (Deprecated) | RFC 792 | Alternative addressing |
| 7 | Unassigned | Unassigned | - | Not used |
| 8 | Echo | Echo | RFC 792 | Ping request |
| 9 | Router Advertisement | Router Advertisement | RFC 1256 | Router discovery |
| 10 | Router Solicitation | Router Solicitation | RFC 1256 | Router discovery |
| 11 | Time Exceeded | Time Exceeded | RFC 792 | TTL exceeded |
| 12 | Parameter Problem | Parameter Problem | RFC 792 | Header issues |
| 13 | Timestamp | Timestamp | RFC 792 | Time synchronization |
| 14 | Timestamp Reply | Timestamp Reply | RFC 792 | Time synchronization |
| 15 | Information Request | Information Request (Deprecated) | RFC 792 | Network info (deprecated) |
| 16 | Information Reply | Information Reply (Deprecated) | RFC 792 | Network info (deprecated) |
| 17 | Address Mask Request | Address Mask Request (Deprecated) | RFC 950 | Subnet mask (deprecated) |
| 18 | Address Mask Reply | Address Mask Reply (Deprecated) | RFC 950 | Subnet mask (deprecated) |
| 19 | Reserved | Reserved (for Security) | - | Security use |

### Extended Messages (20-42)

| Type | Name | Description | RFC | Common Use |
|------|------|-------------|-----|------------|
| 20-29 | Reserved | Reserved (for Robustness Experiment) | - | Experimental |
| 30 | Traceroute | Traceroute (Deprecated) | RFC 1393 | Path tracing (deprecated) |
| 31 | Datagram Conversion Error | Datagram Conversion Error (Deprecated) | RFC 1475 | Conversion error |
| 32 | Mobile Host Redirect | Mobile Host Redirect (Deprecated) | RFC 1475 | Mobile IP |
| 33 | IPv6 Where-Are-You | IPv6 Where-Are-You (Deprecated) | RFC 1475 | IPv6 discovery |
| 34 | IPv6 I-Am-Here | IPv6 I-Am-Here (Deprecated) | RFC 1475 | IPv6 response |
| 35 | Mobile Registration Request | Mobile Registration Request (Deprecated) | RFC 1475 | Mobile IP |
| 36 | Mobile Registration Reply | Mobile Registration Reply (Deprecated) | RFC 1475 | Mobile IP |
| 37 | Domain Name Request | Domain Name Request (Deprecated) | RFC 1475 | DNS request |
| 38 | Domain Name Reply | Domain Name Reply (Deprecated) | RFC 1475 | DNS response |
| 39 | SKIP | SKIP (Deprecated) | RFC 1475 | Security protocol |
| 40 | Photuris | Photuris | RFC 2521 | Security association |
| 41 | ICMP messages utilized by experimental mobility protocols such as Seamoby | Experimental Mobility | RFC 4065 | Mobile networking |
| 42 | Extended Echo Request | Extended Echo Request | RFC 8335 | Enhanced ping |

### Reserved and Future Use (43-255)

| Range | Status | Description |
|-------|--------|-------------|
| 43 | Extended Echo Reply | Enhanced ping response |
| 44-252 | Unassigned | Available for assignment |
| 253 | RFC3692-style Experiment 1 | Experimental use |
| 254 | RFC3692-style Experiment 2 | Experimental use |
| 255 | Reserved | Reserved for future use |

---

## ICMPv6 Message Types

The following table lists all ICMP message types for IPv6. Use these values in the `icmp_type` field for ICMPv6 services.

### Error Messages (0-127)

| Type | Name | Description | RFC | Common Use |
|------|------|-------------|-----|------------|
| 0 | Reserved | Reserved | - | Not used |
| 1 | Destination Unreachable | Destination Unreachable | RFC 4443 | Network unreachable |
| 2 | Packet Too Big | Packet Too Big | RFC 4443 | MTU discovery |
| 3 | Time Exceeded | Time Exceeded | RFC 4443 | Hop limit exceeded |
| 4 | Parameter Problem | Parameter Problem | RFC 4443 | Header issues |
| 5-99 | Unassigned | Unassigned | - | Future error messages |
| 100 | Private experimentation | Private experimentation | RFC 4443 | Private use |
| 101 | Private experimentation | Private experimentation | RFC 4443 | Private use |
| 102-126 | Unassigned | Unassigned | - | Future error messages |
| 127 | Reserved for expansion | Reserved for expansion | RFC 4443 | Future expansion |

### Informational Messages (128-255)

| Type | Name | Description | RFC | Common Use |
|------|------|-------------|-----|------------|
| 128 | Echo Request | Echo Request | RFC 4443 | Ping request |
| 129 | Echo Reply | Echo Reply | RFC 4443 | Ping response |
| 130 | Multicast Listener Query | Multicast Listener Query | RFC 2710 | Multicast group management |
| 131 | Multicast Listener Report | Multicast Listener Report | RFC 2710 | Multicast group management |
| 132 | Multicast Listener Done | Multicast Listener Done | RFC 2710 | Multicast group management |
| 133 | Router Solicitation | Router Solicitation | RFC 4861 | Router discovery |
| 134 | Router Advertisement | Router Advertisement | RFC 4861 | Router discovery |
| 135 | Neighbor Solicitation | Neighbor Solicitation | RFC 4861 | Neighbor discovery |
| 136 | Neighbor Advertisement | Neighbor Advertisement | RFC 4861 | Neighbor discovery |
| 137 | Redirect Message | Redirect Message | RFC 4861 | Route redirection |
| 138 | Router Renumbering | Router Renumbering | RFC 2894 | Router renumbering |
| 139 | ICMP Node Information Query | ICMP Node Information Query | RFC 4620 | Node information |
| 140 | ICMP Node Information Response | ICMP Node Information Response | RFC 4620 | Node information |
| 141 | Inverse Neighbor Discovery Solicitation | Inverse Neighbor Discovery Solicitation | RFC 3122 | Inverse neighbor discovery |
| 142 | Inverse Neighbor Discovery Advertisement | Inverse Neighbor Discovery Advertisement | RFC 3122 | Inverse neighbor discovery |
| 143 | Version 2 Multicast Listener Report | Version 2 Multicast Listener Report | RFC 3810 | MLDv2 |
| 144 | Home Agent Address Discovery Request | Home Agent Address Discovery Request | RFC 6275 | Mobile IPv6 |
| 145 | Home Agent Address Discovery Reply | Home Agent Address Discovery Reply | RFC 6275 | Mobile IPv6 |
| 146 | Mobile Prefix Solicitation | Mobile Prefix Solicitation | RFC 6275 | Mobile IPv6 |
| 147 | Mobile Prefix Advertisement | Mobile Prefix Advertisement | RFC 6275 | Mobile IPv6 |
| 148 | Certification Path Solicitation | Certification Path Solicitation | RFC 3971 | SEND protocol |
| 149 | Certification Path Advertisement | Certification Path Advertisement | RFC 3971 | SEND protocol |
| 150 | ICMP messages utilized by experimental mobility protocols such as Seamoby | Experimental Mobility | RFC 4065 | Mobile networking |
| 151 | Multicast Router Advertisement | Multicast Router Advertisement | RFC 4286 | Multicast routing |
| 152 | Multicast Router Solicitation | Multicast Router Solicitation | RFC 4286 | Multicast routing |
| 153 | Multicast Router Termination | Multicast Router Termination | RFC 4286 | Multicast routing |
| 154 | FMIPv6 Messages | FMIPv6 Messages | RFC 5568 | Fast Mobile IPv6 |
| 155 | RPL Control Message | RPL Control Message | RFC 6550 | RPL routing |
| 156 | ILNPv6 Locator Update Message | ILNPv6 Locator Update Message | RFC 6743 | ILNP |
| 157 | Duplicate Address Request | Duplicate Address Request | RFC 6775 | 6LoWPAN |
| 158 | Duplicate Address Confirmation | Duplicate Address Confirmation | RFC 6775 | 6LoWPAN |
| 159 | MPL Control Message | MPL Control Message | RFC 7731 | Multicast Protocol for Low-Power |
| 160 | Extended Echo Request | Extended Echo Request | RFC 8335 | Enhanced ping |
| 161 | Extended Echo Reply | Extended Echo Reply | RFC 8335 | Enhanced ping |
| 162-199 | Unassigned | Unassigned | - | Future informational messages |
| 200 | Private experimentation | Private experimentation | RFC 4443 | Private use |
| 201 | Private experimentation | Private experimentation | RFC 4443 | Private use |
| 202-254 | Unassigned | Unassigned | - | Future informational messages |
| 255 | Reserved for expansion | Reserved for expansion | RFC 4443 | Future expansion |

---

## Configuration Examples

### Using Protocol Numbers
```yaml
custom_services:
  svc-gre-tunnel:
    protocol: ip
    protocol_number: 47  # GRE
  
  svc-ipsec-esp:
    protocol: ip
    protocol_number: 50  # ESP
  
  svc-ipsec-ah:
    protocol: ip
    protocol_number: 51  # AH
  
  svc-ospf-routing:
    protocol: ip
    protocol_number: 89  # OSPF
```

### Using ICMP Types
```yaml
custom_services:
  svc-ping-request:
    protocol: icmp
    icmp_type: 8   # Echo Request
    icmp_code: 0
  
  svc-ping-reply:
    protocol: icmp
    icmp_type: 0   # Echo Reply
  
  svc-dest-unreachable:
    protocol: icmp
    icmp_type: 3   # Destination Unreachable
```

### Using ICMPv6 Types
```yaml
custom_services:
  svc-ipv6-ping:
    protocol: icmpv6
    icmp_type: 128  # Echo Request
  
  svc-neighbor-discovery:
    protocol: icmpv6
    icmp_type: 135  # Neighbor Solicitation
  
  svc-router-discovery:
    protocol: icmpv6
    icmp_type: 133  # Router Solicitation
```

---

## References

- **IANA Protocol Numbers**: https://www.iana.org/assignments/protocol-numbers/
- **IANA ICMP Type Numbers**: https://www.iana.org/assignments/icmp-parameters/
- **IANA ICMPv6 Type Numbers**: https://www.iana.org/assignments/icmpv6-parameters/
- **RFC 792**: Internet Control Message Protocol (ICMP)
- **RFC 4443**: Internet Control Message Protocol (ICMPv6) for IPv6
- **RFC 4861**: Neighbor Discovery for IP version 6 (IPv6)

---

## Notes

1. **Protocol Number Range**: Valid protocol numbers are 0-255
2. **ICMP Type Range**: Valid ICMP types are 0-255
3. **ICMPv6 Type Range**: Valid ICMPv6 types are 0-255
4. **Code Values**: Many ICMP types support code values (0-255) for sub-categories
5. **NSX Validation**: Not all protocol numbers and ICMP types may be supported by your NSX version
6. **Testing**: Always test custom protocol configurations in a development environment first 