# HelloID-Conn-Prov-Source-ANTIBIA — Informatie NL

## Over ANTIBIA

ANTIBIA is een administratief beheerpakket specifiek ontwikkeld voor **SDIS (Services Départementaux d'Incendie et de Secours)** — de Franse regionale brandweer- en reddingsdiensten — en wordt uitgegeven door de **ORISHA** groep. Het pakket dekt de domeinen HR, salarisadministratie, loopbaan, verzuim, opleiding, vrijwilligersactiviteiten (SPV), medische diensten, preventie en logistiek. ANTIBIA is momenteel in gebruik bij meer dan **70 SDIS-organisaties in Frankrijk**.

## Wat doet deze connector

Deze HelloID Provisioning bronconnector importeert automatisch **ANTIBIA-medewerkers** (beroepsbrandweerlieden SPP, administratief/technisch personeel PATS en vrijwilligers SPV) samen met hun **aanstellingscontracten** in HelloID Provisioning, door rechtstreeks de lokale ANTIBIA SQL Server-database te bevragen.

De geïmporteerde gegevens omvatten:
- Persoonsidentiteit (achternaam, voornaam, personeelsnummer, geboortedatum, telefoonnummers)
- Contracten met begin- en einddatum, rang, categorie en functie
- Volledige organisatorische plaatsing (CIS-brandweerpost, groepering, dienst, pool)
- Automatisch opgeloste manager via de SDIS-hiërarchie
- Positiestatus (actief, detachering, beschikbaarheid, uitgetreden…)

## Technische vereisten

- HelloID Provisioning Agent geïnstalleerd op het interne netwerk van de SDIS-organisatie
- SQL Server leesrechten (SELECT) op de ANTIBIA-database
- SQL Server bereikbaar vanaf de agent (TCP-poort, standaard 1433)

## Uitgever

[ANTIBIA / ORISHA](https://www.antibia.com)
