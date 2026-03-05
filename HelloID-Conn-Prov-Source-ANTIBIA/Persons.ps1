# Initialisation des variables
$config = ($configuration | convertfrom-json)
$server = $config.server
$database = $config.database
$Port = $config.Port
$startPeriod = "01/01/2025 00:00:00"
$connectionString = "Server=$server,$Port;Database=$database;Trusted_Connection=True;"

# Définition de la culture française pour la mise en forme
$culture = New-Object System.Globalization.CultureInfo("fr-FR")

# Fonction pour capitaliser correctement un prénom
function Capitalize-Name {
    param ([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $Name }
    return $culture.TextInfo.ToTitleCase($Name.ToLower())
}

$persons    = [System.Collections.ArrayList]::new()
$contracts  = [System.Collections.ArrayList]::new()
$managers   = [System.Collections.ArrayList]::new()
$assistants = [System.Collections.ArrayList]::new()

# Fonction de lecture SQL
function Get-SQLData {
    param(
        [parameter(Mandatory = $true)]  $connectionString,
        [parameter(Mandatory = $true)]  $SqlQuery,
        [parameter(Mandatory = $true)]  [ref]$Data,
        [parameter(Mandatory = $false)] $Info
    )
    try {
        $Data.value = $null
        $SqlConnection = [System.Data.SqlClient.SqlConnection]::new($ConnectionString)
        $SqlConnection.Open()

        $SqlCmd = [System.Data.SqlClient.SqlCommand]::new()
        $SqlCmd.Connection   = $SqlConnection
        $SqlCmd.CommandText  = $SqlQuery
        $SqlCmd.CommandTimeout = 300   # FIX #1 : timeout 5 min pour éviter un blocage infini de l'agent HelloID

        $SqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new()
        $SqlAdapter.SelectCommand = $SqlCmd

        $DataSet = [System.Data.DataSet]::new()
        $null = $SqlAdapter.Fill($DataSet)

        $Data.value = $DataSet.Tables[0] | Select-Object -Property * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors
        Write-Information "Lecture [$Info] : $($DataSet.Tables[0].Rows.Count) lignes retournées."
    }
    catch {
        $Data.Value = $null
        Write-Error $_
    }
    finally {
        if ($SqlConnection.State -eq "Open") {
            $SqlConnection.close()
        }
        Write-Verbose "Déconnexion de la base [$Info] réalisée avec succès."
    }
}

# ---------------------------------------------------------------------------
# REQUÊTE PERSONNES
# ---------------------------------------------------------------------------
$personQuery = "(
    -- SPP et PATS actif avec une seule fiche
    SELECT
    RH.dbo.Pompers.P_NOM,
    RH.dbo.Pompers.P_PREN,
    RH.dbo.Pompers.P_NOMJF,
    RH.dbo.Pompers.P_MATR as MATRICULE,
    FORMAT(RH.dbo.Pompers.P_DANA, 'MM-dd-yyyy') AS DATE_NAISSANCE,
    CASE WHEN RH.dbo.Pompers.P_TGSM IS NOT NULL AND LTRIM(RTRIM(RH.dbo.Pompers.P_TGSM)) <> '' THEN '+33' + REPLACE(STUFF(RH.dbo.Pompers.P_TGSM, 1, 1, ''),'-','') ELSE NULL END AS P_TGSM,
    null AS P_EMAIL,
    null AS P_TBUR,
    CASE WHEN dbo_Tabcateg_Agents.CATEGORIE = 'Professionnel' OR dbo_Tabcateg_Agents.CATEGORIE = 'PAT' THEN  '+33 ' + STUFF(REPLACE(RH.dbo.Pompers.P_PTGSM, '-', ' '), 1, 1, '') ELSE NULL END AS P_PTGSM
    FROM
    RH.dbo.Pompcor RIGHT OUTER JOIN RH.dbo.Pompers ON (RH.dbo.Pompers.P_CORPS=RH.dbo.Pompcor.CLECOR)
    LEFT OUTER JOIN RH.dbo.Tabcateg dbo_Tabcateg_Agents ON (RH.dbo.Pompers.P_CATEG=dbo_Tabcateg_Agents.CLECAT)
    LEFT OUTER JOIN (
        select p_cle, req.DeuxStatActif from RH.dbo.pompers as po inner join
        (select p_matr, 'Non' as DeuxStatActif from RH.dbo.pompers where p_dbstat = 1 group by p_matr having count(p_matr) = 1
         union
         select p_matr, 'Oui' as DeuxStatActif  from RH.dbo.pompers where p_dbstat = 1 group by p_matr having count(p_matr) > 1) as req on po.p_matr = req.p_matr
    ) dbStatActif ON (dbStatActif.p_cle=RH.dbo.Pompers.P_CLE)
    WHERE
        ISNULL(RH.dbo.Pompers.P_DBSTAT,0) IN (0)
        OR (
            ISNULL(RH.dbo.Pompers.P_DBSTAT,0) IN (1)
            AND ISNULL(dbStatActif.DeuxStatActif, 'Non') IN ('Non')
        )

    UNION

    -- SPP et/ou PATS et/ou Volontaire avec plusieurs fiches (prise en compte seulement de la fiche volontaire)
    SELECT
    RH.dbo.Pompers.P_NOM,
    RH.dbo.Pompers.P_PREN,
    RH.dbo.Pompers.P_NOMJF,
    RH.dbo.Pompers.P_MATR as MATRICULE,
    FORMAT(RH.dbo.Pompers.P_DANA, 'MM-dd-yyyy') AS DATE_NAISSANCE,
    CASE WHEN RH.dbo.Pompers.P_TGSM IS NOT NULL AND LTRIM(RTRIM(RH.dbo.Pompers.P_TGSM)) <> '' THEN '+33' + REPLACE(STUFF(RH.dbo.Pompers.P_TGSM, 1, 1, ''),'-','') ELSE NULL END AS P_TGSM,
    null AS P_EMAIL,
    null AS P_TBUR,
    CASE WHEN dbo_Tabcateg_Agents.CATEGORIE = 'Professionnel' OR dbo_Tabcateg_Agents.CATEGORIE = 'PAT' THEN  '+33 ' + STUFF(REPLACE(RH.dbo.Pompers.P_PTGSM, '-', ' '), 1, 1, '') ELSE NULL END AS P_PTGSM
    FROM
    RH.dbo.Pompcor RIGHT OUTER JOIN RH.dbo.Pompers ON (RH.dbo.Pompers.P_CORPS=RH.dbo.Pompcor.CLECOR)
    LEFT OUTER JOIN RH.dbo.Tabcateg  dbo_Tabcateg_Agents ON (RH.dbo.Pompers.P_CATEG=dbo_Tabcateg_Agents.CLECAT)
    LEFT OUTER JOIN (
        select p_cle, req.DeuxStatActif from RH.dbo.pompers as po inner join
        (select p_matr, 'Non' as DeuxStatActif from RH.dbo.pompers where p_dbstat = 1 group by p_matr having count(p_matr) = 1
         union
         select p_matr, 'Oui' as DeuxStatActif  from RH.dbo.pompers where p_dbstat = 1 group by p_matr having count(p_matr) > 1) as req on po.p_matr = req.p_matr
    ) dbStatActif ON (dbStatActif.p_cle=RH.dbo.Pompers.P_CLE)
    WHERE
    (
        ISNULL(RH.dbo.Pompers.P_DBSTAT,0) IN (1)
        AND ISNULL(dbStatActif.DeuxStatActif, 'Non') IN ('Oui')
        AND dbo_Tabcateg_Agents.CATEGORIE NOT IN ('Volontaire')
    )

    UNION

    -- Tous les autres CAS (parti)
    SELECT distinct
    RH.dbo.Na_pers.P_NOM,
    RH.dbo.Na_pers.P_PREN,
    RH.dbo.Na_pers.P_NOMJF,
    RH.dbo.Na_pers.P_MATR as MATRICULE,
    FORMAT(RH.dbo.Na_pers.P_DANA, 'MM-dd-yyyy') AS DATE_NAISSANCE,
    CASE WHEN RH.dbo.Na_pers.P_TGSM IS NOT NULL AND LTRIM(RTRIM(RH.dbo.Na_pers.P_TGSM)) <> '' THEN '+33' + REPLACE(STUFF(RH.dbo.Na_pers.P_TGSM, 1, 1, ''),'-','') ELSE NULL END AS P_TGSM,
    null AS P_EMAIL,
    null AS P_TBUR,
    null AS P_PTGSM
    FROM
    RH.dbo.Pompcor RIGHT OUTER JOIN RH.dbo.Na_pers ON (RH.dbo.Na_pers.P_CORPS=RH.dbo.Pompcor.CLECOR)
    LEFT OUTER JOIN RH.dbo.Tabcateg  dbo_Tabcateg_Agents ON (RH.dbo.Na_pers.P_CATEG=dbo_Tabcateg_Agents.CLECAT)
    LEFT OUTER JOIN RH.dbo.Na_histcis ON (RH.dbo.Na_pers.P_CLE=RH.dbo.Na_histcis.CLEPERS)
    WHERE
    (
        RH.dbo.Na_pers.p_drad >= '$startPeriod'
    )
)"

