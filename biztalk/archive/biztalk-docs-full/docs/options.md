# Options Analysis (Full Content)

## Option 1 – Upgrade to BizTalk 2020

### Architecture
- BizTalk handles hybrid, cloud-to-cloud, and on-prem integrations
- Heavy reliance on:
  - SOAP web services
  - File-based integrations
  - Stored procedures
- Runs fully on-prem

### Pros
- Quick mitigation of end-of-support risk
- Minimal disruption
- Enables staged migration to AIS

### Cons
- Continues legacy patterns
- Not aligned with cloud-first strategy
- Vendor lock-in and limited skills

### Risks
- BizTalk 2020 EOL by 2030
- Requires parallel AIS migration program

---

## Option 2 – Azure Integration Services (AIS)

### Architecture
- Strategic target platform (productionised 2025)
- API-led, cloud-native integration
- Current workload ~18 integrations

### Pros
- Aligns with cloud-first principles
- Supports REST, event-driven patterns
- Removes technical debt

### Cons
- Requires redesign of SOAP/file-based integrations
- Depends on cloud security perimeter

### Risks
- Requires scaling support team
- Dependency on cloud networking architecture
