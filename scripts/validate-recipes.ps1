$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$recipesPath = Join-Path $root "recipes.json"
$imagesRoot = Join-Path $root "images"

if (-not (Test-Path $recipesPath)) {
    throw "recipes.json not found: $recipesPath"
}

$raw = Get-Content -Encoding UTF8 -Raw $recipesPath
$recipes = $raw | ConvertFrom-Json
$recipeProps = $recipes.PSObject.Properties

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$unitCount = @{}
$totalIngredients = 0
$totalSteps = 0
$timedRecipeCount = 0
$missingImageRecipes = New-Object System.Collections.Generic.List[string]

foreach ($recipeProp in $recipeProps) {
    $key = $recipeProp.Name
    $recipe = $recipeProp.Value

    if (-not $recipe.name) { $errors.Add("${key}: missing name") }
    if (-not $recipe.color) { $errors.Add("${key}: missing color") }
    if (-not $recipe.servings -or $recipe.servings -lt 1) { $errors.Add("${key}: invalid servings") }
    if (-not $recipe.ingredients -or $recipe.ingredients.Count -eq 0) { $errors.Add("${key}: no ingredients") }
    if (-not $recipe.instructions -or $recipe.instructions.Count -eq 0) { $errors.Add("${key}: no instructions") }

    $expectedStep = 1
    $hasTimerStep = $false

    foreach ($step in $recipe.instructions) {
        $totalSteps++
        if ($step.step -ne $expectedStep) {
            $errors.Add("${key}: step sequence mismatch at step $($step.step), expected $expectedStep")
            break
        }
        $expectedStep++

        if ($step.description -match "\d+") {
            $hasTimerStep = $true
        }
    }

    if ($hasTimerStep) {
        $timedRecipeCount++
    } else {
        $warnings.Add("${key}: no timed instruction")
    }

    foreach ($ingredient in $recipe.ingredients) {
        $totalIngredients++
        if ($null -eq $ingredient.name -or $null -eq $ingredient.amount -or $null -eq $ingredient.unit -or $null -eq $ingredient.calories_per_unit) {
            $errors.Add("${key}: incomplete ingredient data")
            continue
        }
        if ($ingredient.amount -lt 0) { $errors.Add("${key}: negative amount for $($ingredient.name)") }
        if ($ingredient.calories_per_unit -lt 0) { $errors.Add("${key}: negative calories for $($ingredient.name)") }

        $unit = [string]$ingredient.unit
        if ($unitCount.ContainsKey($unit)) { $unitCount[$unit]++ } else { $unitCount[$unit] = 1 }
    }

    $imageDir = Join-Path $imagesRoot $key
    $imageCount = 0
    if (Test-Path $imageDir) {
        $imageCount = (Get-ChildItem -Path $imageDir -File -Filter *.png | Measure-Object).Count
    }
    if ($imageCount -ne $recipe.instructions.Count) {
        $missingImageRecipes.Add("${key}: steps=$($recipe.instructions.Count), images=$imageCount")
    }
}

$recipeCount = ($recipeProps | Measure-Object).Count
Write-Output "recipes=$recipeCount ingredients=$totalIngredients steps=$totalSteps timed_recipes=$timedRecipeCount"
Write-Output ""
Write-Output "[Units]"
$unitCount.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Output "$($_.Name):$($_.Value)"
}

Write-Output ""
Write-Output "[Image coverage mismatches]"
if ($missingImageRecipes.Count -eq 0) {
    Write-Output "none"
} else {
    $missingImageRecipes | ForEach-Object { Write-Output $_ }
}

Write-Output ""
Write-Output "[Warnings]"
if ($warnings.Count -eq 0) {
    Write-Output "none"
} else {
    $warnings | ForEach-Object { Write-Output $_ }
}

Write-Output ""
Write-Output "[Errors]"
if ($errors.Count -eq 0) {
    Write-Output "none"
    exit 0
}

$errors | ForEach-Object { Write-Output $_ }
exit 1
