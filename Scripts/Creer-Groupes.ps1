param(
    [switch]$CreationReelle
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

$FichierCSV = "C:\Projet-AD\CSV\Groupes.csv"
$FichierLog = "C:\Projet-AD\Logs\Creation-Groupes.log"
$DomaineDN = (Get-ADDomain).DistinguishedName

New-Item -Path (Split-Path $FichierLog) `
    -ItemType Directory -Force | Out-Null

function Ecrire-Log {
    param([string]$Message)

    $Ligne = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $FichierLog -Value $Ligne -Encoding UTF8
    Write-Host $Ligne
}

if (-not (Test-Path $FichierCSV)) {
    throw "Fichier CSV introuvable : $FichierCSV"
}

$Groupes = @(Import-Csv -Path $FichierCSV -Delimiter ";" -ErrorAction Stop)

if ($Groupes.Count -eq 0) {
    throw "Le fichier CSV est vide."
}

$Colonnes = @($Groupes[0].PSObject.Properties.Name)

foreach ($Colonne in @("NomGroupe", "Categorie", "Portee", "OU")) {
    if ($Colonnes -notcontains $Colonne) {
        throw "Colonne manquante dans le CSV : $Colonne"
    }
}

$NomsVus = @{}

foreach ($Groupe in $Groupes) {
    foreach ($Champ in @("NomGroupe", "Categorie", "Portee", "OU")) {
        if ([string]::IsNullOrWhiteSpace($Groupe.$Champ)) {
            throw "Champ $Champ vide dans le CSV."
        }
    }

    $Nom = $Groupe.NomGroupe.Trim()

    if ($NomsVus.ContainsKey($Nom)) {
        throw "Groupe en double dans le CSV : $Nom"
    }

    $NomsVus[$Nom] = $true

    if ($Groupe.Categorie.Trim() -notin @("Security", "Distribution")) {
        throw "Categorie invalide pour $Nom."
    }

    if ($Groupe.Portee.Trim() -notin @("Global", "DomainLocal", "Universal")) {
        throw "Portee invalide pour $Nom."
    }

    $Parent = $Groupe.OU.Trim()

    if (-not $Parent.EndsWith(
        $DomaineDN,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "OU hors du domaine pour $Nom."
    }
}

foreach ($Groupe in $Groupes) {
    $Nom = $Groupe.NomGroupe.Trim()
    $Parent = $Groupe.OU.Trim()

    try {
        Get-ADOrganizationalUnit -Identity $Parent `
            -ErrorAction Stop | Out-Null
    }
    catch {
        Ecrire-Log "ERREUR : OU introuvable pour $Nom : $Parent"
        continue
    }

    $NomFiltre = $Nom.Replace("'", "''")

    $Existant = @(
        Get-ADGroup `
            -Filter "Name -eq '$NomFiltre'" `
            -SearchBase $DomaineDN `
            -SearchScope Subtree `
            -ErrorAction Stop
    )

    if ($Existant.Count -gt 0) {
        Ecrire-Log "EXISTANT : $Nom. Aucune modification."
        continue
    }

    if (-not $CreationReelle) {
        Ecrire-Log "SIMULATION : creation du groupe $Nom dans $Parent"
        continue
    }

    try {
        New-ADGroup `
            -Name $Nom `
            -SamAccountName $Nom `
            -GroupCategory $Groupe.Categorie.Trim() `
            -GroupScope $Groupe.Portee.Trim() `
            -Path $Parent `
            -ErrorAction Stop

        Ecrire-Log "CREE : $Nom dans $Parent"
    }
    catch {
        Ecrire-Log "ECHEC pour $Nom : $($_.Exception.Message)"
    }
}