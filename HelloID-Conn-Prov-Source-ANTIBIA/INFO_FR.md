# HelloID-Conn-Prov-Source-ANTIBIA — Informations FR

## À propos d'ANTIBIA

ANTIBIA est un logiciel de gestion administrative dédié aux **SDIS (Services Départementaux d'Incendie et de Secours)** édité par le groupe **ORISHA**. Il couvre les domaines RH, paie, carrière, absences, formation, activités SPV, médecine, prévention et logistique. ANTIBIA équipe aujourd'hui plus de **70 SDIS en France**.

## Ce que fait ce connecteur

Ce connecteur source HelloID permet d'importer automatiquement dans HelloID Provisioning les **agents ANTIBIA** (SPP, PATS, SPV) ainsi que leurs **contrats d'affectation**, en interrogeant directement la base SQL Server locale ANTIBIA.

Les données importées incluent :
- Identité de l'agent (nom, prénom, matricule, date de naissance, téléphones)
- Contrats avec dates de début/fin, grade, catégorie, fonction
- Affectation organisationnelle complète (CIS, groupement, service, pôle)
- Manager résolu automatiquement par la hiérarchie SDIS
- Statut de position (actif, détachement, disponibilité, radié…)

## Prérequis techniques

- Agent HelloID Provisioning déployé sur le réseau du SDIS
- Accès SQL Server (SELECT) sur la base ANTIBIA
- SQL Server accessible depuis l'agent (port TCP, généralement 1433)

## Éditeur

[ANTIBIA / ORISHA](https://www.antibia.com)
