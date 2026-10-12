Automatisation d'Active Directory avec PowerShell
Présentation du projet

Ce projet a pour objectif d'automatiser les tâches courantes d'administration d'Active Directory à l'aide de scripts PowerShell et de fichiers CSV.

Il a été réalisé dans un environnement de laboratoire Windows Server avec un domaine Active Directory de test.

Les scripts permettent de préparer et d'automatiser la création des unités d'organisation (OU), des groupes de sécurité et des comptes utilisateurs.

Objectifs
Automatiser la création des unités d'organisation à partir d'un fichier CSV.
Automatiser la création des groupes Active Directory.
Créer des comptes utilisateurs à partir d'un fichier CSV.
Ajouter les utilisateurs aux groupes correspondants.
Vérifier l'existence des objets avant leur création.
Journaliser les opérations et les erreurs.
Limiter les risques grâce à un mode simulation avant la création réelle.
Technologies utilisées
Windows Server
Active Directory Domain Services (AD DS)
Windows PowerShell
Module PowerShell ActiveDirectory
Fichiers CSV
Git et GitHub
Structure du projet
Automatisation-Active-Directory-PowerShell/
├── CSV/
│   ├── OU.csv
│   ├── Groupes.csv
│   └── Utilisateurs-Exemple.csv
├── Scripts/
│   ├── Creer-OU.ps1
│   ├── Creer-Groupes.ps1
│   └── Creer-Utilisateurs.ps1
├── Captures/
├── .gitignore
└── README.md


Les fichiers CSV d'exemple doivent contenir uniquement des données fictives. Les journaux d'exécution et les fichiers contenant des mots de passe ne doivent pas être publiés.

Description des scripts
1. Creer-OU.ps1

Ce script lit le fichier OU.csv et prépare ou réalise la création des unités d'organisation.

Fonctionnalités :

Lecture du fichier CSV avec le séparateur ;.
Vérification des champs et des unités d'organisation parentes.
Détection des OU déjà existantes.
Mode simulation par défaut.
Journalisation des opérations.
2. Creer-Groupes.ps1

Ce script lit le fichier Groupes.csv et prépare ou réalise la création des groupes Active Directory.

Fonctionnalités :

Vérification des données du CSV.
Contrôle de l'existence de l'OU de destination.
Vérification des groupes déjà présents.
Création de groupes de sécurité ou de distribution selon les paramètres.
Mode simulation par défaut.
Journalisation des opérations.
3. Creer-Utilisateurs.ps1

Ce script lit un fichier CSV d'utilisateurs et prépare ou réalise la création des comptes.

Fonctionnalités :

Vérification des champs obligatoires.
Détection des identifiants et UPN en double dans le CSV.
Vérification de l'existence des OU et des groupes.
Contrôle de l'existence des comptes et des UPN.
Création des comptes utilisateurs.
Ajout des utilisateurs aux groupes indiqués.
Demande de changement de mot de passe à la première connexion.
Mode simulation par défaut.
Journalisation des résultats.
Format des fichiers CSV

Les fichiers utilisent le point-virgule (;) comme séparateur.

OU.csv
NomOU;CheminParent
Informatique;DC=ief2i,DC=lan
RH;DC=ief2i,DC=lan
Support;OU=Informatique,DC=ief2i,DC=lan

Groupes.csv
NomGroupe;Categorie;Portee;OU
GG_Informatique;Security;Global;OU=Informatique,DC=ief2i,DC=lan
GG_RH;Security;Global;OU=RH,DC=ief2i,DC=lan

Utilisateurs-Exemple.csv

Le fichier publié doit être un modèle sans mot de passe réel. Les mots de passe de laboratoire sont fournis localement au moment du test et ne doivent jamais être publiés dans le dépôt.

Prérequis
Un environnement Windows avec les outils d'administration Active Directory (RSAT).
Le module PowerShell ActiveDirectory.
Un accès à un domaine Active Directory de test.
Des autorisations suffisantes pour créer des OU, des groupes et des utilisateurs.
Des fichiers CSV correctement renseignés.
Exécution des scripts

Ouvrir PowerShell avec un compte disposant des autorisations nécessaires.

Simulation des OU
& "C:\Projet-AD\Scripts\Creer-OU.ps1"

Simulation des groupes
& "C:\Projet-AD\Scripts\Creer-Groupes.ps1"

Simulation des utilisateurs
& "C:\Projet-AD\Scripts\Creer-Utilisateurs.ps1"


Par défaut, les scripts fonctionnent en mode simulation. Ils ne doivent pas effectuer de création réelle sans le paramètre explicite -CreationReelle.

Création réelle

Après vérification des CSV, des chemins, des droits et des résultats de simulation, le paramètre suivant permet d'activer la création réelle :

& "C:\Projet-AD\Scripts\Creer-OU.ps1" -CreationReelle

& "C:\Projet-AD\Scripts\Creer-Groupes.ps1" -CreationReelle

& "C:\Projet-AD\Scripts\Creer-Utilisateurs.ps1" -CreationReelle


Attention : ces commandes modifient réellement Active Directory. Les exécuter uniquement dans un environnement de test autorisé, après avoir vérifié les données et les conséquences.

Sécurité
Ne jamais publier de mots de passe en clair.
Ne pas publier le fichier réel Utilisateurs.csv.
Ne pas publier de journaux contenant des informations internes.
Utiliser des comptes fictifs dans les exemples et les captures.
Tester les scripts en simulation avant toute création réelle.
Vérifier les permissions et les chemins avant l'exécution.
Tests réalisés

Les tests de laboratoire ont porté sur :

La lecture des fichiers CSV.
La détection d'OU et de groupes déjà existants.
La simulation de création des OU.
La simulation de création des groupes.
La simulation de création des utilisateurs.
La vérification des objets créés dans Active Directory.
L'ajout des utilisateurs aux groupes correspondants.

Les captures d'écran du projet peuvent être consultées dans le dossier Captures/ lorsqu'elles sont disponibles.

Améliorations possibles
Ajouter une validation plus complète des données CSV.
Renforcer la gestion des erreurs et des codes de retour.
Gérer les dépendances entre OU parentes et enfants.
Améliorer la gestion sécurisée des mots de passe.
Ajouter des tests automatisés.
Ajouter un rapport final récapitulant les créations et les erreurs.
Auteur

Projet personnel de laboratoire consacré à l'administration système, à Active Directory et à l'automatisation avec PowerShell.

Avertissement

Ce projet est destiné à l'apprentissage et aux environnements de test. Toute utilisation en production nécessite une revue du code, des tests supplémentaires et une validation des mesures de sécurité.