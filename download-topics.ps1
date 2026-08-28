# Downloads all topic detail JSONs for the full-stack roadmap from roadmap.sh
# Each topic is fetched from https://roadmap.sh/full-stack/<topicId>.json
# Saves them into the data/topics/ folder.

$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'
$dataDir = Join-Path $base 'data'
$topicsDir = Join-Path $dataDir 'topics'
New-Item -ItemType Directory -Path $topicsDir -Force | Out-Null

$roadmap = Get-Content (Join-Path $dataDir 'roadmap.json') -Raw | ConvertFrom-Json

# Nodes that are links to OTHER roadmaps (not topics with their own resources)
$hrefNodes = @('https://roadmap.sh/frontend','https://roadmap.sh/backend','https://roadmap.sh/devops','https://roadmap.sh/aws','https://roadmap.sh')

# Structural / instructional nodes that don't have topic content
$skipLabels = @(
  'Continue Learning with following relevant tracks',
  'Full Stack',
  'Checkpoint',
  'Feel free to skip these and revisit after learning Backend',
  'Start Backend Development',
  'You can pick any backend programming language',
  'Backend Starts here',
  'DevOps starts here',
  'Basic AWS Services',
  'Use the checkpoints and do not forget to practice what you learn',
  'Key topics to learn',
  'Project ideas and suggestions',
  'If you are already a full-stack developer you should visit the following tracks',
  'Target audience for this roadmap is absolute beginners',
  'Find the detailed version of this roadmap along with other similar roadmaps',
  'roadmap.sh'
)

$candidates = $roadmap.nodes | Where-Object {
  $_.data.label -and
  $_.data.label -notmatch 'horizontal|vertical' -and
  -not ($hrefNodes -contains $_.data.href) -and
  -not ($skipLabels | Where-Object { $_.data.label -like "*$_*" })
}

Write-Host "Candidate topic nodes: $($candidates.Count)"

$downloaded = 0
$failed = @()
$empty = @()

foreach ($node in $candidates) {
  $id = $node.id
  $label = $node.data.label
  $url = "https://roadmap.sh/full-stack/$id.json"
  $outFile = Join-Path $topicsDir "$id.json"

  try {
    $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    $content = $resp.Content
    if ($content -and $content.Trim().StartsWith('{')) {
      $obj = $content | ConvertFrom-Json
      # Only keep if it has resources or a description (real topic content)
      if ($obj.resources -or $obj.description) {
        Set-Content -Path $outFile -Value $content -Encoding UTF8
        $downloaded++
        Write-Host "  OK  $label"
      } else {
        $empty += $label
        Write-Host "  EMPTY  $label"
      }
    } else {
      $failed += $label
      Write-Host "  FAIL (no json)  $label"
    }
  } catch {
    $failed += $label
    Write-Host "  ERROR  $label : $($_.Exception.Message)"
  }
}

Write-Host ""
Write-Host "Downloaded: $downloaded"
Write-Host "Empty (no content): $($empty.Count)"
Write-Host "Failed: $($failed.Count)"
if ($failed.Count -gt 0) { Write-Host "Failed list: $($failed -join ', ')" }
