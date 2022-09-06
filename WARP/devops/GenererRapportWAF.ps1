[CmdletBinding()]
param (
    # Indiquer le fichier CSV en entrée
        [Parameter()][string]
    $FichierContenu
)
<#  Instructions pour utiliser ce script :

    Il suffit de lancer le script!
#>


#Prendre le dossier de travail de ce script
$dossierTravail = (Get-Location).Path

#Prendre le rapport WAF report via une boîte de dialogue
Function Prendre-NomFichier($dossierPrincipal)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $boiteDialogueOuvrirFichier = New-Object System.Windows.Forms.OpenFileDialog
    $boiteDialogueOuvrirFichier.initialDirectory = $dossierPrincipal
    $boiteDialogueOuvrirFichier.filter = "CSV (*.csv)| *.csv"
    $boiteDialogueOuvrirFichier.Title = "Sélectionner le ficher de Revue de Well-Architected Framework"
    $boiteDialogueOuvrirFichier.ShowDialog() | Out-Null
    $boiteDialogueOuvrirFichier.filename
}

Function Trouver-IndexCommencantPar($chaines, $termeRecherche){
    $index=0
    foreach ($ligne in $chaines){
        if($ligne.StartsWith($termeRecherche)){
            return $index
        }
        $index++
    }
    return false
}

if([String]::IsNullOrEmpty($FichierContenu))
{
    $fichierEntree = Prendre-NomFichier $dossierTravail
}
else 
{
    if(!(Resolve-Path $FichierContenu)){
        $fichierEntree = Prendre-NomFichier $dossierTravail
    }else{
        $fichierEntree = $FichierContenu
    }
}
#Valider que le fichier est OK
try{
    $contenu = Get-Content $fichierEntree
}
catch{
    Write-Error -Message "Impossible d'ouvrir le fichier de contenu sélectionné."
    exit
}
$nomFichierEntree = Split-Path $fichierEntree -leaf

#region Valider valeurs en entrée

$templatePresentation = "$dossierTravail\PnP_Template_Rapport_PowerPoint.pptx"

try{
    $fichierDescriptions = Import-Csv "$dossierTravail\Descriptions de Catégories WAF.csv"
}
catch{
    Write-Error -Message "Impossible d'ouvrir $($dossierTravail)\Descriptions de Catégories WAF.csv"
    exit
}

#endregion

$titre = "Well-Architected [pillar] Assessment"
$dateRapport = Get-Date -Format "yyyy-MM-dd-HHmm"
$dateRapportLocale = Get-Date -Format g
try{
    $debutTable = Trouver-IndexCommencantPar $contenu "Catégorie,Lien-Texte,Lien,Priorité,CatégorieReporting,SousCatégorieReporting,Poids,Contexte"
    #Write-Debug "Debut Table : $debutTable"
    $identifiantChaineFin = $contenu | Where-Object{$_.Contains("--,,")} | Select-Object -Unique -First 1
    #Write-Debug "Identifiant de fin : $identifiantChaineFin"
    $finTable = $contenu.IndexOf($identifiantChaineFin) - 1
    #Write-Debug "Fin Table : $finTable"
    $csv = $contenu[$debutTable..$finTable] | Out-File  "$dossierTravail\$dateRapport.csv"
    $donnees = Import-Csv -Path "$dossierTravail\$dateRapport.csv"
    $donnees | % { $_.Poids = [int]$_.Poids }
    $pilliers = $donnees.Catégorie | Select-Object -Unique
}
catch{
    Write-Host "Impossible de traiter le fichier de contenu."
    Write-Host "Assurez vous que tous les fichiers d'entrée sont dans le bon format et qu'ils ne sont pas ouverts dans Excel ou un autre éditeur qui bloque le fichier."
    Write-Error -Message "Il y a un problème lors de l'ouverture ou du traitement du fichier de contenu ($fichierEntree)."
    exit
}


#region Calculs CSV

$descriptionCout = ($fichierDescriptions | Where-Object{$_.Pillier -eq "Optimisation de Coût" -and $_.Catégorie -eq "Survey Level Group"}).Description
$descriptionOperations = ($fichierDescriptions | Where-Object{$_.Pillier -eq "Excellence Opérationnelle" -and $_.Catégorie -eq "Survey Level Group"}).Description
$descriptionPerformance = ($fichierDescriptions | Where-Object{$_.Pillier -eq "Efficacité des Performances" -and $_.Catégorie -eq "Survey Level Group"}).Description
$descriptionFiabilite = ($fichierDescriptions | Where-Object{$_.Pillier -eq "Fiabilité" -and $_.Catégorie -eq "Survey Level Group"}).Description
$descriptionSecurite = ($fichierDescriptions | Where-Object{$_.Pillier -eq "Sécurité" -and $_.Catégorie -eq "Survey Level Group"}).Description

