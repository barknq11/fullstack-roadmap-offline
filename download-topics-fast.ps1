$base = "D:\FullStack-Roadmap-Offline"
$dataDir = Join-Path $base "data"
$topicDir = Join-Path $dataDir "topics"
if (-not (Test-Path $topicDir)) { New-Item -ItemType Directory -Path $topicDir -Force | Out-Null }

$slugs = @(
  'frontend-beginner','backend-beginner','devops-beginner','git-github-beginner',
  'python','python-data-analysis','sql','javascript','typescript','nodejs',
  'java','cpp','rust','golang','php','kotlin',
  'html','css','swift-ui','shell-bash',
  'laravel','django','ruby','ruby-on-rails',
  'full-stack','frontend','backend','devops','aws'
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
