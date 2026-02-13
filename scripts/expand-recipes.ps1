$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$recipesPath = Join-Path $root "recipes.json"

if (-not (Test-Path $recipesPath)) {
    throw "recipes.json not found: $recipesPath"
}

function New-Ingredient {
    param(
        [string]$Name,
        [double]$Amount,
        [string]$Unit,
        [double]$CaloriesPerUnit,
        [string]$CalorieBasis = "per_unit"
    )
    return [ordered]@{
        name = $Name
        amount = $Amount
        unit = $Unit
        calories_per_unit = $CaloriesPerUnit
        calorie_basis = $CalorieBasis
    }
}

function Get-TemplateData {
    param(
        [string]$DishName,
        [string]$Category
    )

    $defaultIngredients = @(
        (New-Ingredient "주재료" 300 "g" 180 "per_100"),
        (New-Ingredient "양파" 0.5 "개" 40),
        (New-Ingredient "대파" 0.5 "대" 30),
        (New-Ingredient "다진 마늘" 1 "스푼" 130),
        (New-Ingredient "간장" 1.5 "스푼" 10),
        (New-Ingredient "소금" 0.3 "스푼" 0),
        (New-Ingredient "식용유" 1 "스푼" 120),
        (New-Ingredient "물" 250 "ml" 0 "per_100")
    )

    $soupIngredients = @(
        (New-Ingredient "주재료" 280 "g" 140 "per_100"),
        (New-Ingredient "물" 900 "ml" 0 "per_100"),
        (New-Ingredient "양파" 0.5 "개" 40),
        (New-Ingredient "대파" 1 "대" 30),
        (New-Ingredient "다진 마늘" 1 "스푼" 130),
        (New-Ingredient "국간장" 1.5 "스푼" 10),
        (New-Ingredient "소금" 0.3 "스푼" 0),
        (New-Ingredient "후추" 0.2 "스푼" 0)
    )

    $noodleIngredients = @(
        (New-Ingredient "면" 220 "g" 330 "per_100"),
        (New-Ingredient "주재료" 180 "g" 160 "per_100"),
        (New-Ingredient "양파" 0.5 "개" 40),
        (New-Ingredient "대파" 0.5 "대" 30),
        (New-Ingredient "다진 마늘" 1 "스푼" 130),
        (New-Ingredient "간장 또는 소스" 2 "스푼" 25),
        (New-Ingredient "식용유" 1 "스푼" 120),
        (New-Ingredient "물" 150 "ml" 0 "per_100")
    )

    $riceIngredients = @(
        (New-Ingredient "밥" 2 "공기" 300),
        (New-Ingredient "주재료" 220 "g" 170 "per_100"),
        (New-Ingredient "양파" 0.5 "개" 40),
        (New-Ingredient "대파" 0.5 "대" 30),
        (New-Ingredient "다진 마늘" 1 "스푼" 130),
        (New-Ingredient "간장" 1.5 "스푼" 10),
        (New-Ingredient "고추장 또는 소스" 1 "스푼" 120),
        (New-Ingredient "참기름" 0.5 "스푼" 90)
    )

    $bakeIngredients = @(
        (New-Ingredient "주재료" 250 "g" 220 "per_100"),
        (New-Ingredient "버터 또는 오일" 20 "g" 720 "per_100"),
        (New-Ingredient "양파" 0.3 "개" 40),
        (New-Ingredient "다진 마늘" 0.5 "스푼" 130),
        (New-Ingredient "소금" 0.2 "스푼" 0),
        (New-Ingredient "후추" 0.1 "스푼" 0),
        (New-Ingredient "설탕 또는 시럽" 1 "스푼" 400),
        (New-Ingredient "물 또는 우유" 200 "ml" 60 "per_100")
    )

    $drinkIngredients = @(
        (New-Ingredient "주재료" 150 "g" 70 "per_100"),
        (New-Ingredient "우유 또는 물" 250 "ml" 60 "per_100"),
        (New-Ingredient "얼음" 6 "개" 0),
        (New-Ingredient "시럽" 1 "스푼" 320),
        (New-Ingredient "꿀" 0.5 "스푼" 300),
        (New-Ingredient "레몬즙" 0.5 "스푼" 4),
        (New-Ingredient "소금" 0.05 "스푼" 0),
        (New-Ingredient "토핑" 1 "스푼" 70)
    )

    $isSoup = $DishName -match "국|탕|찌개|전골|수프"
    $isNoodle = $DishName -match "면|국수|우동|소바|파스타|라자냐|리조또|팟타이|탄탄면|짜장|짬뽕|고렝"
    $isRice = $DishName -match "덮밥|볶음밥|라이스|동$|동 "
    $isBake = $DishName -match "전$|전 |타코야키|팬케이크|토스트|브라우니|케이크|그라탱"
    $isDrink = $Category -eq "디저트/음료" -and $DishName -match "스무디|라떼"

    $ingredients = $defaultIngredients
    if ($isSoup) { $ingredients = $soupIngredients }
    elseif ($isNoodle) { $ingredients = $noodleIngredients }
    elseif ($isRice) { $ingredients = $riceIngredients }
    elseif ($isBake) { $ingredients = $bakeIngredients }
    elseif ($isDrink) { $ingredients = $drinkIngredients }

    $instructions = @(
        [ordered]@{ step = 1; description = "$DishName 재료를 손질해 한 번에 조리할 수 있게 준비합니다." },
        [ordered]@{ step = 2; description = "팬 또는 냄비를 예열하고 기름을 두른 뒤 향채를 2분간 볶아 향을 냅니다." },
        [ordered]@{ step = 3; description = "주재료를 넣어 중불에서 5분간 익히며 수분을 조절합니다." },
        [ordered]@{ step = 4; description = "양념을 넣고 약불에서 8분간 더 조리해 맛을 맞춥니다." },
        [ordered]@{ step = 5; description = "불을 끄고 1분간 뜸을 들인 뒤 접시에 담아 마무리합니다." }
    )

    if ($isDrink) {
        $instructions = @(
            [ordered]@{ step = 1; description = "$DishName 재료를 계량하고 컵과 블렌더를 준비합니다." },
            [ordered]@{ step = 2; description = "액체 재료와 주재료를 넣고 30초간 1차 블렌딩합니다." },
            [ordered]@{ step = 3; description = "얼음을 넣고 40초간 곱게 갈아 농도를 맞춥니다." },
            [ordered]@{ step = 4; description = "시럽으로 단맛을 보정하고 10초간 짧게 다시 섞습니다." },
            [ordered]@{ step = 5; description = "컵에 담고 토핑을 올려 바로 제공합니다." }
        )
    }

    return [ordered]@{
        ingredients = $ingredients
        instructions = $instructions
    }
}

