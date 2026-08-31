$base = "D:\FullStack-Roadmap-Offline"
$dataDir = Join-Path $base "data"

# All roadmap slugs to download
$roadmaps = @(
  # Absolute Beginners
  @{ slug="frontend-beginner"; title="Frontend Beginner"; color="#3b82f6"; category="Beginners" },
  @{ slug="backend-beginner"; title="Backend Beginner"; color="#22c55e"; category="Beginners" },
  @{ slug="devops-beginner"; title="DevOps Beginner"; color="#f97316"; category="Beginners" },
  @{ slug="git-github-beginner"; title="Git & GitHub Beginner"; color="#8b5cf6"; category="Beginners" },
  # Languages/Platforms
  @{ slug="python"; title="Python"; color="#3776ab"; category="Languages" },
  @{ slug="python-for-data-analysis"; title="Python for Data Analysis"; color="#ff6f00"; category="Languages" },
  @{ slug="sql"; title="SQL"; color="#e38c00"; category="Languages" },
  @{ slug="javascript"; title="JavaScript"; color="#f7df1e"; category="Languages" },
  @{ slug="typescript"; title="TypeScript"; color="#3178c6"; category="Languages" },
  @{ slug="nodejs"; title="Node.js"; color="#339933"; category="Languages" },
  @{ slug="java"; title="Java"; color="#ed8b00"; category="Languages" },
  @{ slug="cpp"; title="C++"; color="#00599c"; category="Languages" },
  @{ slug="rust"; title="Rust"; color="#dea584"; category="Languages" },
  @{ slug="golang"; title="Go"; color="#00add8"; category="Languages" },
  @{ slug="php"; title="PHP"; color="#777bb4"; category="Languages" },
  @{ slug="kotlin"; title="Kotlin"; color="#7f52ff"; category="Languages" },
  @{ slug="html"; title="HTML"; color="#e34c26"; category="Languages" },
  @{ slug="css"; title="CSS"; color="#1572b6"; category="Languages" },
  @{ slug="swift"; title="Swift"; color="#fa7343"; category="Languages" },
  @{ slug="shell"; title="Shell / Bash"; color="#4eaa25"; category="Languages" },
  @{ slug="laravel"; title="Laravel"; color="#ff2d20"; category="Languages" },
  @{ slug="django"; title="Django"; color="#092e20"; category="Languages" },
  @{ slug="ruby"; title="Ruby"; color="#cc342d"; category="Languages" },
  @{ slug="rails"; title="Ruby on Rails"; color="#cc0000"; category="Languages" }
)

$topicDir = Join-Path $dataDir "topics"
if (-not (Test-Path $topicDir)) { New-Item -ItemType Directory -Path $topicDir -Force | Out-Null }

$success = 0; $fail = 0
foreach ($r in $roadmaps) {
  $slug = $r.slug
  $slugDir = Join-Path $dataDir $slug
  if (-not (Test-Path $slugDir)) { New-Item -ItemType Directory -Path $slugDir -Force | Out-Null }
  
  $roadmapFile = Join-Path $slugDir "roadmap.json"
  if (Test-Path $roadmapFile) {
    Write-Host "  [skip] $slug (already exists)"
    $success++
    continue
  }
  
  Write-Host "  Downloading $slug..."
  try {
    $json = & curl.exe -s "https://roadmap.sh/api/v1-official-roadmap/$slug"
    if ($json -match '"id"') {
      Set-Content -Path $roadmapFile -Value $json -Encoding UTF8
      $success++
      
      # Parse and download topic details
      $data = $json | ConvertFrom-Json
      $nodeMap = @{}
      foreach ($n in $data.children) {
        if ($n.id -and $n.data.label) { $nodeMap[$n.id] = $n.data.label }
      }
      
      # Download topic details (try top 15 topic IDs per roadmap)
      $count = 0
      foreach ($node in $data.children) {
        if ($count -ge 15) { break }
        if ($node.type -ne 'topic' -and $node.type -ne 'subtopic') { continue }
        $nodeId = $node.id
        $topicFile = Join-Path $topicDir "$nodeId.json"
        if (-not (Test-Path $topicFile)) {
          try {
            $topicJson = & curl.exe -s "https://roadmap.sh/$slug/$nodeId.json"
            if ($topicJson -match '"description"') {
              Set-Content -Path $topicFile -Value $topicJson -Encoding UTF8
              $count++
            }
          } catch {}
        } else { $count++ }
      }
    } else {
      Write-Host "  [FAIL] $slug - no data"
      $fail++
    }
  } catch {
    Write-Host "  [FAIL] $slug - $($_.Exception.Message)"
    $fail++
  }
}

Write-Host "`nDone: $success downloaded, $fail failed"
