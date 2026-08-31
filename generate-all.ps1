# Generates the comprehensive offline site with all roadmaps + graph visualization
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

$roadmapSlugs = @(
  # Original role-based
  'full-stack','frontend','backend','devops','aws',
  # Absolute Beginners
  'frontend-beginner','backend-beginner','devops-beginner',
  # Languages / Platforms
  'python','sql','javascript','typescript','nodejs',
  'java','cpp','rust','golang','php','kotlin',
  'swift-ui',
  # Frameworks
  'ruby-on-rails'
)
$roadmapMeta = @{
  # Original
  'full-stack'           = @{ color='#2563eb'; icon='FS'; title='Full Stack Developer' }
  'frontend'             = @{ color='#16a34a'; icon='FE'; title='Frontend Developer' }
  'backend'              = @{ color='#9333ea'; icon='BE'; title='Backend Developer' }
  'devops'               = @{ color='#ea580c'; icon='DO'; title='DevOps Engineer' }
  'aws'                  = @{ color='#f59e0b'; icon='AW'; title='AWS Cloud Engineer' }
  # Absolute Beginners
  'frontend-beginner'    = @{ color='#3b82f6'; icon='FB'; title='Frontend Beginner' }
  'backend-beginner'     = @{ color='#22c55e'; icon='BB'; title='Backend Beginner' }
  'devops-beginner'      = @{ color='#f97316'; icon='DB'; title='DevOps Beginner' }
  # Languages / Platforms
  'python'               = @{ color='#3776ab'; icon='PY'; title='Python' }
  'sql'                  = @{ color='#e38c00'; icon='SQ'; title='SQL' }
  'javascript'           = @{ color='#f7df1e'; icon='JS'; title='JavaScript' }
  'typescript'           = @{ color='#3178c6'; icon='TS'; title='TypeScript' }
  'nodejs'               = @{ color='#339933'; icon='NJ'; title='Node.js' }
  'java'                 = @{ color='#ed8b00'; icon='JV'; title='Java' }
  'cpp'                  = @{ color='#00599c'; icon='C+'; title='C++' }
  'rust'                 = @{ color='#dea584'; icon='RS'; title='Rust' }
  'golang'               = @{ color='#00add8'; icon='GO'; title='Go' }
  'php'                  = @{ color='#777bb4'; icon='PH'; title='PHP' }
  'kotlin'               = @{ color='#7f52ff'; icon='KT'; title='Kotlin' }
  'swift-ui'             = @{ color='#fa7343'; icon='SW'; title='Swift & SwiftUI' }
  # Frameworks
  'ruby-on-rails'        = @{ color='#cc0000'; icon='RR'; title='Ruby on Rails' }
}

# Load shared topic details (all in data/topics/)
$sharedTopicDir = Join-Path $base "data\topics"
$sharedTopics = @{}
if (Test-Path $sharedTopicDir) {
  foreach ($file in Get-ChildItem (Join-Path $sharedTopicDir '*.json')) {
    try {
      $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
      if ($t.nodeId) { $sharedTopics[$t.nodeId] = $t }
    } catch {}
  }
}
Write-Host "Loaded $($sharedTopics.Count) shared topic detail files"

# Load all roadmap data + match topics
$allData = @{}
foreach ($slug in $roadmapSlugs) {
  $rJson = Get-Content (Join-Path $base "data\$slug\roadmap.json") -Raw | ConvertFrom-Json
  $slugTopicDir = Join-Path $base "data\$slug\topics"
  $topics = @()
  foreach ($node in $rJson.nodes) {
    if ($node.type -ne 'topic' -and $node.type -ne 'subtopic') { continue }
    $nodeId = $node.id
    $detail = $null
    if ($sharedTopics.ContainsKey($nodeId)) { $detail = $sharedTopics[$nodeId] }
    elseif (Test-Path $slugTopicDir) {
      $slugFile = Join-Path $slugTopicDir "$nodeId.json"
      if (Test-Path $slugFile) { try { $detail = Get-Content $slugFile -Raw | ConvertFrom-Json } catch {} }
    }
    if ($detail) { $topics += $detail }
  }
  $allData[$slug] = @{
    roadmap = $rJson
    topics  = $topics
  }
}

# Build the payload JSON
$payload = @{
  slugs = $roadmapSlugs
  meta  = $roadmapMeta
  roadmaps = @{}
}

foreach ($slug in $roadmapSlugs) {
  $rd = $allData[$slug]
  $r = $rd.roadmap
  $nodeMap = @{}
  foreach ($n in $r.nodes) {
    if ($n.data.label) {
      $nodeMap[$n.id] = @{
        id     = $n.id
        type   = $n.type
        label  = $n.data.label
        x      = [math]::Round($n.position.x, 0)
        y      = [math]::Round($n.position.y, 0)
      }
    }
  }
  $edgeList = @()
  foreach ($e in $r.edges) {
    if ($nodeMap.ContainsKey($e.source) -and $nodeMap.ContainsKey($e.target)) {
      $edgeList += @{
        source = $e.source
        target = $e.target
      }
    }
  }
  $topicsArr = @()
  foreach ($t in $rd.topics) {
    $label = ''
    $nodeType = ''
    if ($nodeMap.ContainsKey($t.nodeId)) {
      $label = $nodeMap[$t.nodeId].label
      $nodeType = $nodeMap[$t.nodeId].type
    }
    if ($nodeType -eq 'button' -or $nodeType -eq 'horizontal' -or $nodeType -eq 'vertical' -or $nodeType -eq 'label') { continue }
    $desc = if ($t.description) { if ($t.description.Length -gt 300) { $t.description.Substring(0,300) + '...' } else { $t.description } } else { '' }
    $res = if ($t.resources) { $t.resources | Select-Object -First 4 } else { @() }
    $topicObj = @{
      nodeId      = $t.nodeId
      title       = $label
      description = $desc
      resources   = $res
    }
    $topicsArr += $topicObj
  }

  $payload.roadmaps[$slug] = @{
    dimensions = $r.dimensions
    nodes      = $nodeMap
    edges      = $edgeList
    topics     = $topicsArr
  }
}

$json = $payload | ConvertTo-Json -Depth 10 -Compress
$json = $json.Replace('</', '<\/')

Write-Host "Building HTML with $(($roadmapSlugs | ForEach-Object { $allData[$_].topics.Count } | Measure-Object -Sum).Sum) total topics across $($roadmapSlugs.Count) roadmaps..."

# Read the HTML template and inject data
$outFile = Join-Path $base 'index.html'
$template = Get-Content $outFile -Raw
$template = $template.Replace('PAYLOAD_PLACEHOLDER', "PAYLOAD_DATA = $json")
Set-Content -Path $outFile -Value $template -Encoding UTF8

$size = [math]::Round((Get-Item $outFile).Length/1KB, 1)
Write-Host "Generated: $outFile ($size KB)"
Write-Host "Total topics: $(($roadmapSlugs | ForEach-Object { $allData[$_].topics.Count } | Measure-Object -Sum).Sum)"
