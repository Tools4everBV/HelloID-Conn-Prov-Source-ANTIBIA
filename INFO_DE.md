# HelloID-Conn-Prov-Source-ANTIBIA — Informationen DE

## Über ANTIBIA

ANTIBIA ist eine Verwaltungssoftware speziell für **SDIS (Services Départementaux d'Incendie et de Secours)** — die französischen départementalen Feuerwehr- und Rettungsdienste — herausgegeben von der **ORISHA**-Gruppe. Die Lösung deckt die Bereiche Personal, Lohnabrechnung, Laufbahnverwaltung, Abwesenheiten, Ausbildung, Freiwilligenaktivitäten (SPV), Sanitätsdienst, Prävention und Logistik ab. ANTIBIA wird heute von mehr als **70 SDIS-Organisationen in Frankreich** eingesetzt.

## Was dieser Connector leistet

Dieser HelloID Provisioning Quell-Connector importiert automatisch **ANTIBIA-Mitarbeiter** (Berufsfeuerwehrleute SPP, Verwaltungs- und technisches Personal PATS sowie Freiwillige SPV) zusammen mit ihren **Einsatzverträgen** in HelloID Provisioning, indem die lokale ANTIBIA SQL Server-Datenbank direkt abgefragt wird.

Die importierten Daten umfassen:
- Personenidentität (Nachname, Vorname, Personalnummer, Geburtsdatum, Telefonnummern)
- Verträge mit Anfangs- und Enddatum, Dienstgrad, Kategorie und Funktion
- Vollständige organisatorische Zuordnung (CIS-Feuerwache, funktionale Gruppierung, Dienst, Abteilung)
- Automatisch aufgelöster Vorgesetzter über die SDIS-Hierarchie
- Positionsstatus (aktiv, Abordnung, Beurlaubung, ausgeschieden…)

## Technische Voraussetzungen

- HelloID Provisioning Agent im internen Netzwerk der SDIS-Organisation installiert
- SQL Server Lesezugriff (SELECT) auf die ANTIBIA-Datenbank
- SQL Server vom Agent aus erreichbar (TCP-Port, standardmäßig 1433)

## Herausgeber

[ANTIBIA / ORISHA](https://www.antibia.com)
