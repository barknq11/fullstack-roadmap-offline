$base = "D:\FullStack-Roadmap-Offline"
$dataDir = Join-Path $base "data"
$topicDir = Join-Path $dataDir "topics"
if (-not (Test-Path $topicDir)) { New-Item -ItemType Directory -Path $topicDir -Force | Out-Null }

# All roadmap slugs from generate-all.ps1
$slugs = @(
  'ai-agents','ai-and-data-scientist','ai-engineer','ai-product-builders','ai-red-teaming',
  'android','angular','api-design','api-security','asp-net-core','aws',
  'backend','backend-beginner','backend-performance','bi-analyst','c',
  'claude-code','cloudflare','code-review','computer-science','cpp',
  'css','data-analyst','data-engineer','data-structures-algorithms','design-architecture',
  'design-system','developer-relations','devops','devops-beginner','devsecops',
  'django','docker','elasticsearch','engineering-manager','flutter',
  'forward-deployed-engineer','frontend','frontend-beginner','frontend-performance','full-stack',
  'game-developer','git-and-github','git-and-github-beginner','go','graphql',
  'html','ios','java','javascript','kotlin',
  'kubernetes','laravel','leetcode','linux','machine-learning',
  'mlops','mongodb','network-engineer','next-js','nodejs',
  'openclaw','php','postgresql','power-bi','product-design',
  'product-manager','prompt-engineering','python','python-for-data-analysis','qa',
  'r','react','react-native','redis','ruby',
  'ruby-on-rails','rust','scala','server-side-game-developer','shell-bash',
  'software-architect','spring-boot','sql','swift-swift-ui','system-design',
  'technical-writer','terraform','typescript','ux-design','vibe-coding',
  'vue','wordpress'
)

# Phase 1: Collect all needed node IDs
$allNodes = @()
foreach ($slug in $slugs) {
  $roadmapFile = Join-Path $dataDir "$slug\roadmap.json"
  if (-not (Test-Path $roadmapFile)) { continue }
  $json = Get-Content $roadmapFile -Raw | ConvertFrom-Json
  foreach ($node in $json.nodes) {
    if ($node.type -ne 'topic' -and $node.type -ne 'subtopic') { continue }
    $detailFile = Join-Path $topicDir "$($node.id).json"
    if (-not (Test-Path $detailFile)) {
      $allNodes += @{ slug=$slug; id=$node.id }
    }
  }
}
Write-Host "Need to download $($allNodes.Count) topic detail files"

# Phase 2: Download in batches using parallel curl
$found = 0; $missing = 0; $batchSize = 20
for ($i = 0; $i -lt $allNodes.Count; $i += $batchSize) {
  $batch = $allNodes[$i..([Math]::Min($i+$batchSize-1, $allNodes.Count-1))]
  $jobs = @()
  foreach ($node in $batch) {
    $detailFile = Join-Path $topicDir "$($node.id).json"
    $url = "https://roadmap.sh/$($node.slug)/$($node.id).json"
    $jobs += Start-Job -ScriptBlock {
      param($url, $detailFile)
      try {
        $resp = & curl.exe -s $url --connect-timeout 5 --max-time 10
        if ($resp -match '"description"') {
          [System.IO.File]::WriteAllText($detailFile, $resp, [System.Text.UTF8Encoding]::new($false))
          return $true
        }
      } catch {}
      return $false
    } -ArgumentList $url, $detailFile
  }
  $results = $jobs | Wait-Job | Receive-Job
  $jobs | Remove-Job -Force
  $found += ($results | Where-Object { $_ -eq $true }).Count
  $missing += ($results | Where-Object { $_ -ne $true }).Count
  Write-Host "  Batch $([int]($i/$batchSize)+1): $found found, $missing missing so far"
}
Write-Host "`nDone: $found topics with details, $missing not found"
