[CmdletBinding()]
param (
    # Indiquer le fichier CSV en entrée
        [Parameter()][string]
    $ContentFile
)
<#  Instructions pour utiliser ce script :

    Il suffit de lancer le script!
#>


#Prendre le dossier de travail de ce script
$workingDirectory = (Get-Location).Path

#Prendre le rapport WAF report via une boîte de dialogue
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.Title = "Sélectionner le ficher de Revue de Well-Architected Framework"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

Function FindIndexBeginningWith($stringset, $searchterm){
    $i=0
    foreach ($line in $stringset){
        if($line.StartsWith($searchterm)){
            return $i
        }
        $i++
    }
    return false
}

if([String]::IsNullOrEmpty($ContentFile))
{
    $inputfile = Get-FileName $workingDirectory
}
else 
{
    if(!(Resolve-Path $ContentFile)){
        $inputfile = Get-FileName $workingDirectory
    }else{
        $inputFile = $ContentFile
    }
}
#Valider que le fichier est OK
try{
    $content = Get-Content $inputfile
}
catch{
    Write-Error -Message "Impossible d'ouvrir le fichier de contenu sélectionné."
    exit
}
$inputfilename = Split-Path $inputfile -leaf

#region Validate input values

$templatePresentation = "$workingDirectory\PnP_Template_Rapport_PowerPoint.pptx"

try{
    $descriptionsFile = Import-Csv "$workingDirectory\Descriptions de Catégories WAF.csv"
}
catch{
    Write-Error -Message "Impossible d'ouvrir $($workingDirectory)\Descriptions de Catégories WAF.csv"
    exit
}

#endregion

$title = "Well-Architected [pillar] Assessment"
$reportDate = Get-Date -Format "yyyy-MM-dd-HHmm"
$localReportDate = Get-Date -Format g
try{
    $tableStart = FindIndexBeginningWith $content "Catégorie,Lien-Texte,Lien,Priorité,CatégorieReporting,SousCatégorieReporting,Poids,Contexte"
    #Write-Debug "Tablestart: $tablestart"
    $EndStringIdentifier = $content | Where-Object{$_.Contains("--,,")} | Select-Object -Unique -First 1
    #Write-Debug "IdentifiantFinDeChaine : $EndStringIdentifier"
    $tableEnd = $content.IndexOf($EndStringIdentifier) - 1
    #Write-Debug "Tableend: $tableend"
    $csv = $content[$tableStart..$tableEnd] | Out-File  "$workingDirectory\$reportDate.csv"
    $data = Import-Csv -Path "$workingDirectory\$reportDate.csv"
    $data | % { $_.Weight = [int]$_.Weight }
    $pillars = $data.Catégorie | Select-Object -Unique
}
catch{
    Write-Host "Impossible de traiter le fichier de contenu."
    Write-Host "Assurez vous que tous les fichiers d'entrée sont dans le bon format et qu'ils ne sont pas ouverts dans Excel ou un autre éditeur qui bloque le fichier."
    Write-Error -Message "Il y a un problème lors de l'ouverture ou du traitement du fichier de contenu ($inputfile)."
    exit
}


#region Calculs CSV

$descriptionCout = ($descriptionsFile | Where-Object{$_.Pillier -eq "Optimisation de Coût" -and $_.Catégorie -eq "Survey Level Group"}).Description
$operationsDescription = ($descriptionsFile | Where-Object{$_.Pillier -eq "Excellence Opérationnelle" -and $_.Catégorie -eq "Survey Level Group"}).Description
$performanceDescription = ($descriptionsFile | Where-Object{$_.Pillier -eq "Performance Efficiency" -and $_.Catégorie -eq "Survey Level Group"}).Description
$reliabilityDescription = ($descriptionsFile | Where-Object{$_.Pillier -eq "Reliability" -and $_.Catégorie -eq "Survey Level Group"}).Description
$descriptionSecurite = ($descriptionsFile | Where-Object{$_.Pillier -eq "Sécurité" -and $_.Catégorie -eq "Survey Level Group"}).Description

