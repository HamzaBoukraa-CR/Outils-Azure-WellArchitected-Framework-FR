---
Titre: Outillage DevOps pour le processus de recommendations de Azure Well-Architected Framework
Description: Instructions pour l'utilisation de l'Outillage DevOps pour le processus de recommendations de Azure Well-Architected Framework
Auteur: HamzaBoukraa
ms.date: 09/06/2022
ms.topic: conceptuel
ms.service: architecture-center
ms.subservice: well-architected
ms.custom:
  - guide
mots clefs:
  - "Processus de recommendations Well-Architected Framework"
  - "Processus de recommendations Azure Well-Architected Framework"
  - "WARP"
  - "Processus de recommendations Well architected"
  - 'Outillage'
produits:
  - azure-devops
catégories:
  - devops
---

# Outillage DevOps pour le Processus de Recommendations Azure Well-Architected

## Overview

Il y a quatre sections dans ce document :

1. Préparation
1. Reporting
1. Placer les outputs dans un projet Azure DevOps
1. Importer dans GitHub

## Préparation

### Prérequis

- Un project Azure DevOps ***nouveau ou vide*** utilisant un framework agile. Les instructions pour créer ce projet sont listées ci-dessous.

 - Les utilisateurs de cet exemple sont encouragés à tester sur un projet DevOps de non-production DevOps pour bien comprendre comment les recommendations sont représentées dans Azure DevOps.

 - Après les tests, les utilisateurs de cet exemple sont encouragés à importer les recommendations dans un projet Azure DevOps adéquat pour bien planifier et exécuter le travail. 

    **ou**

- Un repo GitHub ***nouveau ou vide*** GitHub pour recevoir ces éléments.

 - Les utilisateurs de cet exemple sont encouragés à tester sur un projet GitHub de non-production DevOps pour bien comprendre comment les recommendations sont représentées dans Github.

 - Après les tests, les utilisateurs de cet exemple sont encouragés à importer les recommendations dans un projet GitHub adéquat pour bien planifier et exécuter le travail. 

- Windows 10 (ou plus récent).

- PowerShell v7

- Microsoft PowerPoint 2019

 - PowerPoint n'est pas requis pour importer les outputs dans Azure DevOps ou Github.

 - Seulement requis pour créer des présentations PowerPoint surlignant les problèmes détectés.

---

**IMPORTANT:**  **Ces instructions fonctionnent seulement sur un environnement Windows à ce stade.**

### Télécharger les scripts et préparer votre environnement pour les exécuter.

