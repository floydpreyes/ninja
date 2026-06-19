# AGA Presentation – WTP Birdwatching App (2025)

## Slide 1: Architecture Presentation
**WTP Birdwatching App**  
Date: November 2025

### Author
- Gary Franks

### Document Classification
- Official Sensitive

### Sponsoring EA
- GF

### Submission Sponsor
- Alistair McIntosh (Project manager)

---

## Slide 2: Executive Summary
- Request for TDA  
- Architecture Advice

The Western Treatment Plant (WTP) is a significant wetland habitat supporting over 300 bird species. It is listed as a Ramsar wetland of international importance. Public users can apply for a birdwatching permit via the Melbourne Water website. Approved applicants are issued physical keys and orientations.

Current challenges include minimal visibility of site entry, visitor tracking, and communication during risk events.

A mobile proof‑of‑concept app has been developed to provide guided tours, push notifications, and optional integration with Bluetooth locks (replacing physical keys).

### Target Lifecycle Position
| System | Current | Target |
|--------|---------|--------|
| WTP Birdwatching App | Innovate | Invest |

---

## Slide 3: Strategic Context
### Initiative Context
- Mobile app was developed as a POC but requires further enhancement and testing.
- Backend hosted in MW Azure tenancy.
- iOS and Android clients exist.
- Admin dashboard available.
- Several cybersecurity issues exist and are being remediated.

### Initiative Status
- Idea / BNI / BCA stage
- RFP responses received from IBM, Microsoft, and Pega.

### Architecture Context
- Business Processes: Promote Organisation, Deliver Customer Service
- Information Architecture: Geography, Risk, Customer & Community
- App Reference Model: Customer Service Management, Community Engagement, Asset Management, Site Security
- Support Tier: 4

---

## Slide 4: Strategic Context (Digital Alignment)
This project supports MW’s digital goals including:
- Customer digital services
- Customer experience
- Understanding clients
- Enriched customer services
- Safety
- Water literacy & citizen science
- Digital Customer & Digital Utility alignment

---

## Slide 5: WTP Birdwatching Location
- Map showing birdwatching areas (image not included)

---

## Slide 6: Functional Use Case
### Functions
- Apply & pay for birdwatching permit
- Access orientation & safety information
- Plan trips
- Navigate the site
- Report hazards
- Open Bluetooth-enabled locks
- Manage Bluetooth locks
- Track site visitors
- Integrate with Bluetooth beacons

Comments noted: WTP operators will push alerts to mobile app; plan to use new electronic gates.

---

## Slide 7–8: Target State – Systems Landscape
### Key components
- MW Azure tenancy
- MySQL birdwatching database
- WTP Birdwatching mobile app (iOS & Android)
- Gallagher app for Bluetooth gate locks
- Web app for operators
- Entra ID for MW users
- SQL-based authentication for public users (interim)

Planned (future): Azure edge security layer (post–April 2026).

---

## Slide 9: Key Decision 1 – Hosting
### Options
1. MW Azure tenancy (recommended)  
2. External / separate hosting environment

### Rationale
- Aligns with cloud hosting strategy
- Moderate risk due to external‑facing APIs
- Meets functional needs
- Internal team suitable for ongoing management

Trade‑off: Ideally would use Dynamics + Entra ID B2C for authentication; revisit in 2 years.

---

## Slide 10: Principles Alignment
- **Maximise enterprise benefit:** Full alignment
- **Stakeholder engagement:** Full alignment
- **Simplify & standardise:** Full alignment
- **Lifecycle / TCO:** Full alignment
- **Information care:** Full alignment
- **Adaptability:** Full alignment
- **User‑centred design:** Full alignment

---

## Slide 11: Recommendation
Redevelop the WTP Birdwatching App to a production‑ready solution.

### Implications
- Built by internal mobile team
- SQL‑based public authentication (temporary)
- Azure edge security unavailable until after April 2026

### Next Steps
- Detailed solution design

---

## Slide 12: Architecture Risks
- Information
- Privacy
- Cyber security

