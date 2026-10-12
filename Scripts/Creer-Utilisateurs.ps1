param(
    [switch]$CreationReelle
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory -ErrorAction Stop

$FichierCSV = "C:\Projet-AD\CSV\Utilisateurs.csv"
$FichierLog = "C:\Projet-AD\Logs\Creation-Utilisateurs.log"
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

$Utilisateurs = @(
    Import-Csv -Path $FichierCSV -Delimiter ";" -ErrorAction Stop
)

if ($Utilisateurs.Count -eq 0) {
    throw "Le fichier CSV est vide."
}

$Colonnes = @($Utilisateurs[0].PSObject.Properties.Name)

foreach ($Colonne in @(
    "Prenom", "Nom", "SamAccountName",
    "UserPrincipalName", "OU", "Groupe", "MotDePasse"
)) {
    if ($Colonnes -notcontains $Colonne) {
        throw "Colonne manquante dans le CSV : $Colonne"
    }
}

# Valider les champs et les doublons avant tout traitement
$IdentifiantsVus = @{}
$UPNVus = @{}

foreach ($Utilisateur in $Utilisateurs) {
    foreach ($Champ in @(
        "Prenom", "Nom", "SamAccountName",
        "UserPrincipalName", "OU", "Groupe", "MotDePasse"
    )) {
        if ([string]::IsNullOrWhiteSpace($Utilisateur.$Champ)) {
            throw "Champ $Champ vide dans le CSV."
        }
    }

    $Sam = $Utilisateur.SamAccountName.Trim()
    $UPN = $Utilisateur.UserPrincipalName.Trim()

    if ($IdentifiantsVus.ContainsKey($Sam)) {
        throw "SamAccountName en double : $Sam"
    }

    if ($UPNVus.ContainsKey($UPN)) {
        throw "UPN en double : $UPN"
    }

    $IdentifiantsVus[$Sam] = $true
    $UPNVus[$UPN] = $true

    if ($Sam.Length -gt 20) {
        throw "SamAccountName trop long : $Sam"
    }

    if ($Sam -match '[\\\/\[\]:;|=,+*?<>"]') {
        throw "SamAccountName contient des caractères interdits : $Sam"
    }
}

foreach ($Utilisateur in $Utilisateurs) {
    $Sam = $Utilisateur.SamAccountName.Trim()
    $UPN = $Utilisateur.UserPrincipalName.Trim()
    $NomFiltre = $Sam.Replace("'", "''")
    $UPNFiltre = $UPN.Replace("'", "''")
    $Parent = $Utilisateur.OU.Trim()
    $NomGroupe = $Utilisateur.Groupe.Trim()

    # Vérifier l'OU cible
    try {
        Get-ADOrganizationalUnit -Identity $Parent `
            -ErrorAction Stop | Out-Null
    }
    catch {
        Ecrire-Log "ERREUR : OU introuvable pour $Sam."
        continue
    }

    # Vérifier le groupe cible
    try {
        $Groupe = Get-ADGroup -Identity $NomGroupe `
            -ErrorAction Stop
    }
    catch {
        Ecrire-Log "ERREUR : groupe introuvable pour $Sam."
        continue
    }

    # Vérifier le SamAccountName dans le domaine
    $Existant = @(
        Get-ADUser -Filter "SamAccountName -eq '$NomFiltre'" `
            -ErrorAction Stop
    )

    if ($Existant.Count -gt 0) {
        Ecrire-Log "EXISTANT : $Sam. Aucune modification."
        continue
    }

    # Vérifier l'UPN dans le domaine
    $ExistantUPN = @(
        Get-ADUser -Filter "UserPrincipalName -eq '$UPNFiltre'" `
            -ErrorAction Stop
    )

    if ($ExistantUPN.Count -gt 0) {
        Ecrire-Log "ERREUR : UPN déjà utilisé pour $Sam."
        continue
    }

    # Vérifier le mot de passe sans l'écrire dans le journal
    try {
        $MotDePasseSecurise = ConvertTo-SecureString `
            $Utilisateur.MotDePasse -AsPlainText -Force

        $Parametres = @{
            Name                  = "$($Utilisateur.Prenom) $($Utilisateur.Nom)"
            GivenName             = $Utilisateur.Prenom
            Surname               = $Utilisateur.Nom
            SamAccountName        = $Sam
            UserPrincipalName     = $UPN
            Path                  = $Parent
            AccountPassword       = $MotDePasseSecurise
            Enabled               = $true
            ChangePasswordAtLogon = $true
            ErrorAction           = "Stop"
        }

        if (-not $CreationReelle) {
            Ecrire-Log "SIMULATION : création de $Sam dans $Parent"
            Ecrire-Log "SIMULATION : ajout de $Sam au groupe $NomGroupe"
            continue
        }

        # Créer le compte puis l'ajouter au groupe
        New-ADUser @Parametres

        try {
            Add-ADGroupMember -Identity $Groupe `
                -Members $Sam -ErrorAction Stop

            Ecrire-Log "CREE ET AJOUTE AU GROUPE : $Sam -> $NomGroupe"
        }
        catch {
            Ecrire-Log "COMPTE CREE, MAIS AJOUT AU GROUPE EN ECHEC pour $Sam : $($_.Exception.Message)"
        }
    }
    catch {
        Ecrire-Log "ECHEC pour $Sam : $($_.Exception.Message)"
    }
}