# HelloID-Conn-Prov-Source-ANTIBIA — Information EN

## About ANTIBIA

ANTIBIA is an administrative management software dedicated to **SDIS (Services Départementaux d'Incendie et de Secours)** — the French departmental fire and rescue services — published by the **ORISHA** group. It covers HR, payroll, career management, leave, training, volunteer activities (SPV), medical services, prevention and logistics. ANTIBIA is currently used by more than **70 SDIS organisations across France**.

## What this connector does

This HelloID Provisioning source connector automatically imports **ANTIBIA employees** (professional firefighters SPP, administrative/technical staff PATS, and volunteers SPV) along with their **assignment contracts** into HelloID Provisioning, by querying the local ANTIBIA SQL Server database directly.

Imported data includes:
- Person identity (last name, first name, employee number, date of birth, phone numbers)
- Contracts with start/end dates, rank, category and job title
- Full organisational placement (CIS fire station, functional grouping, service, division)
- Manager automatically resolved through the SDIS hierarchy
- Position status (active, secondment, leave of absence, retired…)

## Technical requirements

- HelloID Provisioning Agent deployed on the internal network of the SDIS organisation
- SQL Server read access (SELECT) on the ANTIBIA database
- SQL Server reachable from the agent (TCP port, default 1433)

## Publisher

[ANTIBIA / ORISHA](https://www.antibia.com)