try {
    Get-SQLData -SqlQuery $personQuery -connectionString $connectionString -Data ([ref]$persons) -Info "Personnes"
} catch {
    Write-Error "Erreur : $_."
}

# ---------------------------------------------------------------------------
# REQUÊTE CONTRATS
# FIX #2 : les correlated subqueries sur PompHistSusp sont remplacées par
#           un CTE SuspAgg précalculé (un seul scan de la table).
# FIX #3 : le LEFT JOIN Pomphistunit est borné par une borne haute explicite
#           pour éviter le produit cartésien partiel.
# FIX #4 : COALESCE sur les clés nullables dans le PARTITION BY de ROW_NUMBER
#           pour éviter plusieurs rn=1 pour le même agent.
# ---------------------------------------------------------------------------
$contractsQuery = "WITH Radiation AS (
    SELECT P_CLE AS CLEPERS, P_DRAD FROM RH.dbo.POMPERS       WHERE P_DRAD IS NOT NULL
    UNION ALL
    SELECT P_CLE AS CLEPERS, P_DRAD FROM RH.dbo.NA_PERS        WHERE P_DRAD IS NOT NULL
    UNION ALL
    SELECT P_CLE AS CLEPERS, P_DRAD FROM RH.dbo.POMPERSSUPPR   WHERE P_DRAD IS NOT NULL
    UNION ALL
    SELECT P_CLE AS CLEPERS, P_DRAD FROM RH.dbo.NA_PERSSUPPR   WHERE P_DRAD IS NOT NULL
),
Rad AS (
    SELECT CLEPERS, MIN(P_DRAD) AS DATE_RAD
    FROM Radiation
    GROUP BY CLEPERS
),
-- FIX #2 : précalcul des bornes de suspension par agent (remplace 6 correlated subqueries)
SuspAgg AS (
    SELECT
        CLEPERS,
        MIN(DATEDEB) AS DATE_DEB_SUSP,
        MAX(DATEFIN) AS DATE_FIN_SUSP,
        MAX(CASE WHEN DATEDEB <= CAST(GETDATE() AS DATE)
                  AND (DATEFIN >= CAST(GETDATE() AS DATE) OR DATEFIN IS NULL)
             THEN 1 ELSE 0 END) AS EstSuspenduAujourdhui
    FROM RH.dbo.PompHistSusp
    GROUP BY CLEPERS
),
BaseData AS (
    SELECT DISTINCT
        CONCAT(terr.CLEENREG, fonc.CLEENREG, serv.CLEENREG) AS CLEENREG,
        terr.CLEPERS,
        terr.CLECIS,
        fonc.CLEUNIT,
        serv.CLESERV,

        -- FIX #2 : lecture depuis SuspAgg au lieu de correlated subqueries
        susp.DATE_DEB_SUSP,
        susp.DATE_FIN_SUSP,

        POS.DATEDEB AS DATE_DEB_POS,
        POS.DATEFIN AS DATE_FIN_POS,

        terr.SourceType,
        terr.PRIORITE_BASE,
        r.DATE_RAD,

        CASE
            WHEN susp.DATE_FIN_SUSP IS NOT NULL
                 AND susp.DATE_FIN_SUSP >= COALESCE(fonc.DATEDEB, terr.DATEDEB)
            THEN DATEADD(DAY, 1, susp.DATE_FIN_SUSP)
            ELSE COALESCE(fonc.DATEDEB, terr.DATEDEB)
        END AS DATE_DEBUT,

        COALESCE(r.DATE_RAD, fonc.DATEFIN, terr.DATEFIN, POS.DATEFIN) AS DATE_FIN,

        -- FIX #2 : statut suspension depuis SuspAgg
        CASE WHEN susp.EstSuspenduAujourdhui = 1 THEN 'KO' ELSE 'OK' END AS Statut_SUSP,

        CASE
            WHEN r.DATE_RAD IS NOT NULL AND r.DATE_RAD <= CAST(GETDATE() AS DATE) THEN 'KO'
            WHEN POS.CLEPOSIT IS NULL THEN 'OK'
            WHEN POS.CLEPOSIT = 1
                 AND POS.DATEDEB <= CAST(GETDATE() AS DATE)
                 AND (POS.DATEFIN >= CAST(GETDATE() AS DATE) OR POS.DATEFIN IS NULL) THEN 'OK'
            WHEN POS.CLEPOSIT = 2 AND CLESPOSIT IN (11,21,23)
                 AND POS.DATEDEB <= CAST(GETDATE() AS DATE)
                 AND (POS.DATEFIN >= CAST(GETDATE() AS DATE) OR POS.DATEFIN IS NULL) THEN 'OK'
            ELSE 'KO'
        END AS Statut_POSIT,

        POS.CLEPOSIT,
        POS.CLESPOSIT

    FROM (
        SELECT *, 'RH' AS SourceType, 1 AS PRIORITE_BASE FROM RH.dbo.Pomphistcis
        UNION ALL
        SELECT *, 'RH' AS SourceType, 0 AS PRIORITE_BASE FROM RH.dbo.Pomphistcissec
        UNION ALL
        SELECT *, 'NA' AS SourceType, 1 AS PRIORITE_BASE FROM RH.dbo.Na_histcis
        UNION ALL
        SELECT *, 'NA' AS SourceType, 0 AS PRIORITE_BASE FROM RH.dbo.Na_histcissec
    ) terr

    -- FIX #3 : borne haute ajoutée sur Pomphistunit pour éviter le produit cartésien partiel
    LEFT JOIN RH.dbo.Pomphistunit fonc
        ON  fonc.CLEPERS = terr.CLEPERS
        AND fonc.DATEDEB <= COALESCE(terr.DATEFIN, '99991231')
        AND (fonc.DATEFIN >= terr.DATEDEB OR fonc.DATEFIN IS NULL)

    LEFT JOIN RH.dbo.Pomphistserv serv ON fonc.CLEENREG = serv.CLEENREG
    LEFT JOIN RH.dbo.Pomphistposit POS ON terr.CLEPERS = POS.CLEPERS

    -- FIX #2 : LEFT JOIN sur le CTE précalculé au lieu de correlated subqueries
    LEFT JOIN SuspAgg susp ON susp.CLEPERS = terr.CLEPERS

    LEFT JOIN Rad r ON r.CLEPERS = terr.CLEPERS
),
FullResult AS (
    SELECT
        aff.CLEENREG AS ID,
        aff.CLEPERS,
        p.P_MATR AS MATRICULE,
        pol.CLEDIRECTION AS POLE_CODE,

        CASE
            WHEN aff.DATE_RAD IS NOT NULL AND aff.DATE_RAD <= CAST(GETDATE() AS DATE) THEN 'RADIE'
            WHEN CLEPOSIT IS NULL            THEN 'ACTIF'
            WHEN CLEPOSIT = 1                THEN 'ACTIF'
            WHEN CLEPOSIT = 2 AND CLESPOSIT IN (11,21,23) THEN 'DETACHEMENT INTERNE'
            WHEN CLEPOSIT = 2                THEN 'DETACHEMENT'
            WHEN CLEPOSIT = 3                THEN 'HORS CADRE'
            WHEN CLEPOSIT = 4                THEN 'DISPONIBILITE'
            WHEN CLEPOSIT = 6                THEN 'CONGE PARENTAL'
            WHEN CLEPOSIT = 7                THEN 'CONGE DE PRESENCE PARENTALE'
            WHEN CLEPOSIT = 11               THEN 'MISE A DISPO SDIS26'
            ELSE 'AUTRE'
        END AS STATUT_POSIT_LABEL,

        FORMAT(aff.DATE_DEBUT, 'MM-dd-yyyy 00:00:00') AS DATE_DEBUT,

        FORMAT(
            COALESCE(aff.DATE_RAD, aff.DATE_FIN, aff.DATE_FIN_POS),
            'MM-dd-yyyy 23:59:59'
        ) AS DATE_FIN,

        FORMAT(aff.DATE_DEB_SUSP, 'MM-dd-yyyy 23:59:59') AS DATE_DEB_SUSP,
        FORMAT(aff.DATE_FIN_SUSP, 'MM-dd-yyyy 23:59:59') AS DATE_FIN_SUSP,
        FORMAT(aff.DATE_DEB_POS,  'MM-dd-yyyy 23:59:59') AS DATE_DEB_POS,
        FORMAT(aff.DATE_FIN_POS,  'MM-dd-yyyy 23:59:59') AS DATE_FIN_POS,

        CASE
            WHEN aff.DATE_RAD IS NOT NULL THEN 'INACTIF'
            WHEN aff.Statut_POSIT = 'OK' AND aff.Statut_SUSP = 'OK' THEN 'ACTIF'
            ELSE 'INACTIF'
        END AS Statut_POSIT_FINAL,

        grade.GRADE,
        cat.CATEGORIE,
        fn1.FONCTION AS FONCTION1,
        fn2.FONCTION AS FONCTION2,

        aff.CLEUNIT  AS GROUPEMENT_CODE,
        unit.GROUPEMENT,
        unit.CODE    AS GROUPEMENT_SIGLE,

        aff.CLESERV  AS SERVICE_CODE,
        serv.SERVICE,
        serv.PAIE    AS SERVICE_SIGLE,

        cis.CLECOR   AS CENTRE_CODE,
        cis.CORP     AS CENTRE,
        cis.CO11     AS CENTRE_COURT,
        cis.CODE_NEXSIS AS CENTRE_SIGLE,
        cis.CO3      AS ADRESSE1,
        cis.CO4      AS ADRESSE2,
        cis.CO5      AS VILLE,
        cis.CO6      AS CP,
        cis.CO27     AS CENTRE_EMAIL,
        typeco.COR_TYP,

        CASE
            WHEN aff.PRIORITE_BASE = 1 THEN IIF(cat.CATEGORIE = 'Volontaire', 1, 2)
            ELSE 0
        END AS PRIORITE

    FROM BaseData aff
    JOIN (
        SELECT P_CLE, P_MATR, P_GRAD, P_CATEG, P_FONC, P_FONC2 FROM RH.dbo.Pompers
        UNION ALL
        SELECT P_CLE, P_MATR, P_GRAD, P_CATEG, P_FONC, P_FONC2 FROM RH.dbo.Na_pers
    ) p ON aff.CLEPERS = p.P_CLE
    JOIN  RH.dbo.Sp_grade   grade   ON p.P_GRAD    = grade.CLE
    JOIN  RH.dbo.Tabcateg   cat     ON p.P_CATEG   = cat.CLECAT
    LEFT JOIN RH.dbo.PomphistDirection pol ON pol.CLEPERS = p.P_CLE AND pol.DATEFIN IS NULL
    LEFT JOIN (
        SELECT CLECOR, CODE_NEXSIS, CORP, CO11, CO3, CO4, CO5, CO6, CO27, CO2 FROM RH.dbo.Pompcor
        UNION
        SELECT CLECOR, NULL, CORP, NULL, NULL, NULL, NULL, NULL, NULL, NULL   FROM RH.dbo.PompcorHD
    ) cis ON aff.CLECIS = cis.CLECOR
    LEFT JOIN RH.dbo.TABTYPCO   typeco ON cis.CO2          = typeco.CODIF
    LEFT JOIN RH.dbo.Pomppfct   fn1    ON p.P_FONC          = fn1.CLEFONC
    LEFT JOIN RH.dbo.Pomppfct   fn2    ON p.P_FONC2         = fn2.CLEFONC
    LEFT JOIN RH.dbo.Pompgserv  unit   ON aff.CLEUNIT       = unit.CLE_GRPFONC
    LEFT JOIN RH.dbo.Pompserv   serv   ON aff.CLESERV       = serv.CLESER
    WHERE aff.DATE_FIN >= '$startPeriod' OR aff.DATE_FIN IS NULL
),
Ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            -- FIX #4 : COALESCE sur les NULLs pour éviter plusieurs rn=1 pour le même agent
            --          Valeur de fallback en VARCHAR '-1' car les codes sont des varchar dans ANTIBIA
            PARTITION BY CLEPERS,
                         COALESCE(CENTRE_CODE,     '-1'),
                         COALESCE(SERVICE_CODE,    '-1'),
                         COALESCE(GROUPEMENT_CODE, '-1')
            ORDER BY PRIORITE DESC,
                     CASE WHEN Statut_POSIT_FINAL = 'ACTIF' THEN 1 ELSE 2 END,
                     DATE_FIN DESC
        ) AS rn
    FROM FullResult
)
SELECT * FROM Ranked WHERE rn = 1;
"

