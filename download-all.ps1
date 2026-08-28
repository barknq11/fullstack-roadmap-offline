# Downloads all roadmaps + their topic details from roadmap.sh
# Roadmaps: frontend, backend, devops, aws (plus existing full-stack)

$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'
$topicsBase = Join-Path $base 'data\topics'

$roadmaps = @('full-stack','frontend','backend','devops','aws')

foreach ($slug in $roadmaps) {
  Write-Host "`n=== $slug ===" -ForegroundColor Cyan

  # Download roadmap JSON
  $rDir = Join-Path $base "data\$slug"
  New-Item -ItemType Directory -Path $rDir -Force | Out-Null
  $rFile = Join-Path $rDir 'roadmap.json'
  $url = "https://roadmap.sh/api/v1-official-roadmap/$slug"
  $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
  Set-Content -Path $rFile -Value $resp.Content -Encoding UTF8
  $rJson = $resp.Content | ConvertFrom-Json
  Write-Host "  Roadmap: $($rJson.nodes.Count) nodes"

  # Topic detail endpoint pattern: https://roadmap.sh/<slug>/<nodeId>.json
  # Identify candidate topic nodes
  $labeled = $rJson.nodes | Where-Object { $_.data.label -and $_.data.label -notmatch 'horizontal|vertical' }
  $topicDir = Join-Path $rDir 'topics'
  New-Item -ItemType Directory -Path $topicDir -Force | Out-Null

  $downloaded = 0
  foreach ($node in $labeled) {
    $nid = $node.id
    $tUrl = "https://roadmap.sh/$slug/$nid.json"
    $tFile = Join-Path $topicDir "$nid.json"
    try {
      $tResp = Invoke-WebRequest -Uri $tUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
      $tContent = $tResp.Content
      if ($tContent -and $tContent.Trim().StartsWith('{')) {
        $tObj = $tContent | ConvertFrom-Json
        if ($tObj.description -or ($tObj.resources -and $tObj.resources.Count -gt 0)) {
          Set-Content -Path $tFile -Value $tContent -Encoding UTF8
          $downloaded++
        }
      }
    } catch {
      # skip failed nodes
    }
  }
  Write-Host "  Topics: $downloaded downloaded out of $($labeled.Count) labeled nodes"
}

Write-Host "`nAll roadmaps downloaded!" -ForegroundColor Green
