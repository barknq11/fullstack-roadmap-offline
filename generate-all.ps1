# Generates the offline site with lazy-loaded data files
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

$roadmapSlugs = @(
  'full-stack','frontend','backend','devops','aws',
  'frontend-beginner','backend-beginner','devops-beginner',
  'python','sql','javascript','typescript','nodejs',
  'java','cpp','rust','golang','php','kotlin',
  'swift-ui','ruby-on-rails'
)
$roadmapMeta = @{
  'full-stack'           = @{ color='#2563eb'; icon='FS'; title='Full Stack Developer' }
  'frontend'             = @{ color='#16a34a'; icon='FE'; title='Frontend Developer' }
  'backend'              = @{ color='#9333ea'; icon='BE'; title='Backend Developer' }
  'devops'               = @{ color='#ea580c'; icon='DO'; title='DevOps Engineer' }
  'aws'                  = @{ color='#f59e0b'; icon='AW'; title='AWS Cloud Engineer' }
  'frontend-beginner'    = @{ color='#3b82f6'; icon='FB'; title='Frontend Beginner' }
  'backend-beginner'     = @{ color='#22c55e'; icon='BB'; title='Backend Beginner' }
  'devops-beginner'      = @{ color='#f97316'; icon='DB'; title='DevOps Beginner' }
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
  'ruby-on-rails'        = @{ color='#cc0000'; icon='RR'; title='Ruby on Rails' }
}

# Topological sort function (Kahn's algorithm)
function Invoke-TopologicalSort {
  param([hashtable]$Nodes, [array]$Edges)
  
  $inDegree = @{}
  $adj = @{}
  foreach ($id in $Nodes.Keys) { $inDegree[$id] = 0; $adj[$id] = @() }
  foreach ($e in $Edges) {
    if ($inDegree.ContainsKey($e.target)) { $inDegree[$e.target]++ }
    if ($adj.ContainsKey($e.source)) { $adj[$e.source] += $e.target }
  }
  
  $queue = [System.Collections.Queue]::new()
  foreach ($id in $Nodes.Keys) { if ($inDegree[$id] -eq 0) { $queue.Enqueue($id) } }
  
  $sorted = @()
  while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    $sorted += $current
    foreach ($next in $adj[$current]) {
      $inDegree[$next]--
      if ($inDegree[$next] -eq 0) { $queue.Enqueue($next) }
    }
  }
  
  # Add orphans (disconnected nodes) alphabetically
  foreach ($id in ($Nodes.Keys | Sort-Object { $Nodes[$_].label })) {
    if ($sorted -notcontains $id) { $sorted += $id }
  }
  
  return $sorted
}

# Load shared topic details
$sharedTopicDir = Join-Path $base "data\topics"
$sharedTopics = @{}
if (Test-Path $sharedTopicDir) {
  foreach ($file in Get-ChildItem (Join-Path $sharedTopicDir '*.json')) {
    try { $t = Get-Content $file.FullName -Raw | ConvertFrom-Json; if ($t.nodeId) { $sharedTopics[$t.nodeId] = $t } } catch {}
  }
}
Write-Host "Loaded $($sharedTopics.Count) shared topic detail files"

# Build lightweight index (for home page)
$index = @{ slugs = $roadmapSlugs; meta = $roadmapMeta; counts = @{} }

# Build per-roadmap detail files
$dataDir = Join-Path $base "data\web"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