function Get-PillarInfo($pillar)
{
    if($pillar.Contains("Optimisation de Coût"))
    {
        return [pscustomobject]@{"Pillier" = $pillar; "Score" = $scoreCout; "Description" = $descriptionCout}
    }
    if($pillar.Contains("Reliability"))
    {
        return [pscustomobject]@{"Pillier" = $pillar; "Score" = $reliabilityScore; "Description" = $reliabilityDescription}
    }
    if($pillar.Contains("Excellence Opérationnelle"))
    {
        return [pscustomobject]@{"Pillier" = $pillar; "Score" = $operationsScore; "Description" = $operationsDescription}
    }
    if($pillar.Contains("Performance Efficiency"))
    {
        return [pscustomobject]@{"Pillier" = $pillar; "Score" = $performanceScore; "Description" = $performanceDescription}
    }
    if($pillar.Contains("Sécurité"))
    {
        return [pscustomobject]@{"Pillier" = $pillar; "Score" = $scoreSecurite; "Description" = $descriptionSecurite}
    }
}

$overallScore = ""
$scoreCout = ""
$operationsScore = ""
$performanceScore = ""
$reliabilityScore = ""
$scoreSecurite = ""

for($i=3; $i -le 8; $i++)
{
    if($Content[$i].Contains("overall"))
    {
        $overallScore = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Contains("Optimisation de Coût"))
    {
        $scoreCout = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Contains("Reliability"))
    {
        $reliabilityScore = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Contains("Excellence Opérationnelle"))
    {
        $operationsScore = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Contains("Performance Efficiency"))
    {
        $performanceScore = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Contains("Sécurité"))
    {
        $scoreSecurite = $Content[$i].Split(',')[2].Trim("'").Split('/')[0]
    }
    if($Content[$i].Equals(",,,,,"))
    {
        #End early if not all pillars assessed
        Break
    }
}

#endregion



$application = New-Object -ComObject powerpoint.application
$presentation = $application.Presentations.open($templatePresentation)
$titleSlide = $presentation.Slides[8]
$summarySlide = $presentation.Slides[9]
$detailSlide = $presentation.Slides[10]
$endSlide = $presentation.Slides[11]

#endregion

#region Clean the uncategorized data

if($data.PSobject.Properties.Name -contains "CatégorieReporting"){
    foreach($lineData in $data)
    {
        
        if(!$lineData.CatégorieReporting)
        {
            $lineData.CatégorieReporting = "Uncategorized"
        }
    }
}

#endregion

