# HelloID-Conn-Prov-Source-ANTIBIA

> ℹ️ Ce dépôt contient uniquement le connecteur et le code de configuration. L'implémenteur est responsable de l'obtention des informations de connexion (serveur, base de données, compte SQL). Veuillez contacter le gestionnaire applicatif du client pour coordonner les prérequis.

![Logo](https://media.licdn.com/dms/image/v2/D4E3DAQE7HoWsY5epHA/image-scale_191_1128/image-scale_191_1128/0/1698053055557/antibia_cover?e=2147483647&v=beta&t=3wDjWj4iBzmsnTWDU0ZHCmYa3Odqf1QO-k42XbPhP3A)

## Table des matières

- [Introduction](#introduction)
- [Démarrage rapide](#démarrage-rapide)
  - [Attributs personnalisés (Custom fields)](#attributs-personnalisés-custom-fields)
  - [Mappings](#mappings)
  - [Paramètres de connexion](#paramètres-de-connexion)
  - [Prérequis](#prérequis)
  - [Remarques](#remarques)
- [Configuration du connecteur](#configuration-du-connecteur)
- [HelloID Docs](#helloid-docs)
- [Aide](#aide)

---

## Introduction

**HelloID-Conn-Prov-Source-ANTIBIA** est un connecteur **source** HelloID Provisioning pour le logiciel **ANTIBIA RH** édité par le groupe ORISHA.

ANTIBIA est une solution de gestion administrative dédiée aux **SDIS (Services Départementaux d'Incendie et de Secours)**, couvrant les modules RH, paie, carrière, formation, activités SPV, médecine et logistique. Elle équipe aujourd'hui plus de **70 SDIS en France**.

La communication avec ANTIBIA s'effectue via des **requêtes SQL Server** directes sur la base de données locale ANTIBIA (`RH.dbo`).

### Tables et vues utilisées

| Table / Vue | Description |
|---|---|
| `RH.dbo.Pompers` | Agents actifs (SPP, PATS, SPV) |
| `RH.dbo.Na_pers` | Agents partis / radiés archivés |
| `RH.dbo.Pomperssuppr` / `Na_perssuppr` | Agents supprimés (conservation date radiation) |
| `RH.dbo.Pompcor` / `PompcorHD` | Référentiel CIS (actifs et historiques) |
| `RH.dbo.Pomphistcis` / `Pomphistcissec` | Historique affectations CIS principale/secondaire |
| `RH.dbo.Na_histcis` / `Na_histcissec` | Idem pour agents Na_pers |
| `RH.dbo.Pomphistunit` | Historique groupements fonctionnels |
| `RH.dbo.Pomphistserv` | Historique services |
| `RH.dbo.Pomphistposit` | Historique positions statutaires |
| `RH.dbo.PompHistSusp` | Historique suspensions |
| `RH.dbo.PomphistDirection` | Historique pôles / directions |
| `RH.dbo.Pompgserv` | Référentiel groupements fonctionnels |
| `RH.dbo.Pompserv` | Référentiel services |
| `RH.dbo.Pomppfct` | Référentiel fonctions |
| `RH.dbo.Sp_grade` | Référentiel grades |
| `RH.dbo.Tabcateg` | Référentiel catégories (Professionnel, Volontaire, PAT, JSP…) |
| `RH.dbo.TABTYPCO` | Référentiel types de CIS |
| `RH.dbo.Pompgpt` | Référentiel groupements territoriaux |

---

## Démarrage rapide

### Attributs personnalisés (Custom fields)

> ⚠️ **Étape obligatoire avant l'import du mapping.**
>
> Le mapping fourni (`mapping.json`) utilise des **attributs personnalisés** (`Custom.*`) sur les contrats HelloID. Ces champs n'existent pas par défaut dans HelloID et doivent être créés manuellement dans le schéma du Source System avant d'importer le mapping, sans quoi l'import échouera.

Pour créer les attributs personnalisés, aller dans **HelloID Provisioning → Source Systems → ANTIBIA → Schema → Contract attributes** et ajouter les champs suivants :

| Nom de l'attribut | Type | Source (champ ANTIBIA) | Description |
|---|---|---|---|
| `Custom.assistantExternalId` | String | `AssistantID` | Matricule de l'assistant (si applicable) |
| `Custom.departmentCode` | String | `DepartmentSigle` | Sigle du groupement fonctionnel |
| `Custom.divisionCode` | String | `ServiceSigle` | Sigle du service |
| `Custom.grade` | String | `Grade` | Grade de l'agent |
| `Custom.locationEmail` | String | `CenterEmail` | Email du CIS d'affectation |
| `Custom.postalCode` | String | `PostalCode` | Code postal du CIS |
| `Custom.Statut` | String | `StatutPosition` | Statut de position (ACTIF, RADIE, DETACHEMENT…) |
| `Custom.street1` | String | `StreetAddress1` | Adresse ligne 1 du CIS |
| `Custom.street2` | String | `StreetAddress2` | Adresse ligne 2 du CIS |
| `Custom.Ville` | String | `City` | Ville du CIS |

> 💡 Le type **String** convient pour tous ces attributs. L'option `convertToString: true` est déjà activée dans le mapping pour chacun d'eux.

---

### Mappings

Le fichier `mapping.json` fourni couvre l'intégralité des champs personnes et contrats. Voici un résumé :

**Personnes (`personMappings`) :**

| Champ HelloID | Mode | Valeur / Source |
|---|---|---|
| `ExternalId` | field | `ExternalId` (matricule) |
| `Name.FamilyName` | field | `LastName` (MAJUSCULES) |
| `Name.GivenName` | field | `FirstName` (capitalisé) |
| `Name.FamilyNamePartner` | field | `LastName` |
| `Name.Convention` | fixed | `P` |
| `Details.BirthDate` | field | `BirthDate` |
| `Contact.Business.Phone.Fixed` | field | `OfficePhone` |
| `Contact.Business.Phone.Mobile` | field | `OfficeMobile` |
| `Contact.Personal.Phone.Mobile` | field | `MobilePhone` |
| `Contact.Personal.Email` | field | `PrivateEmail` |
| `Contact.Business.Address.*` | field | Adresse du CIS principal |
| `Contact.Business.Address.Country` | fixed | `FRANCE` |

**Contrats (`contractMappings`) :**

| Champ HelloID | Mode | Valeur / Source |
|---|---|---|
| `ExternalId` | field | `ExternalID` |
| `StartDate` | field | `StartDate` |
| `EndDate` | field | `EndDate` |
| `Title.Name` | complex | `Title1 + " - " + Title2` (JS) |
| `Type.Description` | field | `Category` (Professionnel / Volontaire / PAT) |
| `Details.Fte` | field | `FTE` (priorité contrat) |
| `Manager.ExternalId` | field | `ManagerID` (matricule résolu) |
| `Department.ExternalId` | field | `DepartmentCode` |
| `Department.DisplayName` | field | `Department` |
| `Division.ExternalId` / `.Code` | field | `ServiceCode` |
| `Division.Name` | field | `Service` |
| `Location.ExternalId` | field | `CenterCode` |
| `Location.Name` | field | `Center` |
| `Location.Code` | field | `TypeCIS` |
| `Custom.*` | field | Voir tableau attributs personnalisés ci-dessus |

---

### Paramètres de connexion

| Paramètre | Description | Obligatoire |
|---|---|---|
| `server` | Nom ou IP du serveur SQL Server ANTIBIA | ✅ |
| `database` | Nom de la base (généralement `RH`) | ✅ |
| `Port` | Port TCP SQL Server (défaut : `1433`) | ✅ |
| `username` | Compte SQL (si pas Trusted_Connection) | ❌ |
| `password` | Mot de passe SQL | ❌ |
| `startPeriod` | Date de début pour l'inclusion des agents radiés (format `MM/dd/yyyy HH:mm:ss`) | ✅ |
| `matriculesToExclude` | Matricules à exclure, séparés par des virgules | ❌ |
| `groupementTerritorialKey` | Clé ANTIBIA du groupement territorial de fallback pour les chefs de CIS SPV | ❌ |

> 💡 Le connecteur utilise `Trusted_Connection=True` par défaut. Pour utiliser un compte SQL dédié, modifiez la `$connectionString` dans `Persons.ps1` et `Departments.ps1`.

---

### Prérequis

- Agent HelloID Provisioning installé **sur le réseau du SDIS** (accès direct à SQL Server)
- Compte Windows ou SQL avec droits **SELECT** sur la base `RH`
- SQL Server accessible depuis l'agent HelloID (port TCP ouvert)
- Attributs personnalisés créés dans le schéma HelloID (voir section [Attributs personnalisés](#attributs-personnalisés-custom-fields))
- Le paramètre `startPeriod` doit être mis à jour chaque année pour inclure les agents radiés récents

### Remarques

**Gestion des catégories :**
- Les agents **JSP** (Jeunes Sapeurs-Pompiers) sont **exclus** des contrats exportés vers HelloID.
- Les agents **Volontaires (SPV)** avec plusieurs fiches actives sont traités spécifiquement (prise en compte de la fiche non-volontaire).

**Résolution du manager :**
La hiérarchie de résolution du manager est la suivante (du plus précis au plus général) :
1. Chef de Service du contrat
2. Chef de Groupement du contrat
3. Chef de Pôle du contrat
4. Directeur Départemental (DDSIS)
5. `$null` si le DDSIS est lui-même la personne

**Priorité des contrats (`FTE`) :**
| Valeur | Signification |
|---|---|
| `2` | Contrat principal SPP ou PAT |
| `1` | Contrat principal SPV |
| `0` | Contrat secondaire |

**Statuts de position (`StatutPosition`) :**
`ACTIF`, `RADIE`, `DETACHEMENT`, `DETACHEMENT INTERNE`, `HORS CADRE`, `DISPONIBILITE`, `CONGE PARENTAL`, `CONGE DE PRESENCE PARENTALE`, `MISE A DISPO`, `AUTRE`

---

## Configuration du connecteur

1. Dans HelloID Provisioning, ajouter un nouveau **Source System** de type PowerShell.
2. Importer les fichiers suivants :
   - `configuration.json`
   - `Persons.ps1`
   - `Departments.ps1`
3. Renseigner les paramètres de connexion dans l'onglet **Configuration** (voir tableau [Paramètres de connexion](#paramètres-de-connexion)).
4. **Créer les attributs personnalisés** dans le schéma du connecteur (voir section [Attributs personnalisés](#attributs-personnalisés-custom-fields)).
5. Importer le fichier `mapping.json` dans l'onglet **Mapping**.
6. Lancer une **synchronisation de test** et vérifier les logs.

---

## HelloID Docs

- Documentation officielle : https://docs.helloid.com/
- Configurer un connecteur source PowerShell : https://docs.helloid.com/en/provisioning/source-systems/powershell-source-systems.html
- Gérer les attributs personnalisés : https://docs.helloid.com/en/provisioning/source-systems/manage-source-system-schema.html

## Aide

Pour toute question sur la configuration d'un connecteur source HelloID PowerShell, consultez la [documentation](https://docs.helloid.com/en/provisioning/source-systems/powershell-source-systems.html) ou posez vos questions sur le [forum HelloID](https://forum.helloid.com).
