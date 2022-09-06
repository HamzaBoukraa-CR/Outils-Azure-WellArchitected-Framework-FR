#Ce script télécharge la liste de fichiers vers le dossier de travail

#C'est l'URL de base pour les téléchargements. L'URL de base ne peut pas se terminer par un /
$baseURL = "https://raw.githubusercontent.com/HamzaBoukraa-CR/Outils-Azure-WellArchitected-Framework-FR/main/WARP/devops"

$workingDirectory = (Get-Location).Path
Write-Host "Dossier de travail : $workingDirectory"
Invoke-WebRequest $baseURL/liste-fichiers.txt -OutFile $workingDirectory/liste-fichiers.txt


Write-Host "Téléchargement à partir de : $baseURL"
Write-Host "La liste de fichiers :"
Get-Content $workingDirectory/liste-fichiers.txt | ForEach-Object {Write-Host "   $_"}


Get-Content $workingDirectory/liste-fichiers.txt | ForEach-Object {Invoke-WebRequest $baseURL/$_ -OutFile $workingDirectory/$(Split-Path $_ -Leaf)}