foreach($pillar in $pillars) 
{
    $pillarData = $data | Where-Object{$_.Catégorie -eq $pillar}
    $pillarInfo = Get-PillarInfo -pillar $pillar
    
    # Edit title & date on slide 1
    $slideTitle = $title.Replace("[pillar]",$pillar.substring(0,1).toupper()+$pillar.substring(1).tolower())
    $newTitleSlide = $titleSlide.Duplicate()
    $newTitleSlide.MoveTo($presentation.Slides.Count)
    $newTitleSlide.Shapes[3].TextFrame.TextRange.Text = $slideTitle
    $newTitleSlide.Shapes[4].TextFrame.TextRange.Text = $newTitleSlide.Shapes[4].TextFrame.TextRange.Text.Replace("[Report_Date]",$localReportDate)
   
    # Edit Executive Summary Slide

    #Add logic to get overall score
    $newSummarySlide = $summarySlide.Duplicate()
    $newSummarySlide.MoveTo($presentation.Slides.Count)
    $newSummarySlide.Shapes[3].TextFrame.TextRange.Text = $pillarInfo.Score
    $newSummarySlide.Shapes[4].TextFrame.TextRange.Text = $pillarInfo.Description
    [Single]$summBarScore = [int]$pillarInfo.Score*2.47+56
    $newSummarySlide.Shapes[11].Left = $summBarScore

    $CategoriesList = New-Object System.Collections.ArrayList
    $categories = ($pillarData | Sort-Object -Property "Weight" -Descending).CatégorieReporting | Select-Object -Unique
    foreach($category in $categories)
    {
        $categoryWeight = ($pillarData | Where-Object{$_.CatégorieReporting -eq $category}).Weight | Measure-Object -Sum
        $categoryScore = $categoryWeight.Sum/$categoryWeight.Count
        $categoryWeightiestCount = ($pillarData | Where-Object{$_.CatégorieReporting -eq $category}).Weight -ge $MinimumReportLevel | Measure-Object
        $CategoriesList.Add([pscustomobject]@{"Catégorie" = $category; "CategoryScore" = $categoryScore; "CategoryWeightiestCount" = $categoryWeightiestCount.Count}) | Out-Null
    }

    $CategoriesList = $CategoriesList | Sort-Object -Property CategoryScore -Descending

    $counter = 13 #Shape count for the slide to start adding scores
    $categoryCounter = 0
    $areaIconX = 378.1129
    $areaIconY = @(176.4359, 217.6319, 258.3682, 299.1754, 339.8692, 382.6667, 423.9795, 461.0491)
    foreach($category in $CategoriesList)
    {
        if($category.Catégorie -ne "Uncategorized")
        {
            try
            {
                #$newSummarySlide.Shapes[8] #Domain 1 Icon
                $newSummarySlide.Shapes[$counter].TextFrame.TextRange.Text = $category.CategoryWeightiestCount.ToString("#")
                $newSummarySlide.Shapes[$counter+1].TextFrame.TextRange.Text = $category.Catégorie
                $counter = $counter + 3
                switch ($category.CategoryScore) {
                    { $_ -lt 33 } { 
                        $categoryShape = $newSummarySlide.Shapes[37]
                    }
                    { $_ -gt 33 -and $_ -lt 67 } { 
                        $categoryShape = $newSummarySlide.Shapes[38] 
                    }
                    { $_ -gt 67 } { 
                        $categoryShape = $newSummarySlide.Shapes[39] 
                    }
                    Default { 
                        $categoryShape = $newSummarySlide.Shapes[38] 
                    }
                }
                $categoryShape.Duplicate() | Out-Null
                $newShape = $newSummarySlide.Shapes.Count
                $newSummarySlide.Shapes[$newShape].Left = $areaIconX
                $newSummarySlide.Shapes[$newShape].top = $areaIcony[$categoryCounter] 
                $categoryCounter = $categoryCounter + 1
            }
            catch{}
        }
    }

    #Remove the boilerplate placeholder text if categories < 8
    if($categories.Count -lt 8)
    {
        $skipLastShape = $newSummarySlide.Shapes.count - $categoryCounter
        for($k=$skipLastShape; $k -gt $counter-1; $k--)
        {
            try
            {
                $newSummarySlide.Shapes[$k].Delete()
                <#$newSummarySlide.Shapes[$k].Delete()
                $newSummarySlide.Shapes[$k+1].Delete()#>
            }
            catch{}
        }
    }

    # Edit new category summary slide

    foreach($category in $CategoriesList.Catégorie)
    {
        $categoryData = $pillarData | Where-Object{$_.CatégorieReporting -eq $category -and $_.Catégorie -eq $pillar}
        $categoryDataCount = ($categoryData | measure).Count
        $categoryWeight = ($pillarData | Where-Object{$_.CatégorieReporting -eq $category}).Weight | Measure-Object -Sum
        $categoryScore = $categoryWeight.Sum/$categoryWeight.Count
        $categoryDescription = ($descriptionsFile | Where-Object{$_.Pillier -eq $pillar -and $categoryData.CatégorieReporting.Contains($_.Catégorie)}).Description
        $y = $categoryDataCount
        $x = 5
        if($categoryDataCount -lt 5)
        {
            $x = $categoryDataCount
        }

        $newDetailSlide = $detailSlide.Duplicate()
        $newDetailSlide.MoveTo($presentation.Slides.Count)

        $newDetailSlide.Shapes[1].TextFrame.TextRange.Text = $category
        $newDetailSlide.Shapes[3].TextFrame.TextRange.Text = $categoryScore.ToString("#")
        [Single]$detailBarScore = $categoryScore*2.48+38
        $newDetailSlide.Shapes[12].Left = $detailBarScore
        $newDetailSlide.Shapes[4].TextFrame.TextRange.Text = $categoryDescription
        $newDetailSlide.Shapes[7].TextFrame.TextRange.Text = "Top $x out of $y recommendations:"
        $newDetailSlide.Shapes[8].TextFrame.TextRange.Text = ($categoryData | Sort-Object -Property "Link-Text" -Unique | Sort-Object -Property Weight -Descending | Select-Object -First $x).'Link-Text' -join "`r`n`r`n"
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
$presentation.SavecopyAs("$workingDirectory\PnP_PowerPointReport_Template_$reportDate.pptx")
$presentation.Close()


$application.quit()
$application = $null
[gc]::collect()
[gc]::WaitForPendingFinalizers()
