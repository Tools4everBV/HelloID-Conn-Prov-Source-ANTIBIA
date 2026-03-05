# HelloID-Conn-Prov-Source-ANTIBIA

> ℹ️ Ce dépôt contient uniquement le connecteur et le code de configuration. L'implémenteur est responsable de l'obtention des informations de connexion (serveur, base de données, compte SQL). Veuillez contacter le gestionnaire applicatif du client pour coordonner les prérequis.

![Logo](https://www.antibia.com/wp-content/uploads/2021/06/logo-antibia.png)

## Table des matières

- [Introduction](#introduction)
- [Démarrage rapide](#démarrage-rapide)
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

### Mappings

Un mapping de base `mapping.json` est fourni pour les personnes et les contrats. Il doit être adapté selon les règles métier du SDIS.

### Paramètres de connexion

| Paramètre | Description | Obligatoire |
|---|---|---|
| `server` | Nom ou IP du serveur SQL Server ANTIBIA | ✅ |
| `database` | Nom de la base (généralement `RH`) | ✅ |
| `Port` | Port TCP SQL Server (défaut : `1433`) | ✅ |
| `username` | Compte SQL (si pas Trusted_Connection) | ❌ |
| `password` | Mot de passe SQL | ❌ |

> 💡 Le connecteur utilise `Trusted_Connection=True` par défaut. Pour utiliser un compte SQL dédié, modifiez la `$connectionString` dans `Persons.ps1` et `Departments.ps1`.

### Prérequis

- Agent HelloID Provisioning installé **sur le réseau du SDIS** (accès direct à SQL Server)
- Compte Windows ou SQL avec droits **SELECT** sur la base `RH`
- SQL Server accessible depuis l'agent HelloID (port TCP ouvert)
- La variable `$startPeriod` dans `Persons.ps1` doit être mise à jour chaque année pour inclure les agents radiés récents

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
   - `mapping.json`
   - `Persons.ps1`
   - `Departments.ps1`
3. Renseigner les paramètres de connexion dans l'onglet **Configuration**.
4. Lancer une **synchronisation de test** et vérifier les logs.

---

## HelloID Docs

- Documentation officielle : https://docs.helloid.com/
- Configurer un connecteur source PowerShell : https://docs.helloid.com/en/provisioning/source-systems/powershell-source-systems.html

## Aide

Pour toute question sur la configuration d'un connecteur source HelloID PowerShell, consultez la [documentation](https://docs.helloid.com/en/provisioning/source-systems/powershell-source-systems.html) ou posez vos questions sur le [forum HelloID](https://forum.helloid.com).