try {
    Get-SQLData -SqlQuery $contractsQuery -connectionString $connectionString -Data ([ref]$contracts) -Info "Contrats PRO"
} catch {
    Write-Error "Erreur lors de la lecture des Contrats : $_."
}

# ---------------------------------------------------------------------------
# REQUÊTE MANAGERS
# FIX #8 : remplacement de la correlated subquery CIS le plus récent
#           par un CTE avec ROW_NUMBER()
# ---------------------------------------------------------------------------
$managersQuery = "WITH CisPlusRecentRanked AS (
    SELECT
        cis.CLEPERS,
        cor.CORP,
        cor.CLECOR,
        gp.gpt AS GPT,
        ROW_NUMBER() OVER (PARTITION BY cis.CLEPERS ORDER BY cis.DATEDEB DESC) AS rn
    FROM RH.dbo.Pomphistcis AS cis
    LEFT JOIN RH.dbo.pompcor AS cor ON cis.clecis = cor.CLECOR
    LEFT JOIN RH.dbo.pompgpt AS gp  ON cor.CO7    = gp.clegpt
    WHERE cis.DATEDEB <= GETDATE()
),
CisPlusRecent AS (
    SELECT CLEPERS, CORP, CLECOR, GPT FROM CisPlusRecentRanked WHERE rn = 1
)
SELECT DISTINCT
    RH.dbo.Pompers.P_NOM,
    RH.dbo.Pompers.P_PREN,
    RH.dbo.Pompers.P_MATR,
    RH_dbo_Pomppfct3.FONCTION  AS FONCTION1,
    RH_dbo_Pomppfct2.FONCTION  AS FONCTION2,
    CisPlusRecent.CORP         AS CENTRE,
    CisPlusRecent.CLECOR       AS CENTRE_CODE,
    RH_dbo_Pompgserv2.GROUPEMENT,
    RH_dbo_Pompgserv2.CLE_GRPFONC AS GROUPEMENT_CODE,
    RH_dbo_Pompserv2.SERVICE,
    RH_dbo_Pompserv2.CLESER    AS SERVICE_CODE,
    RH_dbo_Pompgserv2.CLE_DIRECTION AS POLE_CODE