foreach ($slug in $roadmapSlugs) {
  $rJson = Get-Content (Join-Path $base "data\$slug\roadmap.json") -Raw | ConvertFrom-Json
  $slugTopicDir = Join-Path $base "data\$slug\topics"
  
  # Build node map (only topic/subtopic nodes for sorting)
  $nodeMap = @{}
  $topicNodes = @{}
  foreach ($n in $rJson.nodes) {
    if ($n.data.label) {
      $nodeMap[$n.id] = @{
        id = $n.id; type = $n.type; label = $n.data.label
        x = [math]::Round($n.position.x, 0); y = [math]::Round($n.position.y, 0)
      }
      if ($n.type -eq 'topic' -or $n.type -eq 'subtopic') {
        $topicNodes[$n.id] = $nodeMap[$n.id]
      }
    }
  }
  
  # Build edges
  $edgeList = @()
  foreach ($e in $rJson.edges) {
    if ($nodeMap.ContainsKey($e.source) -and $nodeMap.ContainsKey($e.target)) {
      $edgeList += @{ source = $e.source; target = $e.target }
    }
  }
  
  # Topological sort for ordering
  $sortedIds = Invoke-TopologicalSort -Nodes $topicNodes -Edges $edgeList
  
  # Build prerequisite/leadsTo maps from edges
  $prereqMap = @{}  # target -> [sources]
  $leadsToMap = @{} # source -> [targets]
  foreach ($id in $topicNodes.Keys) { $prereqMap[$id] = @(); $leadsToMap[$id] = @() }
  foreach ($e in $edgeList) {
    if ($topicNodes.ContainsKey($e.source) -and $topicNodes.ContainsKey($e.target)) {
      $prereqMap[$e.target] += $e.source
      $leadsToMap[$e.source] += $e.target
    }
  }
  
  # Build topics with full descriptions, prerequisites, leadsTo, and order
  $topicsArr = @()
  $orderIndex = 0
  foreach ($nodeId in $sortedIds) {
    $detail = $null
    if ($sharedTopics.ContainsKey($nodeId)) { $detail = $sharedTopics[$nodeId] }
    elseif (Test-Path $slugTopicDir) {
      $slugFile = Join-Path $slugTopicDir "$nodeId.json"
      if (Test-Path $slugFile) { try { $detail = Get-Content $slugFile -Raw | ConvertFrom-Json } catch {} }
    }
    $label = $topicNodes[$nodeId].label
    $desc = ''
    $fullDesc = ''
    $res = @()
    if ($detail) {
      $fullDesc = if ($detail.description) { $detail.description } else { '' }
      $desc = if ($fullDesc.Length -gt 300) { $fullDesc.Substring(0,300) + '...' } else { $fullDesc }
      $res = if ($detail.resources) { $detail.resources | Select-Object -First 4 } else { @() }
    }
    
    # Resolve prerequisite/leadsTo nodeIds to labels
    $prereqLabels = @()
    foreach ($prereqId in $prereqMap[$nodeId]) {
      if ($topicNodes.ContainsKey($prereqId)) { $prereqLabels += @{ nodeId = $prereqId; title = $topicNodes[$prereqId].label } }
    }
    $leadsToLabels = @()
    foreach ($leadsToId in $leadsToMap[$nodeId]) {
      if ($topicNodes.ContainsKey($leadsToId)) { $leadsToLabels += @{ nodeId = $leadsToId; title = $topicNodes[$leadsToId].label } }
    }
    
    $topicsArr += @{
      nodeId = $nodeId
      title = $label
      description = $desc
      fullDescription = $fullDesc
      resources = $res
      prerequisites = $prereqLabels
      leadsTo = $leadsToLabels
      order = $orderIndex
    }
    $orderIndex++
  }
  
  $index.counts[$slug] = $topicsArr.Count
  
  # Write per-roadmap detail file
  $detailPayload = @{ dimensions = $rJson.dimensions; nodes = $nodeMap; edges = $edgeList; topics = $topicsArr }
  $detailJson = $detailPayload | ConvertTo-Json -Depth 10 -Compress
  $detailJson = $detailJson.Replace('</', '<\/')
  Set-Content -Path (Join-Path $dataDir "$slug.json") -Value $detailJson -Encoding UTF8
  
  Write-Host "  $slug : $($topicsArr.Count) topics, $([math]::Round((Get-Item (Join-Path $dataDir "$slug.json")).Length/1KB,0)) KB"
}

# Write index file
$indexJson = $index | ConvertTo-Json -Depth 5 -Compress
Set-Content -Path (Join-Path $dataDir "index.json") -Value $indexJson -Encoding UTF8

$indexSize = [math]::Round((Get-Item (Join-Path $dataDir "index.json")).Length/1KB, 0)
$htmlSize = [math]::Round((Get-Item (Join-Path $base 'index.html')).Length/1KB, 0)
$totalTopics = 0; foreach ($s in $roadmapSlugs) { $totalTopics += $index.counts[$s] }
Write-Host "`nDone! HTML: $htmlSize KB, Index: $indexSize KB"
Write-Host "Total topics: $totalTopics"