1. Télécharger et installer [PowerShell 7](https://docs.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell)

1. Lancer un terminal PowerShell et lancer les commandes suivantes à partir d'un dossier de travail:

    ```powershell
    $installUri = "https://raw.githubusercontent.com/HamzaBoukraa-CR/Outils-Azure-WellArchitected-Framework-FR/main/WARP/devops/installer-outils-WARP.ps1"
    Invoke-WebRequest $installUri -OutFile "installer-outils-WARP.ps1"
    .\installer-outils-WARP.ps1
    ```

    Example output:

    ```powershell
    PS C:\Users\me> mkdir warp
    PS C:\Users\me> cd warp
    PS C:\Users\me\warp> $installUri = "https://raw.githubusercontent.com/HamzaBoukraa-CR/Outils-Azure-WellArchitected-Framework-FR/main/WARP/devops/installer-outils-WARP.ps1"
    PS C:\Users\me\warp> Invoke-WebRequest $installUri -OutFile "installer-outils-WARP.ps1"
    PS C:\Users\me\warp> .\installer-outils-WARP.ps1
    Dossier de travail : C:\Users\me\warp
    Télécharger à partir de : https://raw.githubusercontent.com/HamzaBoukraa-CR/Outils-Azure-WellArchitected-Framework-FR/main/WARP/devops
    We will get these files:
       Azure_Well_Architected_Review_Sample.csv
       GenerateWAFReport.ps1
       PnP-DevOps.ps1
       PnP-Github.ps1
       PnP_Template_Rapport_PowerPoint.pptx
       WAF Category Descriptions.csv
       WASA.json
    ```

## Reporting

### Création d'une présentation PowerPoint en utilisant PowerShell

1. Copier le fichier CSV exporté à partir de [Revue Microsoft Azure Well-Architected](https://docs.microsoft.com/assessments/?mode=pre-assessment) dans le dossier de travail créé précédemment.

    **NOTE:** Un exemple d'export est inclu dans cet outillage : Exemple\_Revue\_Azure\_Well\_Architected.csv

1. Lancer la commande suivante dans un terminal PowerShell et sélectionner le fichier CSV à utiliser :

    ```powershell
    .\GenererRapportWAF.ps1 
    ```

    **NOTE:** Un nouveau fichier PowerPoint file sera créé dans le dossier de travail portant un nom sous le format: `PnP_Template_Rapport_PowerPoint_yyyy-mm-dd hh.mm.ss.pptx`

1. Examiner ce fichier PowerPoint file pour les diapositives auto-générées (après la diapo 8).

1. Si ces diapositives sont créées dans ce fichier, alors l'environnement est bien configuré et l'utilisation d'un vrai CSV généré par l'évaluation de Well Architected Framework.

## Import des recommendations dans un projet Azure DevOps

1. Créer ou se connecter à une **Organisation** Azure DevOps :

    - If an organization does not exist, follow these steps in this [link](https://docs.microsoft.com/azure/devops/organizations/accounts/create-organization?view=azure-devops&preserve-view=true).

    **IMPORTANT:** In Azure DevOps, under **Organization Settings - Overview**, verify that your organization is using the [new URL format](https://docs.microsoft.com/en-us/azure/devops/release-notes/2018/sep-10-azure-devops-launch#administration).

1. Navigate to the **Project** where you want to import the recommendations:
    - If a project does not exist in the Azure DevOps Organization, then create a new project using the steps in this [link](https://docs.microsoft.com/azure/devops/organizations/projects/create-project?view=azure-devops&tabs=preview-page&preserve-view=true).

    **IMPORTANT:** If you are using an existing **Project**, you will need to ensure that the [process](https://docs.microsoft.com/en-us/azure/devops/organizations/settings/work/inheritance-process-model?view=azure-devops&tabs=agile-process) is set to **Agile**. When you create a new project, ensure that the **Work item process** is set to **Agile** under **Advanced**.

    ![New Project](_images/new_project.png)

1. Make note of the **Project** URL in the address bar

    ![Project URL](_images/project_url.png)

1. Create or acquire an Azure DevOps **Personal Access Token** using the steps in this [link](https://docs.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page&preserve-view=true).

    - **IMPORTANT:** The **Personal Access Token** that you use or create must have **Read, write, & manage** access to **Work Items**

    ![Personal Access Token](_images/pat.png)

1. Run the following command in the PowerShell terminal.

    ```powershell
    .\PnP-DevOps.ps1 -csv PATH_TO_CSV -pat PAT_FROM_ADO -uri "PROJECT_URL" -name "ASSESSMENT_NAME"
    ```

    The flags are:

    * **-pat** The **Personal Access Token** from ADO
    * **-uri** The URL for your **Project**
    * **-csv** The exported CSV file from a [Microsoft Azure Well-Architected Assessment](https://docs.microsoft.com/assessments/?mode=pre-assessment).
    * **-name** is used to tag the imported work items in ADO.
        * Organizations and teams can use these tags as  milestones to organize the work items across multiple assessments. 
        * For example:

            A team performs a Well-Architected Review and imports the resultant CSV into their DevOps tooling. The team names this import "Milestone 1" and all work items imported are tagged with the name "Milestone 1"
            
            After a few sprints, the team can perform another Well-Architected Review. The import the resultant CSV into their DevOps tooling. This import would be named "Milestone 2".

            Note: Assessments and imports should focus only on a single workload. There is no method to differentiate between workloads with these tools.
    

    Example command output:

    ```powershell
    PS C:\Users\cae\warp>.\PnP-DevOps.ps1 -csv .\Azure_Well_Architected_Review_Sample.csv `
    >> -pat xxxxxxxxxxxxxxxxx `
    >> -uri https://dev.azure.com/contoso/WARP_Import `
    >> -name "WAF-Assessment-202201"
    Assessment Name: WAF-Assessment-202201
    URI Base: https://dev.azure.com/contoso/WARP_Import/
    Number of Recommendations to import : 175
    Ready? [y/n]: y
    Adding Epic to ADO: Operational Procedures
    Adding Epic to ADO: Deployment & Testing
    Adding Epic to ADO: Governance
    ...
    Adding Work Item: Storage account should use a private link connection for 4 Storage Account(s)
    Adding Work Item: Log Analytics agent should be installed on your virtual machine for 1 Virtual machine(s)
    Adding Work Item: Management ports of virtual machines should be protected with just-in-time network access control for 1 Virtual machine(s)
    ...

    Import Complete!
    ```

1. When the script finishes, navigate to the **Backlogs** in your Azure DevOps Projects, enable **Epics** in the settings, and then set the navigation level to **Epics**.

    ![Backlogs](_images/backlog_settings1.png)

    ![Backlogs Settings](_images/backlog_settings2.png)

    ![Backlogs Scope](_images/backlog_settings3.png)
    **NOTE:** If **Epics** do not appear in the drop down after changing the settings, refreshing the page should fix that.


1. You should now see the **Backlogs** populated with **Epics** and **Features**:

    ![Backlogs](_images/backlog_settings4.png)

## Place findings into a GitHub repository

1. Create or log into an existing Github repository.

    - If an organization does not exist, follow these steps in this [link](https://docs.github.com/en/get-started/quickstart/create-a-repo).

1. Acquire a [personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) with write access to create issues:

    - Permissions should be *Full control of private repositories*.
    ![](_images/github_repo_perms.png)

1. Run the `PnP-Github.ps1` script from a command prompt: `./PnP-Github.ps1 -pat \`
   `"GITHUB-PAT-TOKEN" -csv PATH-TO-CSV -uri "URI-FOR-GITHUB-DEPOT" -name "ASSESSMENT_NAME"`

    The flags are:

    * **-pat** The **Personal Access Token** from Github
    * **-uri** The URL for your **Project**
    * **-csv** The exported CSV file from a [Microsoft Azure Well-Architected Assessment](https://docs.microsoft.com/assessments/?mode=pre-assessment).
    * **-name** is used is used to tag the imported work items in ADO.
        * Organizations and teams can use these tags as  milestones to organize the work items across multiple assessments. 
        * For example:

            A team performs a Well-Architected Review and imports the resultant CSV into their DevOps tooling. The team names this import "Milestone 1" and all work items imported are tagged with the name "Milestone 1"
            
            After a few sprints, the team can perform another Well-Architected Review. The import the resultant CSV into their DevOps tooling. This import would be named "Milestone 2".

            Note: Assessments and imports should focus only on a single workload. There is no method to differentiate between workloads with these tools.
    

    Example command output:
1. Example: `./PnP-Github.ps1 -pat "ghp_TjDjgAKBNK0R1VPDm1234567890" \`
`-csv .\test-assessmentsmall.csv -uri "https://github.com/WAF-USER/contoso" \`
` -name "WAF FEB 2021"`

1.  You should see **Milestones** and **Issues** populated with data.
![](_images/github_repo_backlog.png)