function Prendre-InfosPillier($pillier)
{
    if($pillier.Contains("Optimisation de Coût"))
    {
        return [pscustomobject]@{"Pillier" = $pillier; "Score" = $scoreCout; "Description" = $descriptionCout}
    }
    if($pillier.Contains("Fiabilité"))
    {
        return [pscustomobject]@{"Pillier" = $pillier; "Score" = $scoreFiabilite; "Description" = $descriptionFiabilite}
    }
    if($pillier.Contains("Excellence Opérationnelle"))
    {
        return [pscustomobject]@{"Pillier" = $pillier; "Score" = $scoreOperations; "Description" = $descriptionOperations}
    }
    if($pillier.Contains("Efficacité des Performances"))
    {
        return [pscustomobject]@{"Pillier" = $pillier; "Score" = $scorePerformance; "Description" = $descriptionPerformance}
    }
    if($pillier.Contains("Sécurité"))
    {
        return [pscustomobject]@{"Pillier" = $pillier; "Score" = $scoreSecurite; "Description" = $descriptionSecurite}
    }
}

$scoreGlobal = ""
$scoreCout = ""
$scoreOperations = ""
$scorePerformance = ""
$scoreFiabilite = ""
$scoreSecurite = ""

for($i=3; $i -le 8; $i++)
{
    if($contenu[$i].Contains("global"))
    {
        $scoreGlobal = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Contains("Optimisation de Coût"))
    {
        $scoreCout = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Contains("Fiabilité"))
    {
        $scoreFiabilite = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Contains("Excellence Opérationnelle"))
    {
        $scoreOperations = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Contains("Efficacité des Performances"))
    {
        $scorePerformance = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Contains("Sécurité"))
    {
        $scoreSecurite = $contenu[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($contenu[$i].Equals(",,,,,"))
    {
        #Fin prématurée si tous les pilliers ne sont pas évalués
        Break
    }
}

#endregion


$application = New-Object -ComObject powerpoint.application
$presentation = $application.Presentations.open($templatePresentation)
$diapoTitre = $presentation.Slides[8]
$diapoSommaire = $presentation.Slides[9]
$diapoDetail = $presentation.Slides[10]
$diapoFin = $presentation.Slides[11]

#endregion

#region Nettoyage de données non catégorisées

if($donnees.PSobject.Properties.Name -contains "CatégorieReporting"){
    foreach($ligneDonnees in $donnees)
    {
        
        if(!$ligneDonnees.CatégorieReporting)
        {
            $ligneDonnees.CatégorieReporting = "Non categorisé"
        }
    }
}

#endregion

foreach($pillier in $pilliers) 
{
    $donneesPillier = $donnees | Where-Object{$_.Catégorie -eq $pillier}
    $InfoPillier = Prendre-InfoPillier -pillier $pillier
    
    # Edit titre & date sur diapositive 1
    $diapoTitre = $titre.Replace("[pillier]",$pillier.substring(0,1).toupper()+$pillier.substring(1).tolower())
    $nouvelleDiapoTitre = $diapoTitre.Duplicate()
    $nouvelleDiapoTitre.MoveTo($presentation.Slides.Count)
    $nouvelleDiapoTitre.Shapes[3].TextFrame.TextRange.Text = $diapoTitre
    $nouvelleDiapoTitre.Shapes[4].TextFrame.TextRange.Text = $nouvelleDiapoTitre.Shapes[4].TextFrame.TextRange.Text.Replace("[Date_Rapport]",$dateRapportLocale)
   
    # Edit Diapo Sommaire

    #Ajout de logique pour le score global
    $nouvelleDiapoSommaire = $diapoSommaire.Duplicate()
    $nouvelleDiapoSommaire.MoveTo($presentation.Slides.Count)
    $nouvelleDiapoSommaire.Shapes[3].TextFrame.TextRange.Text = $infoPillier.Score
    $nouvelleDiapoSommaire.Shapes[4].TextFrame.TextRange.Text = $infoPillier.Description
    [Single]$summBarScore = [int]$infoPillier.Score*2.47+56
    $nouvelleDiapoSommaire.Shapes[11].Left = $summBarScore

    $listeCategories = New-Object System.Collections.ArrayList
    $categories = ($donneesPillier | Sort-Object -Property "Poids" -Descending).CatégorieReporting | Select-Object -Unique
    foreach($categorie in $categories)
    {
        $poidsCategorie = ($donneesPillier | Where-Object{$_.CatégorieReporting -eq $categorie}).Poids | Measure-Object -Sum
        $scoreCategorie = $poidsCategorie.Sum/$poidsCategorie.Count
        $poidsCategorieCount = ($donneesPillier | Where-Object{$_.CatégorieReporting -eq $categorie}).Poids -ge $MinimumReportLevel | Measure-Object
        $listeCategories.Add([pscustomobject]@{"Catégorie" = $categorie; "ScoreCatégorie" = $scoreCategorie; "PoidsCatégorieCount" = $poidsCategorieCount.Count}) | Out-Null
    }

    $listeCategories = $listeCategories | Sort-Object -Property ScoreCatégorie -Descending

    $compteur = 13
    $compteurCategorie = 0
    $areaIconX = 378.1129
    $areaIconY = @(176.4359, 217.6319, 258.3682, 299.1754, 339.8692, 382.6667, 423.9795, 461.0491)
    foreach($categorie in $listeCategories)
    {
        if($categorie.Catégorie -ne "Non categorisé")
        {
            try
            {
                #$nouvelleDiapoSommaire.Shapes[8] #Domain 1 Icon
                $nouvelleDiapoSommaire.Shapes[$compteur].TextFrame.TextRange.Text = $categorie.PoidsCatégorieCount.ToString("#")
                $nouvelleDiapoSommaire.Shapes[$compteur+1].TextFrame.TextRange.Text = $categorie.Catégorie
                $compteur = $compteur + 3
                switch ($categorie.ScoreCatégorie) {
                    { $_ -lt 33 } { 
                        $formeCategorie = $nouvelleDiapoSommaire.Shapes[37]
                    }
                    { $_ -gt 33 -and $_ -lt 67 } { 
                        $formeCategorie = $nouvelleDiapoSommaire.Shapes[38] 
                    }
                    { $_ -gt 67 } { 
                        $formeCategorie = $nouvelleDiapoSommaire.Shapes[39] 
                    }
                    Default { 
                        $formeCategorie = $nouvelleDiapoSommaire.Shapes[38] 
                    }
                }
                $formeCategorie.Duplicate() | Out-Null
                $nouvelleForme = $nouvelleDiapoSommaire.Shapes.Count
                $nouvelleDiapoSommaire.Shapes[$nouvelleForme].Left = $areaIconX
                $nouvelleDiapoSommaire.Shapes[$nouvelleForme].top = $areaIcony[$compteurCategorie] 
                $compteurCategorie = $compteurCategorie + 1
            }
            catch{}
        }
    }

    #Supprimer si categories < 8
    if($categories.Count -lt 8)
    {
        $skipLastShape = $nouvelleDiapoSommaire.Shapes.count - $compteurCategorie
        for($k=$skipLastShape; $k -gt $compteur-1; $k--)
        {
            try
            {
                $nouvelleDiapoSommaire.Shapes[$k].Delete()
                <#$nouvelleDiapoSommaire.Shapes[$k].Delete()
                $nouvelleDiapoSommaire.Shapes[$k+1].Delete()#>
            }
            catch{}
        }
    }

    # Edit nouvelle diapo de sommaire catégorie

    foreach($categorie in $listeCategories.Catégorie)
    {
        $donneesCategorie = $donneesPillier | Where-Object{$_.CatégorieReporting -eq $categorie -and $_.Catégorie -eq $pillier}
        $donneesCategorieCount = ($donneesCategorie | measure).Count
        $poidsCategorie = ($donneesPillier | Where-Object{$_.CatégorieReporting -eq $categorie}).Poids | Measure-Object -Sum
        $scoreCategorie = $poidsCategorie.Sum/$poidsCategorie.Count
        $descriptionCategorie = ($fichierDescriptions | Where-Object{$_.Pillier -eq $pillier -and $donneesCategorie.CatégorieReporting.Contains($_.Catégorie)}).Description
        $y = $donneesCategorieCount
        $x = 5
        if($donneesCategorieCount -lt 5)
        {
            $x = $donneesCategorieCount
        }

        $newDetailSlide = $detailSlide.Duplicate()
        $newDetailSlide.MoveTo($presentation.Slides.Count)

        $newDetailSlide.Shapes[1].TextFrame.TextRange.Text = $categorie
        $newDetailSlide.Shapes[3].TextFrame.TextRange.Text = $scoreCategorie.ToString("#")
        [Single]$detailBarScore = $scoreCategorie*2.48+38
        $newDetailSlide.Shapes[12].Left = $detailBarScore
        $newDetailSlide.Shapes[4].TextFrame.TextRange.Text = $categoryDescription
        $newDetailSlide.Shapes[7].TextFrame.TextRange.Text = "Top $x out of $y recommendations:"
        $newDetailSlide.Shapes[8].TextFrame.TextRange.Text = ($categoryData | Sort-Object -Property "Link-Text" -Unique | Sort-Object -Property Poids -Descending | Select-Object -First $x).'Link-Text' -join "`r`n`r`n"
        $sentenceCount = $newDetailSlide.Shapes[8].TextFrame.TextRange.Sentences().count

        for($k=1; $k -le $sentenceCount; $k++)
        {
            if($newDetailSlide.Shapes[8].TextFrame.TextRange.Sentences($k).Text)
            {
                try
                {
                    $recommendationObject = $categoryData | Where-Object{$newDetailSlide.Shapes[8].TextFrame.TextRange.Sentences($k).Text.Contains($_.'Link-Text')}
                    $newDetailSlide.Shapes[8].TextFrame.TextRange.Sentences($k).ActionSettings(1).HyperLink.Address = $recommendationObject.Link
                }
                catch{}
            }
        }    
    }
}

$newEndSlide = $endSlide.Duplicate()
$newEndSlide.MoveTo($presentation.Slides.Count)

$titleSlide.Delete()
$summarySlide.Delete()
$detailSlide.Delete()
$endSlide.Delete()
$presentation.SavecopyAs("$dossierTravail\PnP_Template_Rapport_PowerPoint_$dateRapport.pptx")
$presentation.Close()


$application.quit()
$application = $null
[gc]::collect()
[gc]::WaitForPendingFinalizers()