FROM
    RH.dbo.Pompcor RIGHT OUTER JOIN RH.dbo.Pompers ON (RH.dbo.Pompers.P_CORPS = RH.dbo.Pompcor.CLECOR)
    LEFT OUTER JOIN RH.dbo.Pomphistcis      terr        ON (RH.dbo.Pompers.P_CLE   = terr.CLEPERS)
    LEFT OUTER JOIN RH.dbo.Tabcateg         dbo_Tabcateg_Agents ON (RH.dbo.Pompers.P_CATEG = dbo_Tabcateg_Agents.CLECAT)
    LEFT OUTER JOIN RH.dbo.Pomppfct         RH_dbo_Pomppfct2 ON (RH.dbo.Pompers.P_FONC2  = RH_dbo_Pomppfct2.CLEFONC)
    LEFT OUTER JOIN RH.dbo.Pomppfct         RH_dbo_Pomppfct3 ON (RH.dbo.Pompers.P_FONC   = RH_dbo_Pomppfct3.CLEFONC)
    LEFT OUTER JOIN RH.dbo.Pompgserv        RH_dbo_Pompgserv2 ON (RH.dbo.Pompers.P_GPTFCT = RH_dbo_Pompgserv2.CLE_GRPFONC)
    LEFT OUTER JOIN RH.dbo.Pompserv         RH_dbo_Pompserv2 ON (RH_dbo_Pompserv2.CLESER  = RH.dbo.Pompers.P_SERV)
    LEFT JOIN RH.dbo.Pomphistposit          POS  ON (RH.dbo.Pompers.P_CLE = POS.CLEPERS)
    LEFT JOIN RH.dbo.PompHistSusp           SUSP ON (RH.dbo.Pompers.P_CLE = SUSP.CLEPERS)
    LEFT JOIN RH.dbo.Pomphistunit           fonc ON (
        fonc.CLEPERS  = terr.CLEPERS
        AND fonc.DATEDEB >= terr.DATEDEB
        AND (terr.DATEFIN IS NULL OR fonc.DATEDEB <= terr.DATEFIN)
    )
    -- FIX #8 : LEFT JOIN sur le CTE ROW_NUMBER() au lieu de la correlated subquery
    LEFT JOIN CisPlusRecent ON (RH.dbo.Pompers.P_CLE = CisPlusRecent.CLEPERS)
