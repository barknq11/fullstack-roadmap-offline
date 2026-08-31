$base = "D:\FullStack-Roadmap-Offline"
$dataDir = Join-Path $base "data"
$topicDir = Join-Path $dataDir "topics"

$slugs = @(
  'frontend-beginner','backend-beginner','devops-beginner','git-github-beginner',
  'python','python-data-analysis','sql','javascript','typescript','nodejs',
  'java','cpp','rust','golang','php','kotlin',
  'html','css','swift-ui','shell-bash',
  'laravel','django','ruby','ruby-on-rails'
)

$total = 0; $found = 0; $missing = 0
foreach ($slug in $slugs) {
  $roadmapFile = Join-Path $dataDir "$slug\roadmap.json"
  if (-not (Test-Path $roadmapFile)) { Write-Host "[SKIP] $slug - no roadmap.json"; continue }
  
  $json = Get-Content $roadmapFile -Raw | ConvertFrom-Json
  $nodes = $json.nodes
  if (-not $nodes) { Write-Host "[SKIP] $slug - no nodes"; continue }
  
  $count = 0; $downloaded = 0
  foreach ($node in $nodes) {
    if ($node.type -ne 'topic' -and $node.type -ne 'subtopic') { continue }
    $nodeId = $node.id
    $detailFile = Join-Path $topicDir "$nodeId.json"
    
    if (Test-Path $detailFile) { $count++; $found++; continue }
    
    try {
      $resp = & curl.exe -s "https://roadmap.sh/$slug/$nodeId.json" --connect-timeout 5 --max-time 10
      if ($resp -match '"description"') {
        Set-Content -Path $detailFile -Value $resp -Encoding UTF8
        $count++; $downloaded++; $found++
      } else {
        $missing++
      }
    } catch { $missing++ }
    
    $total++
    if ($total % 50 -eq 0) { Write-Host "  Progress: $total checked, $found found, $downloaded downloaded..." }
  }
  Write-Host "[$slug] $count topics with details"
}

Write-Host "`nDone: $found topics with details, $missing not found, $total total checked"