$korean = @(
    "김치볶음밥","제육볶음","오징어볶음","닭볶음탕","갈비찜","부대찌개","육개장","감자탕","순대국","콩나물국밥",
    "비빔냉면","물냉면","칼국수","잔치국수","수제비","해물파전","불고기전골","동태찌개","알탕","코다리조림",
    "고등어조림","갈치조림","닭한마리","김치전","감자전","깻잎전","떡만두국","떡국","어묵탕","닭개장",
    "설렁탕","곰탕","멸치국수","김치말이국수","비빔국수","쭈꾸미볶음","낙지볶음","한식잡채","차돌된장찌개","김치수제비"
)

$japanese = @(
    "규동","오야코동","가츠동","돈카츠","카레우동","자루소바","텐동","스키야키","야키소바","오코노미야키",
    "타코야키","미소시루","연어동","장어덮밥","유부초밥"
)

$chinese = @(
    "마파두부","깐풍기","유린기","탕수육","짜장면","짬뽕","고추잡채","팔보채","토마토달걀볶음","탄탄면"
)

$western = @(
    "스파게티 볼로네제","까르보나라","알리오올리오","라자냐","리조또","버섯크림파스타","토마토수프","감바스 알 아히요","치킨 알프레도","미트볼 스파게티",
    "그릭샐러드","시저샐러드","햄버거스테이크","비프스튜","포테이토그라탱","프렌치토스트","팬케이크","에그베네딕트","치킨파르미지아나","바질페스토파스타"
)

$asian = @(
    "팟타이","똠얌꿍","나시고렝","미고렝","하이난치킨라이스","카오팟","반미샌드위치","분짜","탄두리치킨","버터치킨커리"
)

$dessertDrink = @(
    "초콜릿브라우니","티라미수","치즈케이크","바나나스무디","딸기라떼"
)

$catalog = New-Object System.Collections.Generic.List[object]
foreach ($name in $korean) { $catalog.Add([ordered]@{ name = $name; category = "한식" }) }
foreach ($name in $japanese) { $catalog.Add([ordered]@{ name = $name; category = "일식" }) }
foreach ($name in $chinese) { $catalog.Add([ordered]@{ name = $name; category = "중식" }) }
foreach ($name in $western) { $catalog.Add([ordered]@{ name = $name; category = "양식" }) }
foreach ($name in $asian) { $catalog.Add([ordered]@{ name = $name; category = "아시안" }) }
foreach ($name in $dessertDrink) { $catalog.Add([ordered]@{ name = $name; category = "디저트/음료" }) }

if ($catalog.Count -ne 100) {
    throw "Catalog count must be 100, actual: $($catalog.Count)"
}

$colorByCategory = @{
    "한식" = "#F97316"
    "일식" = "#0EA5E9"
    "중식" = "#EF4444"
    "양식" = "#22C55E"
    "아시안" = "#A855F7"
    "디저트/음료" = "#EC4899"
}

$difficultyCycle = @("easy","medium","hard")

$recipes = Get-Content -Encoding UTF8 -Raw $recipesPath | ConvertFrom-Json

$added = 0
for ($i = 0; $i -lt $catalog.Count; $i++) {
    $entry = $catalog[$i]
    $key = "popular{0:d3}" -f ($i + 1)
    if ($recipes.PSObject.Properties.Name -contains $key) {
        continue
    }

    $template = Get-TemplateData -DishName $entry.name -Category $entry.category
    $difficulty = $difficultyCycle[$i % $difficultyCycle.Count]
    $servings = if ($entry.category -eq "디저트/음료") { 2 } else { 2 + ($i % 3) }
    $cookTime = if ($entry.category -eq "디저트/음료") { 12 + ($i % 6) } else { 20 + ($i % 25) }

    $recipeObj = [ordered]@{
        name = $entry.name
        category = $entry.category
        difficulty = $difficulty
        cook_time_minutes = $cookTime
        color = $colorByCategory[$entry.category]
        servings = $servings
        ingredients = $template.ingredients
        instructions = $template.instructions
    }

    Add-Member -InputObject $recipes -MemberType NoteProperty -Name $key -Value $recipeObj
    $added++
}

$json = $recipes | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($recipesPath, $json, [System.Text.UTF8Encoding]::new($false))

Write-Output "added=$added total=$((($recipes.PSObject.Properties) | Measure-Object).Count)"

