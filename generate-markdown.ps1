# Generates a Markdown file (README.md) for reading and taking notes.
# Organized by phase, with all topics, descriptions, and free resources.

$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'
$dataDir = Join-Path $base 'data'
$topicsDir = Join-Path $dataDir 'topics'

$roadmap = Get-Content (Join-Path $dataDir 'roadmap.json') -Raw | ConvertFrom-Json

$topicMap = @{}
foreach ($node in $roadmap.nodes) {
  if ($node.data.label -and $node.data.label -notmatch 'horizontal|vertical') {
    $topicMap[$node.id] = $node.data.label
  }
}

$topics = @()
foreach ($file in Get-ChildItem (Join-Path $topicsDir '*.json')) {
  $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
  $nodeId = $t.nodeId
  $label = if ($topicMap.ContainsKey($nodeId)) { $topicMap[$nodeId] } else { $nodeId }
  $topics += [PSCustomObject]@{
    nodeId        = $nodeId
    label         = $label
    description   = $t.description
    resources     = @($t.resources)
    lessonPacks   = @($t.lessonPacks)
    paidResources = @($t.paidResources)
  }
}

function Get-Phase($label) {
  $l = $label.ToLower()
  if ($l -match 'checkpoint') { return 'Checkpoints & Projects' }
  if ($l -match 'html|css|javascript|npm|git|github|tailwind|react|frontend') { return 'Frontend' }
  if ($l -match 'node|restful|jwt|redis|linux|postgres|backend') { return 'Backend' }
  if ($l -match 'aws|ec2|vpc|route53|ses|s3|monit|actions|ansible|terraform|devops') { return 'DevOps' }
  return 'Other'
}

$phaseOrder = @('Frontend', 'Backend', 'DevOps', 'Checkpoints & Projects', 'Other')

# Build the markdown
$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine('# Full Stack Developer Roadmap')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> Offline reading & notes copy. Generated from roadmap.sh data.')
[void]$sb.AppendLine('> Open `index.html` in this folder for the interactive version.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("> Data captured: $($roadmap.updatedAt)")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Table of Contents')
[void]$sb.AppendLine('')

foreach ($phase in $phaseOrder) {
  $phaseTopics = $topics | Where-Object { (Get-Phase $_.label) -eq $phase }
  if ($phaseTopics.Count -eq 0) { continue }
  $anchor = $phase.ToLower() -replace '[^a-z0-9]+','-'
  [void]$sb.AppendLine("- [$phase](#$anchor) ($($phaseTopics.Count) topics)")
}
[void]$sb.AppendLine('')

foreach ($phase in $phaseOrder) {
  $phaseTopics = $topics | Where-Object { (Get-Phase $_.label) -eq $phase }
  if ($phaseTopics.Count -eq 0) { continue }
  $anchor = $phase.ToLower() -replace '[^a-z0-9]+','-'
  [void]$sb.AppendLine("## $phase")
  [void]$sb.AppendLine('')

  foreach ($t in $phaseTopics) {
    $heading = $t.label -replace '[\[\]]',''
    [void]$sb.AppendLine("### $heading")
    [void]$sb.AppendLine('')

    # Description (strip markdown heading levels to avoid breaking TOC)
    if ($t.description) {
      $desc = $t.description
      # Demote any # headings inside descriptions to bold so they don't pollute TOC
      $desc = $desc -replace '(?m)^#{1,4}\s+(.+)$', '**$1**'
      [void]$sb.AppendLine($desc)
      [void]$sb.AppendLine('')
    }

    # Free resources
    if ($t.resources.Count -gt 0) {
      [void]$sb.AppendLine('**Free Resources:**')
      [void]$sb.AppendLine('')
      foreach ($r in $t.resources) {
        [void]$sb.AppendLine("- [$($r.title)]($($r.url))  _($($r.type))_")
      }
      [void]$sb.AppendLine('')
    }

    # Lesson packs
    if ($t.lessonPacks.Count -gt 0) {
      [void]$sb.AppendLine('**Lesson Packs:**')
      [void]$sb.AppendLine('')
      foreach ($p in $t.lessonPacks) {
        [void]$sb.AppendLine(("- **{0}** - {1} ({2} lessons, {3} projects, {4} min)" -f $p.title, $p.description, $p.lessonCount, $p.projectCount, $p.readingTime))
      }
      [void]$sb.AppendLine('')
    }

    # Paid resources
    if ($t.paidResources.Count -gt 0) {
      [void]$sb.AppendLine('**Paid Courses:**')
      [void]$sb.AppendLine('')
      foreach ($r in $t.paidResources) {
        [void]$sb.AppendLine("- [$($r.title)]($($r.url))  _($($r.partner))_")
      }
      [void]$sb.AppendLine('')
    }

    # Notes section
    [void]$sb.AppendLine('**Notes:**')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- ')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
  }
}

$outFile = Join-Path $base 'README.md'
Set-Content -Path $outFile -Value $sb.ToString() -Encoding UTF8
Write-Host "Generated: $outFile ($([math]::Round((Get-Item $outFile).Length/1KB,1)) KB)"
