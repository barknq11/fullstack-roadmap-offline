# Generates the offline site with lazy-loaded data files
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

# All roadmaps with metadata
$roadmapMeta = @{
  # Role Based Roadmaps
  'full-stack'           = @{ color='#2563eb'; icon='FS'; title='Full Stack Developer'; category='Role Based' }
  'frontend'             = @{ color='#16a34a'; icon='FE'; title='Frontend Developer'; category='Role Based' }
  'backend'              = @{ color='#9333ea'; icon='BE'; title='Backend Developer'; category='Role Based' }
  'devops'               = @{ color='#ea580c'; icon='DO'; title='DevOps Engineer'; category='Role Based' }
  'devsecops'            = @{ color='#dc2626'; icon='DS'; title='DevSecOps'; category='Role Based' }
  'android'              = @{ color='#3ddc84'; icon='AN'; title='Android Developer'; category='Role Based' }
  'ios'                  = @{ color='#007aff'; icon='IO'; title='iOS Developer'; category='Role Based' }
  'data-analyst'         = @{ color='#17a2b8'; icon='DA'; title='Data Analyst'; category='Role Based' }
  'data-engineer'        = @{ color='#6f42c1'; icon='DE'; title='Data Engineer'; category='Role Based' }
  'ai-engineer'          = @{ color='#ff6b6b'; icon='AI'; title='AI Engineer'; category='Role Based' }
  'ai-and-data-scientist'= @{ color='#e83e8c'; icon='DS'; title='AI & Data Scientist'; category='Role Based' }
  'machine-learning'     = @{ color='#9b59b6'; icon='ML'; title='Machine Learning Engineer'; category='Role Based' }
  'mlops'                = @{ color='#3498db'; icon='MO'; title='MLOps Engineer'; category='Role Based' }
  'software-architect'   = @{ color='#95a5a6'; icon='SA'; title='Software Architect'; category='Role Based' }
  'technical-writer'     = @{ color='#1abc9c'; icon='TW'; title='Technical Writer'; category='Role Based' }
  'product-manager'      = @{ color='#e67e22'; icon='PM'; title='Product Manager'; category='Role Based' }
  'engineering-manager'  = @{ color='#2c3e50'; icon='EM'; title='Engineering Manager'; category='Role Based' }
  'developer-relations'  = @{ color='#9b59b6'; icon='DR'; title='Developer Relations'; category='Role Based' }
  'game-developer'       = @{ color='#27ae60'; icon='GD'; title='Game Developer'; category='Role Based' }
  'server-side-game-developer' = @{ color='#2ecc71'; icon='SG'; title='Server Side Game Dev'; category='Role Based' }
  'bi-analyst'           = @{ color='#f39c12'; icon='BI'; title='BI Analyst'; category='Role Based' }
  'network-engineer'     = @{ color='#34495e'; icon='NE'; title='Network Engineer'; category='Role Based' }
  'forward-deployed-engineer' = @{ color='#1abc9c'; icon='FD'; title='Forward Deployed Eng'; category='Role Based' }
  'ai-red-teaming'       = @{ color='#e74c3c'; icon='AR'; title='AI Red Teaming'; category='Role Based' }
  'ux-design'            = @{ color='#e91e63'; icon='UX'; title='UX Design'; category='Role Based' }
  
  # Skill Based - Languages
  'javascript'           = @{ color='#f7df1e'; icon='JS'; title='JavaScript'; category='Languages' }
  'typescript'           = @{ color='#3178c6'; icon='TS'; title='TypeScript'; category='Languages' }
  'python'               = @{ color='#3776ab'; icon='PY'; title='Python'; category='Languages' }
  'java'                 = @{ color='#ed8b00'; icon='JV'; title='Java'; category='Languages' }
  'go'                   = @{ color='#00add8'; icon='GO'; title='Go'; category='Languages' }
  'rust'                 = @{ color='#dea584'; icon='RS'; title='Rust'; category='Languages' }
  'c'                    = @{ color='#a8b9cc'; icon='C'; title='C Programming'; category='Languages' }
  'cpp'                  = @{ color='#00599c'; icon='C+'; title='C++'; category='Languages' }
  'php'                  = @{ color='#777bb4'; icon='PH'; title='PHP'; category='Languages' }
  'ruby'                 = @{ color='#cc342d'; icon='RB'; title='Ruby'; category='Languages' }
  'kotlin'               = @{ color='#7f52ff'; icon='KT'; title='Kotlin'; category='Languages' }
  'swift-swift-ui'       = @{ color='#fa7343'; icon='SW'; title='Swift & Swift UI'; category='Languages' }
  'scala'                = @{ color='#dc322f'; icon='SC'; title='Scala'; category='Languages' }
  'r'                    = @{ color='#276dc3'; icon='R'; title='R'; category='Languages' }
  
  # Skill Based - Frameworks & Libraries
  'react'                = @{ color='#61dafb'; icon='RE'; title='React'; category='Frameworks' }
  'vue'                  = @{ color='#42b883'; icon='VU'; title='Vue'; category='Frameworks' }
  'angular'              = @{ color='#dd0031'; icon='AG'; title='Angular'; category='Frameworks' }
  'next-js'              = @{ color='#000000'; icon='NX'; title='Next.js'; category='Frameworks' }
  'nodejs'               = @{ color='#339933'; icon='NJ'; title='Node.js'; category='Frameworks' }
  'spring-boot'          = @{ color='#6db33f'; icon='SB'; title='Spring Boot'; category='Frameworks' }
  'asp-net-core'         = @{ color='#512bd4'; icon='AS'; title='ASP.NET Core'; category='Frameworks' }
  'laravel'              = @{ color='#ff2d20'; icon='LA'; title='Laravel'; category='Frameworks' }
  'django'               = @{ color='#092e20'; icon='DJ'; title='Django'; category='Frameworks' }
  'ruby-on-rails'        = @{ color='#cc0000'; icon='RR'; title='Ruby on Rails'; category='Frameworks' }
  'flutter'              = @{ color='#02569b'; icon='FL'; title='Flutter'; category='Frameworks' }
  'react-native'         = @{ color='#61dafb'; icon='RN'; title='React Native'; category='Frameworks' }
  'wordpress'            = @{ color='#21759b'; icon='WP'; title='WordPress'; category='Frameworks' }
  
  # Skill Based - Web
  'html'                 = @{ color='#e34c26'; icon='HT'; title='HTML'; category='Web' }
  'css'                  = @{ color='#264de4'; icon='CS'; title='CSS'; category='Web' }
  'graphql'              = @{ color='#e10098'; icon='GQ'; title='GraphQL'; category='Web' }
  
  # Skill Based - DevOps & Cloud
  'aws'                  = @{ color='#ff9900'; icon='AW'; title='AWS'; category='DevOps & Cloud' }
  'docker'               = @{ color='#2496ed'; icon='DK'; title='Docker'; category='DevOps & Cloud' }
  'kubernetes'           = @{ color='#326ce5'; icon='K8'; title='Kubernetes'; category='DevOps & Cloud' }
  'terraform'            = @{ color='#7b42bc'; icon='TF'; title='Terraform'; category='DevOps & Cloud' }
  'linux'                = @{ color='#fcc624'; icon='LX'; title='Linux'; category='DevOps & Cloud' }
  'git-and-github'       = @{ color='#f05032'; icon='GH'; title='Git & GitHub'; category='DevOps & Cloud' }
  'cloudflare'           = @{ color='#f38020'; icon='CF'; title='Cloudflare'; category='DevOps & Cloud' }
  
  # Skill Based - Databases
  'sql'                  = @{ color='#e38c00'; icon='SQ'; title='SQL'; category='Databases' }
  'mongodb'              = @{ color='#47a248'; icon='MG'; title='MongoDB'; category='Databases' }
  'postgresql'           = @{ color='#336791'; icon='PG'; title='PostgreSQL'; category='Databases' }
  'redis'                = @{ color='#dc382d'; icon='RD'; title='Redis'; category='Databases' }
  'elasticsearch'        = @{ color='#005571'; icon='ES'; title='Elasticsearch'; category='Databases' }
  
  # Skill Based - CS Fundamentals
  'computer-science'     = @{ color='#2c3e50'; icon='CS'; title='Computer Science'; category='CS Fundamentals' }
  'system-design'        = @{ color='#34495e'; icon='SD'; title='System Design'; category='CS Fundamentals' }
  'data-structures-algorithms' = @{ color='#1abc9c'; icon='DS'; title='Data Structures & Algorithms'; category='CS Fundamentals' }
  'design-system'        = @{ color='#9b59b6'; icon='DS'; title='Design System'; category='CS Fundamentals' }
  'design-architecture'  = @{ color='#8e44ad'; icon='DA'; title='Design Architecture'; category='CS Fundamentals' }
  'api-design'           = @{ color='#3498db'; icon='AD'; title='API Design'; category='CS Fundamentals' }
  
  # Skill Based - AI & Emerging
  'ai-agents'            = @{ color='#ff6b6b'; icon='AA'; title='AI Agents'; category='AI & Emerging' }
  'ai-product-builders'  = @{ color='#e83e8c'; icon='AP'; title='AI Product Builders'; category='AI & Emerging' }
  'prompt-engineering'   = @{ color='#9b59b6'; icon='PE'; title='Prompt Engineering'; category='AI & Emerging' }
  'claude-code'          = @{ color='#d97706'; icon='CC'; title='Claude Code'; category='AI & Emerging' }
  'vibe-coding'          = @{ color='#8b5cf6'; icon='VC'; title='Vibe Coding'; category='AI & Emerging' }
  'leetcode'             = @{ color='#ffa11a'; icon='LC'; title='LeetCode'; category='AI & Emerging' }
  'openclaw'             = @{ color='#10b981'; icon='OC'; title='OpenClaw'; category='AI & Emerging' }
  
  # Absolute Beginners
  'frontend-beginner'    = @{ color='#3b82f6'; icon='FB'; title='Frontend Beginner'; category='Absolute Beginners' }
  'backend-beginner'     = @{ color='#22c55e'; icon='BB'; title='Backend Beginner'; category='Absolute Beginners' }
  'devops-beginner'      = @{ color='#f97316'; icon='DB'; title='DevOps Beginner'; category='Absolute Beginners' }
  'git-and-github-beginner' = @{ color='#f05032'; icon='GB'; title='Git & GitHub Beginner'; category='Absolute Beginners' }
  
  # Best Practices
  'api-security'         = @{ color='#dc3545'; icon='AS'; title='API Security'; category='Best Practices' }
  'backend-performance'  = @{ color='#28a745'; icon='BP'; title='Backend Performance'; category='Best Practices' }
  'frontend-performance' = @{ color='#17a2b8'; icon='FP'; title='Frontend Performance'; category='Best Practices' }
  'code-review'          = @{ color='#6c757d'; icon='CR'; title='Code Review'; category='Best Practices' }
  
  # Product Design
  'product-design'       = @{ color='#e91e63'; icon='PD'; title='Product Design'; category='Product Design' }
  
  # Power BI
  'power-bi'             = @{ color='#f2c811'; icon='PB'; title='Power BI'; category='Power BI' }
  
  # QA
  'qa'                   = @{ color='#6c757d'; icon='QA'; title='QA Engineer'; category='QA' }
  
  # Python for Data Analysis
  'python-for-data-analysis' = @{ color='#3776ab'; icon='PA'; title='Python for Data Analysis'; category='Python' }
  
  # shell-bash
  'shell-bash'           = @{ color='#4eaa25'; icon='SH'; title='Shell / Bash'; category='Shell' }
}

$roadmapSlugs = $roadmapMeta.Keys | Sort-Object

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
$categories = @{}
foreach ($slug in $roadmapSlugs) {
  $meta = $roadmapMeta[$slug]
  if ($meta) {
    $cat = $meta.category
    if (-not $categories.ContainsKey($cat)) { $categories[$cat] = @() }
    $categories[$cat] += $slug
  }
}
$index = @{ slugs = $roadmapSlugs; meta = $roadmapMeta; categories = $categories; counts = @{} }

# Build per-roadmap detail files
$dataDir = Join-Path $base "data\web"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

foreach ($slug in $roadmapSlugs) {
  $roadmapFile = Join-Path $base "data\$slug\roadmap.json"
  if (-not (Test-Path $roadmapFile)) {
    Write-Host "  SKIP: $slug (no roadmap.json)"
    continue
  }
  
  $rJson = Get-Content $roadmapFile -Raw | ConvertFrom-Json
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
Write-Host "Total roadmaps: $($roadmapSlugs.Count), Total topics: $totalTopics"
