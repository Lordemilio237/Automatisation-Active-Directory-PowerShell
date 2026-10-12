param(
    [switch]$CreationReelle
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

$FichierCSV = "C:\Projet-AD\CSV\OU.csv"
$FichierLog = "C:\Projet-AD\Logs\Creation-OU.log"
$DomaineDN = (Get-ADDomain).DistinguishedName

# Préparer le dossier des journaux
New-Item -Path (Split-Path $FichierLog) `
    -ItemType Directory -Force | Out-Null

function Ecrire-Log {
    param([string]$Message)

    $Ligne = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $FichierLog -Value $Ligne -Encoding UTF8
    Write-Host $Ligne
}

# Vérifier la présence du CSV
if (-not (Test-Path $FichierCSV)) {
    throw "Fichier CSV introuvable : $FichierCSV"
}

$Unites = @(Import-Csv -Path $FichierCSV -Delimiter ";")

if ($Unites.Count -eq 0) {
    throw "Le fichier CSV est vide."
}

# Vérifier les colonnes
$Colonnes = @($Unites[0].PSObject.Properties.Name)

if ($Colonnes -notcontains "NomOU" -or
    $Colonnes -notcontains "CheminParent") {
    throw "Colonnes requises : NomOU et CheminParent."
}

# Vérifier les données et les doublons
$NomsComplets = @{}

foreach ($OU in $Unites) {
    $Nom = $OU.NomOU.Trim()
    $Parent = $OU.CheminParent.Trim()

    if ([string]::IsNullOrWhiteSpace($Nom) -or
        [string]::IsNullOrWhiteSpace($Parent)) {
        throw "Une ligne contient un champ vide."
    }

    $Cle = "OU=$Nom,$Parent"

    if ($NomsComplets.ContainsKey($Cle)) {
        throw "OU en double dans le CSV : $Cle"
    }

    $NomsComplets[$Cle] = $true

    if (-not $Parent.EndsWith(
        $DomaineDN,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Le parent est hors du domaine : $Parent"
    }
}

# Traiter les OU dans l'ordre du CSV
foreach ($OU in $Unites) {
    $Nom = $OU.NomOU.Trim()
    $Parent = $OU.CheminParent.Trim()
    $DN = "OU=$Nom,$Parent"

    # Vérifier que le parent existe
    try {
        Get-ADObject -Identity $Parent -ErrorAction Stop |
            Out-Null
    }
    catch {
        Ecrire-Log "ERREUR : parent introuvable pour $Nom : $Parent"
        continue
    }

    # Vérifier si l'OU existe déjà à cet emplacement
    $NomFiltre = $Nom.Replace("'", "''")

    $Existante = @(
        Get-ADOrganizationalUnit `
            -Filter "Name -eq '$NomFiltre'" `
            -SearchBase $Parent `
            -SearchScope OneLevel `
            -ErrorAction Stop
    )

    if ($Existante.Count -gt 0) {
        Ecrire-Log "EXISTANTE : $DN"
        continue
    }

    if (-not $CreationReelle) {
        Ecrire-Log "SIMULATION : création de $DN"
        continue
    }

    try {
        New-ADOrganizationalUnit `
            -Name $Nom `
            -Path $Parent `
            -ErrorAction Stop

        Ecrire-Log "CREEE : $DN"
    }
    catch {
        Ecrire-Log "ECHEC pour $DN : $($_.Exception.Message)"
    }
}