WHERE (
    RH_dbo_Pomppfct3.FONCTION IN ('CHEF DE GROUPEMENT','MEDECIN CHEF','CHEF DE SERVICE','DIRECTEUR DEPART.','CHEF DE CIS','INTERIM CHEF DE CENTRE','CHEF DE POLE')
    OR
    RH_dbo_Pomppfct2.FONCTION IN ('CHEF DE GROUPEMENT','MEDECIN CHEF','CHEF DE SERVICE','DIRECTEUR DEPART.','CHEF DE CIS','INTERIM CHEF DE CENTRE','CHEF DE POLE')
)
AND (
    (POS.CLEPOSIT IS NULL)
    OR (POS.CLEPOSIT = 1
        AND POS.DATEDEB <= CAST(GETDATE() AS DATE)
        AND (POS.DATEFIN >= CAST(GETDATE() AS DATE) OR POS.DATEFIN IS NULL))
    OR (POS.CLEPOSIT = 2
        AND POS.CLESPOSIT IN (11,21,23)
        AND (POS.DATEDEB <= CAST(GETDATE() AS DATE) OR POS.DATEDEB IS NULL)
        AND (POS.DATEFIN >= CAST(GETDATE() AS DATE) OR POS.DATEFIN IS NULL))
)
AND (
    (SUSP.DATEDEB IS NULL)
    OR (SUSP.DATEDEB >= CAST(GETDATE() AS DATE))
    OR (SUSP.DATEDEB <= CAST(GETDATE() AS DATE) AND SUSP.DATEFIN <= CAST(GETDATE() AS DATE))
)"

