# Initialisation des variables
$config = ($configuration | convertfrom-json)
$server = $config.server
$database = $config.database
$Port = $config.Port
$connectionString = "Server=$server,$Port;Database=$database;Trusted_Connection=True;"

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
        $SqlCmd.Connection     = $SqlConnection
        $SqlCmd.CommandText    = $SqlQuery
        $SqlCmd.CommandTimeout = 300

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
        if ($SqlConnection.State -eq "Open") { $SqlConnection.close() }
        Write-Verbose "Déconnexion de la base [$Info] réalisée avec succès."
    }
}

$departments = $null

# ---------------------------------------------------------------------------
# REQUÊTE DÉPARTEMENTS (Centres, Groupements, Services, Pôles)
# ---------------------------------------------------------------------------
$departmentsQuery = "SELECT DISTINCT
    -- CENTRES (CIS)
    cor.CLECOR      AS ExternalId,
    cor.CORP        AS DisplayName,
    cor.CO11        AS ShortName,
    cor.CODE_NEXSIS AS Code,
    cor.CO3         AS StreetAddress1,
    cor.CO4         AS StreetAddress2,
    cor.CO5         AS City,
    cor.CO6         AS PostalCode,
    cor.CO27        AS Email,
    typ.COR_TYP     AS Type,
    NULL            AS ParentExternalId,
    'Centre'        AS Level
FROM RH.dbo.Pompcor cor
LEFT JOIN RH.dbo.TABTYPCO typ ON cor.CO2 = typ.CODIF
WHERE cor.CLECOR IS NOT NULL

UNION

-- GROUPEMENTS FONCTIONNELS
SELECT DISTINCT
    CAST(grp.CLE_GRPFONC AS VARCHAR) AS ExternalId,
    grp.GROUPEMENT                   AS DisplayName,
    grp.CODE                         AS ShortName,
    grp.CODE                         AS Code,
    NULL AS StreetAddress1,
    NULL AS StreetAddress2,
    NULL AS City,
    NULL AS PostalCode,
    NULL AS Email,
    'Groupement'                     AS Type,
    NULL                             AS ParentExternalId,
    'Groupement'                     AS Level
FROM RH.dbo.Pompgserv grp
WHERE grp.CLE_GRPFONC IS NOT NULL

UNION

-- SERVICES
SELECT DISTINCT
    CAST(ser.CLESER AS VARCHAR) AS ExternalId,
    ser.SERVICE                 AS DisplayName,
    ser.PAIE                    AS ShortName,
    ser.PAIE                    AS Code,
    NULL AS StreetAddress1,
    NULL AS StreetAddress2,
    NULL AS City,
    NULL AS PostalCode,
    NULL AS Email,
    'Service'                   AS Type,
    NULL                        AS ParentExternalId,
    'Service'                   AS Level
FROM RH.dbo.Pompserv ser
WHERE ser.CLESER IS NOT NULL
"

try {
    Get-SQLData -SqlQuery $departmentsQuery -connectionString $connectionString -Data ([ref]$departments) -Info "Departments"
} catch {
    Write-Error "Erreur lors de la lecture des départements : $_."
}

if ($null -ne $departments) {
    foreach ($d in $departments) {
        $department = @{}
        $department["ExternalId"]       = $d.ExternalId
        $department["DisplayName"]      = $d.DisplayName
        $department["ShortName"]        = $d.ShortName
        $department["Code"]             = $d.Code
        $department["Type"]             = $d.Type
        $department["Level"]            = $d.Level
        $department["StreetAddress1"]   = $d.StreetAddress1
        $department["StreetAddress2"]   = $d.StreetAddress2
        $department["City"]             = $d.City
        $department["PostalCode"]       = $d.PostalCode
        $department["Email"]            = $d.Email
        $department["ParentExternalId"] = $d.ParentExternalId

        Write-Output ($department | ConvertTo-Json -Depth 10)
    }
    Write-Information "Export Departments terminé : $($departments.Count) département(s) exporté(s)."
}
