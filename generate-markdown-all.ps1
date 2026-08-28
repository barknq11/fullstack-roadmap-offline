# Generates a comprehensive Markdown file for ALL roadmaps
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

$roadmapSlugs = @('full-stack','frontend','backend','devops','aws')
$roadmapNames = @{
  'full-stack' = 'Full Stack Developer'
  'frontend'   = 'Frontend Developer'
  'backend'    = 'Backend Developer'
  'devops'     = 'DevOps Engineer'
  'aws'        = 'AWS Cloud Engineer'
}

function Get-Phase($label) {
  $l = $label.ToLower()
  if ($l -match 'checkpoint') { return 'Checkpoints & Projects' }
  if ($l -match 'html|css|javascript|npm|git|github|tailwind|react|vue|angular|svelte|next|nuxt|webpack|vite|sass|less|typescript|dom|responsive|accessibility|seo|performance|animation|figma|ui|ux|css-in-js|styled') { return 'Frontend' }
  if ($l -match 'node|express|rest|jwt|redis|linux|postgres|mongo|sql|graphql|backend|python|java|go|ruby|php|django|fastapi|flask|spring|api|auth|cache|queue|rabbit|kafka|docker') { return 'Backend' }
  if ($l -match 'aws|ec2|vpc|route53|ses|s3|monit|actions|ansible|terraform|devops|ci/cd|jenkins|kubernetes|k8s|cloud|gcp|azure|nginx|prometheus|grafana|elk|logging|incident|sre|iac|puppet|chef') { return 'DevOps' }
  if ($l -match 'cloud|iam|lambda|dynamodb|sqs|sns|cloudfront|route\s*53|ecs|eks|rds|elastic|sam|cdk|waf') { return 'AWS' }
  return 'Other'
}

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine('# Developer Roadmaps — Offline Reading & Notes')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> Generated from roadmap.sh data. Open `index.html` for the interactive version with graph visualization.')
[void]$sb.AppendLine('')

# Main TOC
[void]$sb.AppendLine('## Roadmaps')
[void]$sb.AppendLine('')
foreach ($slug in $roadmapSlugs) {
  [void]$sb.AppendLine("- [$($roadmapNames[$slug])](#$slug)")
}
[void]$sb.AppendLine('')

foreach ($slug in $roadmapSlugs) {
  Write-Host "Processing $slug..."
  $rJson = Get-Content (Join-Path $base "data\$slug\roadmap.json") -Raw | ConvertFrom-Json
  $topicDir = Join-Path $base "data\$slug\topics"

  # Build node label map
  $nodeLabels = @{}
  foreach ($n in $rJson.nodes) {
    if ($n.data.label) { $nodeLabels[$n.id] = @{ label=$n.data.label; type=$n.type } }
  }

  # Load topics
  $topics = @()
  if (Test-Path $topicDir) {
    foreach ($file in Get-ChildItem (Join-Path $topicDir '*.json')) {
      $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
      $label = ''
      $ntype = ''
      if ($nodeLabels.ContainsKey($t.nodeId)) {
        $label = $nodeLabels[$t.nodeId].label
        $ntype = $nodeLabels[$t.nodeId].type
      }
      if ($ntype -eq 'button' -or $ntype -eq 'horizontal' -or $ntype -eq 'vertical' -or $ntype -eq 'label') { continue }
      $topics += [PSCustomObject]@{
        nodeId = $t.nodeId
        label = $label
        description = $t.description
        resources = @($t.resources)
        lessonPacks = @($t.lessonPacks)
        paidResources = @($t.paidResources)
      }
    }
  }

  $name = $roadmapNames[$slug]
  [void]$sb.AppendLine("---")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("# $name")
[void]$sb.AppendLine("")
[void]$sb.AppendLine(">")
[void]$sb.AppendLine(">")
[void]$sb.AppendLine("> **$($topics.Count) topics** with descriptions and free resources.")
[void]$sb.AppendLine(">")
[void]$sb.AppendLine("")

  # Phase grouping
  $phaseOrder = @('Frontend','Backend','DevOps','AWS','Checkpoints & Projects','Other')
  $groups = @{}
  foreach ($t in $topics) {
    $phase = Get-Phase $t.label
    if (-not $groups.ContainsKey($phase)) { $groups[$phase] = @() }
    $groups[$phase] += $t
  }

  # TOC for this roadmap
  [void]$sb.AppendLine("### Table of Contents")
  [void]$sb.AppendLine("")
  foreach ($phase in $phaseOrder) {
    if ($groups.ContainsKey($phase) -and $groups[$phase].Count -gt 0) {
      $anchor = "$slug-$($phase.ToLower() -replace '[^a-z0-9]+','-')"
      [void]$sb.AppendLine("- [$phase](#$anchor) ($($groups[$phase].Count) topics)")
    }
  }
  [void]$sb.AppendLine("")

  foreach ($phase in $phaseOrder) {
    if (-not $groups.ContainsKey($phase) -or $groups[$phase].Count -eq 0) { continue }
    $anchor = "$slug-$($phase.ToLower() -replace '[^a-z0-9]+','-')"
    [void]$sb.AppendLine("### $phase")
    [void]$sb.AppendLine("")

    foreach ($t in $groups[$phase]) {
      $heading = $t.label -replace '[\[\]]',''
      [void]$sb.AppendLine("#### $heading")
      [void]$sb.AppendLine("")

      if ($t.description) {
        $desc = $t.description -replace '(?m)^#{1,4}\s+(.+)$', '**$1**'
        [void]$sb.AppendLine($desc)
        [void]$sb.AppendLine("")
      }

      if ($t.resources.Count -gt 0) {
        [void]$sb.AppendLine('**Free Resources:**')
        [void]$sb.AppendLine('')
        foreach ($r in $t.resources) {
          [void]$sb.AppendLine(("- [{0}]({1})  _({2})_" -f $r.title, $r.url, $r.type))
        }
        [void]$sb.AppendLine('')
      }

      if ($t.lessonPacks.Count -gt 0) {
        [void]$sb.AppendLine('**Lesson Packs:**')
        [void]$sb.AppendLine('')
        foreach ($p in $t.lessonPacks) {
          [void]$sb.AppendLine(("- **{0}** - {1} ({2} lessons, {3} projects, {4} min)" -f $p.title, $p.description, $p.lessonCount, $p.projectCount, $p.readingTime))
        }
        [void]$sb.AppendLine('')
      }

      if ($t.paidResources.Count -gt 0) {
        [void]$sb.AppendLine('**Paid Courses:**')
        [void]$sb.AppendLine('')
        foreach ($r in $t.paidResources) {
          [void]$sb.AppendLine(("- [{0}]({1})  _({2})_" -f $r.title, $r.url, $r.partner))
        }
        [void]$sb.AppendLine('')
      }

      [void]$sb.AppendLine('**Notes:**')
      [void]$sb.AppendLine('')
      [void]$sb.AppendLine('- ')
      [void]$sb.AppendLine('')
      [void]$sb.AppendLine('---')
      [void]$sb.AppendLine('')
    }
  }
}

$outFile = Join-Path $base 'README.md'
Set-Content -Path $outFile -Value $sb.ToString() -Encoding UTF8
$size = [math]::Round((Get-Item $outFile).Length/1KB, 1)
Write-Host "`nGenerated: $outFile ($size KB)"