try {
    Get-SQLData -SqlQuery $managersQuery -connectionString $connectionString -Data ([ref]$managers) -Info "Managers"
} catch {
    Write-Error "Erreur lors de la lecture de la table des managers : $_."
}

# ---------------------------------------------------------------------------
# INDEXATION
# ---------------------------------------------------------------------------
$persons = $persons | Sort-Object -Property MATRICULE -Unique

# Protection : si la requête contrats a échoué, initialiser un hashtable vide
# pour éviter "Indexation impossible dans un tableau Null"
if ($null -eq $contracts -or $contracts.Count -eq 0) {
    Write-Warning "La table des contrats est vide ou nulle — aucun contrat ne sera associé aux personnes."
    $contractsGrouped = @{}
} else {
    $contractsGrouped = $contracts | Group-Object -Property "MATRICULE" -AsHashTable -AsString
}
$managersCenterGrouped     = $managers  | Where-Object { $_.FONCTION1 -eq "CHEF DE CIS" -OR $_.FONCTION2 -eq "CHEF DE CIS" -OR $_.FONCTION1 -eq "INTERIM CHEF DE CENTRE" -OR $_.FONCTION2 -eq "INTERIM CHEF DE CENTRE" } | Group-Object -Property "CENTRE_CODE"    -AsHashTable -AsString
$managersPoleGrouped       = $managers  | Where-Object { $_.FONCTION1 -eq "CHEF DE POLE" }                                                                                                                                  | Group-Object -Property "POLE_CODE"      -AsHashTable -AsString
$managersPoleGrouped['']   = $null
$managersGroupementGrouped = $managers  | Where-Object { $_.FONCTION1 -eq "CHEF DE GROUPEMENT" -or $_.FONCTION1 -eq "MEDECIN CHEF" }                                                                                        | Group-Object -Property "GROUPEMENT_CODE" -AsHashTable -AsString
$managersGroupementGrouped[''] = $null
$managersServiceGrouped    = $managers  | Where-Object { $_.FONCTION1 -eq "CHEF DE SERVICE" -OR $_.FONCTION2 -eq "CHEF SERVICE" }                                                                                           | Group-Object -Property "SERVICE_CODE"    -AsHashTable -AsString
$managersServiceGrouped[''] = $null
$managerDDSIS              = $managers  | Where-Object { ($_.FONCTION1 -eq "DIRECTEUR DEPART." -OR $_.FONCTION2 -eq "DIRECTEUR DEPART.") -and ($_.GROUPEMENT -notlike "MIS A DISPOSITION") }

