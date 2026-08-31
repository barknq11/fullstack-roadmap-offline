# Downloads all missing roadmap JSONs from GitHub
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

# GitHub directory name to our slug mapping
$githubToSlug = @{
  "ai-agents" = "ai-agents"
  "ai-data-scientist" = "ai-and-data-scientist"
  "ai-engineer" = "ai-engineer"
  "ai-product-builder" = "ai-product-builders"
  "ai-red-teaming" = "ai-red-teaming"
  "android" = "android"
  "angular" = "angular"
  "api-design" = "api-design"
  "aspnet-core" = "asp-net-core"
  "aws" = "aws"
  "backend-beginner" = "backend-beginner"
  "backend" = "backend"
  "bi-analyst" = "bi-analyst"
  "blockchain" = "blockchain"
  "c" = "c"
  "claude-code" = "claude-code"
  "cloudflare" = "cloudflare"
  "code-review" = "code-review"
  "computer-science" = "computer-science"
  "cpp" = "cpp"
  "css" = "css"
  "cyber-security" = "cyber-security"
  "data-analyst" = "data-analyst"
  "data-engineer" = "data-engineer"
  "datastructures-and-algorithms" = "data-structures-algorithms"
  "design-system" = "design-system"
  "devops-beginner" = "devops-beginner"
  "devops" = "devops"
  "devrel" = "developer-relations"
  "devsecops" = "devsecops"
  "django" = "django"
  "docker" = "docker"
  "elasticsearch" = "elasticsearch"
  "engineering-manager" = "engineering-manager"
  "flutter" = "flutter"
  "forward-deployed-engineer" = "forward-deployed-engineer"
  "frontend-beginner" = "frontend-beginner"
  "frontend" = "frontend"
  "full-stack" = "full-stack"
  "game-developer" = "game-developer"
  "git-github-beginner" = "git-and-github-beginner"
  "git-github" = "git-and-github"
  "golang" = "go"
  "graphql" = "graphql"
  "html" = "html"
  "ios" = "ios"
  "java" = "java"
  "javascript" = "javascript"
  "kotlin" = "kotlin"
  "kubernetes" = "kubernetes"
  "laravel" = "laravel"
  "leetcode" = "leetcode"
  "linux" = "linux"
  "machine-learning" = "machine-learning"
  "mlops" = "mlops"
  "mongodb" = "mongodb"
  "network-engineer" = "network-engineer"
  "nextjs" = "next-js"
  "nodejs" = "nodejs"
  "openclaw" = "openclaw"
  "php" = "php"
  "postgresql-dba" = "postgresql"
  "power-bi" = "power-bi"
  "product-design" = "product-design"
  "product-manager" = "product-manager"
  "prompt-engineering" = "prompt-engineering"
  "python-data-analysis" = "python-for-data-analysis"
  "python" = "python"
  "qa" = "qa"
  "r" = "r"
  "react-native" = "react-native"
  "react" = "react"
  "redis" = "redis"
  "ruby-on-rails" = "ruby-on-rails"
  "ruby" = "ruby"
  "rust" = "rust"
  "scala" = "scala"
  "server-side-game-developer" = "server-side-game-developer"
  "shell-bash" = "shell-bash"
  "software-architect" = "software-architect"
  "software-design-architecture" = "design-architecture"
  "spring-boot" = "spring-boot"
  "sql" = "sql"
  "swift-ui" = "swift-swift-ui"
  "system-design" = "system-design"
  "technical-writer" = "technical-writer"
  "terraform" = "terraform"
  "typescript" = "typescript"
  "ux-design" = "ux-design"
  "vibe-coding" = "vibe-coding"
  "vue" = "vue"
  "wordpress" = "wordpress"
}

# Find which ones we need to download
$existingSlugs = Get-ChildItem (Join-Path $base "data") -Directory | Select-Object -ExpandProperty Name
$toDownload = @()

foreach ($githubName in $githubToSlug.Keys) {
  $slug = $githubToSlug[$githubName]
  if ($slug -notin $existingSlugs) {
    $toDownload += @{ github = $githubName; slug = $slug }
  }
}

Write-Host "Need to download: $($toDownload.Count) roadmaps"

# Download function
function Download-Roadmap {
  param([string]$GithubName, [string]$Slug)
  
  $url = "https://roadmap.sh/api/v1-official-roadmap/$Slug"
  $destDir = Join-Path $base "data\$Slug"
  
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }
  
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    $json = $response.Content
    Set-Content -Path (Join-Path $destDir "roadmap.json") -Value $json -Encoding UTF8
    return $true
  } catch {
    Write-Host "  FAILED: $Slug - $($_.Exception.Message)"
    return $false
  }
}

# Download in batches of 5
$batchSize = 5
$success = 0
$failed = 0

for ($i = 0; $i -lt $toDownload.Count; $i += $batchSize) {
  $batch = $toDownload[$i..([Math]::Min($i + $batchSize - 1, $toDownload.Count - 1))]
  
  $jobs = @()
  foreach ($item in $batch) {
    $jobs += Start-Job -ScriptBlock {
      param($base, $github, $slug)
      
      $url = "https://roadmap.sh/api/v1-official-roadmap/$slug"
      $destDir = Join-Path $base "data\$slug"
      
      if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
      }
      
      try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        $json = $response.Content
        Set-Content -Path (Join-Path $destDir "roadmap.json") -Value $json -Encoding UTF8
        return @{ success = $true; slug = $slug }
      } catch {
        return @{ success = $false; slug = $slug; error = $_.Exception.Message }
      }
    } -ArgumentList $base, $item.github, $item.slug
  }
  
  $results = $jobs | Wait-Job | Receive-Job
  $jobs | Remove-Job -Force
  
  foreach ($result in $results) {
    if ($result.success) {
      $success++
      Write-Host "  OK: $($result.slug)"
    } else {
      $failed++
      Write-Host "  FAILED: $($result.slug) - $($result.error)"
    }
  }
  
  Write-Host "Progress: $($success + $failed)/$($toDownload.Count) (OK: $success, Failed: $failed)"
}

Write-Host "`nDone! Downloaded: $success, Failed: $failed"