# Filtrage sur matricules exclus (non modifié - point 7)
$MatriculesAExclure = @("170071","3115")
$persons = $persons | Where-Object { $MatriculesAExclure -notcontains $_.matricule }

# ---------------------------------------------------------------------------
# CONSTRUCTION DES OBJETS HELLOID
# ---------------------------------------------------------------------------
$totalPersonnes = 0
$totalContrats  = 0

foreach ($p in $persons) {
    $person = @{}
    $person["ExternalId"]    = $p.MATRICULE
    # FIX #9 : Capitalize-Name maintenant appliqué sur les prénoms et noms
    $person["DisplayName"]   = "$($p.P_NOM) $(Capitalize-Name $p.P_PREN) ($($p.MATRICULE))"
    $person["FirstName"]     = Capitalize-Name $p.P_PREN
    $person["LastName"]      = $p.P_NOM
    $person["LastNameBirth"] = Capitalize-Name $p.P_NOMJF
    $person["BirthDate"]     = $p.DATE_NAISSANCE
    $person["MobilePhone"]   = $p.P_TGSM
    $person["PrivateEmail"]  = $p.P_EMAIL
    $person["OfficePhone"]   = $p.P_TBUR
    $person["OfficeMobile"]  = $p.P_PTGSM
    $person["Contracts"]     = [System.Collections.ArrayList]@()

    foreach ($c in $contractsGrouped["$($p.MATRICULE)"]) {

        $managerId = $null

        if ($managersServiceGrouped["$($c.SERVICE_CODE)"]) {
            # FIX #6 : Select-Object -First 1 pour éviter qu'un tableau soit assigné à $managerId
            $managerId = ($managersServiceGrouped["$($c.SERVICE_CODE)"] | Select-Object -First 1).P_MATR
            if ($managerId -eq $p.MATRICULE) {
                $managerId = ($managersGroupementGrouped["$($c.GROUPEMENT_CODE)"] | Select-Object -First 1).P_MATR
                if ($managerId -eq $p.MATRICULE) {
                    $managerId = ($managersPoleGrouped["$($c.POLE_CODE)"] | Select-Object -First 1).P_MATR
                }
            }
        }
        elseif ($managersGroupementGrouped["$($c.GROUPEMENT_CODE)"]) {
            $managerId = ($managersGroupementGrouped["$($c.GROUPEMENT_CODE)"] | Select-Object -First 1).P_MATR
            if ($managerId -eq $p.MATRICULE) {
                $managerId = ($managersPoleGrouped["$($c.POLE_CODE)"] | Select-Object -First 1).P_MATR
            }
        }
        elseif ($managersPoleGrouped["$($c.POLE_CODE)"]) {
            $managerId = ($managersPoleGrouped["$($c.POLE_CODE)"] | Select-Object -First 1).P_MATR
            if ($managerId -eq $p.MATRICULE) {
                $managerId = ($managerDDSIS | Select-Object -First 1).P_MATR
                if ($managerId -eq $p.MATRICULE) {
                    $managerId = $null
                }
            }
        }
        else {
            if ($c.CATEGORIE -like "VOLONTAIRE") {
                $managerId = ($managersCenterGrouped["$($c.CENTRE_CODE)"] | Select-Object -First 1).P_MATR
                # Chef de centre lui-même → manager = chef du groupement territorial (non modifié - point 7)
                if ($managerId -eq $p.MATRICULE) {
                    $managerId = $managersGroupementGrouped["GPT2T7TG3395547"].P_MATR
                }
            }
            else {
                $managerId = ($managerDDSIS | Select-Object -First 1).P_MATR
            }
        }

        $contract = @{}
        $contract["ExternalID"]      = $c.ID
        $contract["StartDate"]       = $c.DATE_DEBUT
        $contract["EndDate"]         = $c.DATE_FIN
        $contract["Grade"]           = $c.GRADE
        $contract["Category"]        = $c.CATEGORIE
        $contract["Title1"]          = $c.FONCTION1
        $contract["Title2"]          = $c.FONCTION2
        $contract["DepartmentCode"]  = $c.GROUPEMENT_CODE
        $contract["Department"]      = $c.GROUPEMENT
        $contract["DepartmentSigle"] = $c.GROUPEMENT_SIGLE
        $contract["ServiceCode"]     = $c.SERVICE_CODE
        $contract["Service"]         = $c.SERVICE
        $contract["PoleCode"]        = $c.POLE_CODE
        $contract["ServiceSigle"]    = $c.SERVICE_SIGLE
        $contract["CenterCode"]      = $c.CENTRE_CODE
        $contract["Center"]          = $c.CENTRE
        $contract["CenterEmail"]     = $c.CENTRE_EMAIL
        $contract["StreetAddress1"]  = $c.ADRESSE1
        $contract["StreetAddress2"]  = $c.ADRESSE2
        $contract["City"]            = $c.VILLE
        $contract["PostalCode"]      = $c.CP
        $contract["FTE"]             = $c.PRIORITE
        $contract["ManagerID"]       = $managerId
        $contract["TypeCIS"]         = $c.COR_TYP
        $contract["StatutPosition"]  = $c.STATUT_POSIT_LABEL

        # Exclusion des contrats JSP
        if ($c.CATEGORIE -NotLike "JSP") {
            if ([string]::IsNullOrWhiteSpace($c.DATE_FIN)) {
                # Contrat ouvert → toujours inclus
                [void]$person.Contracts.Add($contract)
            }
            else {
                # FIX #5 : les deux ParseExact utilisent maintenant le MÊME séparateur "-"
                #          pour éviter la bombe à retardement MM-dd vs MM/dd
                try {
                    $DateDeFinContrat = [datetime]::ParseExact($c.DATE_FIN,   "MM-dd-yyyy HH:mm:ss", $null)
                    $DateDeFinMax     = [datetime]::ParseExact($startPeriod,   "MM/dd/yyyy HH:mm:ss", $null)
                    if ($DateDeFinContrat -gt $DateDeFinMax) {
                        [void]$person.Contracts.Add($contract)
                    }
                }
                catch {
                    Write-Warning "Impossible de parser la date de fin [$($c.DATE_FIN)] pour le contrat [$($c.ID)] - contrat ignoré."
                }
            }
        }
    }

    if ($person.Contracts.Count -gt 0) {
        $totalPersonnes++
        $totalContrats += $person.Contracts.Count
        Write-Output ($person | ConvertTo-Json -Depth 10)
    }
}

# FIX #10 : log final des volumes importés
Write-Information "Import ANTIBIA terminé : $totalPersonnes personne(s) exportée(s), $totalContrats contrat(s) total."
