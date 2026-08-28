# Generates the comprehensive offline site with all roadmaps + graph visualization
$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'

$roadmapSlugs = @('full-stack','frontend','backend','devops','aws')
$roadmapMeta = @{
  'full-stack' = @{ color='#2563eb'; icon='🔧'; title='Full Stack Developer' }
  'frontend'   = @{ color='#16a34a'; icon='🎨'; title='Frontend Developer' }
  'backend'    = @{ color='#9333ea'; icon='⚙️'; title='Backend Developer' }
  'devops'     = @{ color='#ea580c'; icon='🚀'; title='DevOps Engineer' }
  'aws'        = @{ color='#f59e0b'; icon='☁️'; title='AWS Cloud Engineer' }
}

# Load all roadmap data + topics
$allData = @{}
foreach ($slug in $roadmapSlugs) {
  $rJson = Get-Content (Join-Path $base "data\$slug\roadmap.json") -Raw | ConvertFrom-Json
  $topicDir = Join-Path $base "data\$slug\topics"
  $topics = @()
  if (Test-Path $topicDir) {
    foreach ($file in Get-ChildItem (Join-Path $topicDir '*.json')) {
      $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
      $topics += $t
    }
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
  # Build node info map
  $nodeMap = @{}
  foreach ($n in $r.nodes) {
    if ($n.data.label) {
      $nodeMap[$n.id] = @{
        id     = $n.id
        type   = $n.type
        label  = $n.data.label
        x      = $n.position.x
        y      = $n.position.y
        href   = $n.data.href
      }
    }
  }
  # Build edge list (filtered to source/target that exist in nodeMap)
  $edgeList = @()
  foreach ($e in $r.edges) {
    if ($nodeMap.ContainsKey($e.source) -and $nodeMap.ContainsKey($e.target)) {
      $edgeList += @{
        source = $e.source
        target = $e.target
      }
    }
  }
  # Build topics array
  $topicsArr = @()
  foreach ($t in $rd.topics) {
    $label = ''
    $nodeType = ''
    if ($nodeMap.ContainsKey($t.nodeId)) {
      $label = $nodeMap[$t.nodeId].label
      $nodeType = $nodeMap[$t.nodeId].type
    }
    # Skip buttons (links to other roadmaps) and decorative nodes
    if ($nodeType -eq 'button' -or $nodeType -eq 'horizontal' -or $nodeType -eq 'vertical' -or $nodeType -eq 'label') { continue }
    $topicsArr += @{
      nodeId      = $t.nodeId
      title       = $label
      description = $t.description
      resources   = $t.resources
      lessonPacks = $t.lessonPacks
      paidResources = $t.paidResources
    }
  }

  $payload.roadmaps[$slug] = @{
    dimensions = $r.dimensions
    nodes      = $nodeMap
    edges      = $edgeList
    topics     = $topicsArr
  }
}

$json = $payload | ConvertTo-Json -Depth 10 -Compress
# Escape </ to prevent breaking script tags
$json = $json.Replace('</', '<\/')

# Now generate the HTML
$html = Get-Content (Join-Path $base 'generate-html.ps1') -Raw
# Extract the HTML template between the here-string markers
# Actually, let's just write the HTML directly

Write-Host "Building HTML with $(($roadmapSlugs | ForEach-Object { $allData[$_].topics.Count } | Measure-Object -Sum).Sum) total topics across $($roadmapSlugs.Count) roadmaps..."

# --- Write the HTML file ---
$outFile = Join-Path $base 'index.html'

# We'll write it in parts to keep memory manageable
$part1 = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Full Stack Developer Roadmap (Offline)</title>
<style>
  :root {
    --bg: #f8fafc;
    --card: #ffffff;
    --border: #e2e8f0;
    --text: #0f172a;
    --muted: #64748b;
    --accent: #2563eb;
    --accent-dark: #1d4ed8;
    --hover: #f1f5f9;
    --active-bg: #dbeafe;
    --active-text: #1d4ed8;
    --code-bg: #f1f5f9;
    --pre-bg: #0f172a;
    --pre-text: #e2e8f0;
    --graph-bg: #f8fafc;
    --tooltip-bg: #0f172a;
    --tooltip-text: #fff;
    --graph-btn-bg: #fff;
    --graph-btn-hover: #f1f5f9;
    --paid-bg: #fefce8;
    --paid-border: #fde68a;
    --shadow: rgba(0,0,0,0.1);
    --badge-video-bg: #fee2e2; --badge-video-text: #991b1b;
    --badge-article-bg: #dbeafe; --badge-article-text: #1d4ed8;
    --badge-official-bg: #dcfce7; --badge-official-text: #166534;
    --badge-opensource-bg: #f3e8ff; --badge-opensource-text: #6b21a8;
    --badge-course-bg: #fef3c7; --badge-course-text: #92400e;
    --badge-feed-bg: #e0f2fe; --badge-feed-text: #075985;
    --badge-roadmap-bg: #f1f5f9; --badge-roadmap-text: #64748b;
    --badge-default-bg: #f1f5f9; --badge-default-text: #64748b;
  }
  [data-theme="dark"] {
    --bg: #0f172a;
    --card: #1e293b;
    --border: #334155;
    --text: #e2e8f0;
    --muted: #94a3b8;
    --accent: #60a5fa;
    --accent-dark: #93bbfc;
    --hover: #334155;
    --active-bg: #1e3a5f;
    --active-text: #93c5fd;
    --code-bg: #1e293b;
    --pre-bg: #020617;
    --pre-text: #e2e8f0;
    --graph-bg: #0f172a;
    --tooltip-bg: #e2e8f0;
    --tooltip-text: #0f172a;
    --graph-btn-bg: #1e293b;
    --graph-btn-hover: #334155;
    --paid-bg: #422006;
    --paid-border: #854d0e;
    --shadow: rgba(0,0,0,0.4);
    --badge-video-bg: #450a0a; --badge-video-text: #fca5a5;
    --badge-article-bg: #1e3a5f; --badge-article-text: #93c5fd;
    --badge-official-bg: #052e16; --badge-official-text: #86efac;
    --badge-opensource-bg: #2e1065; --badge-opensource-text: #d8b4fe;
    --badge-course-bg: #451a03; --badge-course-text: #fcd34d;
    --badge-feed-bg: #0c4a6e; --badge-feed-text: #7dd3fc;
    --badge-roadmap-bg: #1e293b; --badge-roadmap-text: #94a3b8;
    --badge-default-bg: #1e293b; --badge-default-text: #94a3b8;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background: var(--bg); color: var(--text); line-height: 1.6;
    transition: background 0.2s, color 0.2s;
  }
  /* Header */
  header {
    background: #0f172a; color: #fff; padding: 0 28px;
    position: sticky; top: 0; z-index: 50;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  }
  .header-top { display: flex; align-items: center; gap: 16px; padding: 14px 0 6px; }
  .header-top h1 { font-size: 18px; font-weight: 700; flex: 1; }
  .header-top h1 span { color: #f59e0b; }
  .theme-toggle {
    background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2);
    border-radius: 8px; width: 36px; height: 36px; cursor: pointer;
    display: flex; align-items: center; justify-content: center;
    transition: all 0.2s; color: #f59e0b; font-size: 18px;
  }
  .theme-toggle:hover { background: rgba(255,255,255,0.18); }
  .roadmap-tabs { display: flex; gap: 4px; padding: 0 0 8px; overflow-x: auto; }
  .roadmap-tab {
    display: flex; align-items: center; gap: 6px;
    padding: 7px 14px; border-radius: 7px; cursor: pointer;
    font-size: 13px; font-weight: 500; white-space: nowrap;
    color: #94a3b8; background: transparent; border: 1px solid transparent;
    transition: all 0.15s;
  }
  .roadmap-tab:hover { background: rgba(255,255,255,0.08); color: #e2e8f0; }
  .roadmap-tab.active { background: rgba(255,255,255,0.12); color: #fff; border-color: rgba(255,255,255,0.2); }
  .roadmap-tab .dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .roadmap-tab .count { font-size: 11px; color: #64748b; }

  /* View tabs */
  .view-tabs {
    display: flex; gap: 4px; padding: 0 0 0 16px;
  }
  .view-tab {
    padding: 6px 12px; border-radius: 6px; cursor: pointer;
    font-size: 12px; font-weight: 600; text-transform: uppercase;
    letter-spacing: 0.04em; color: #64748b; background: transparent;
    border: 1px solid transparent; transition: all 0.15s;
  }
  .view-tab:hover { color: #94a3b8; }
  .view-tab.active { background: rgba(255,255,255,0.1); color: #fff; border-color: rgba(255,255,255,0.15); }

  /* Layout */
  .layout { display: flex; height: calc(100vh - 98px); }
  .layout.graph-view { flex-direction: column; }

  /* Sidebar (topics list) */
  aside {
    width: 300px; min-width: 300px;
    background: var(--card); border-right: 1px solid var(--border);
    display: flex; flex-direction: column; overflow: hidden;
  }
  .search-box {
    width: 100%; padding: 9px 12px;
    border: 1px solid var(--border); border-radius: 8px;
    font-size: 13px; margin: 12px 12px 0; outline: none;
  }
  .search-box:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
  .topics-scroll { flex: 1; overflow-y: auto; padding: 8px 12px 20px; }
  .phase { margin-bottom: 14px; }
  .phase-title {
    font-size: 11px; font-weight: 700; text-transform: uppercase;
    letter-spacing: 0.06em; color: var(--muted); padding: 5px 8px;
    border-bottom: 1px solid var(--border); margin-bottom: 4px;
  }
  .topic-item {
    display: flex; align-items: center; gap: 8px;
    padding: 7px 10px; border-radius: 6px; cursor: pointer;
    font-size: 13px; color: var(--text); transition: background 0.12s;
  }
  .topic-item:hover { background: var(--hover); }
  .topic-item.active { background: var(--active-bg); color: var(--active-text); font-weight: 600; }
  .topic-item .dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
  .topic-item .res-count {
    margin-left: auto; font-size: 10px; color: var(--muted);
    background: var(--hover); padding: 1px 5px; border-radius: 8px;
  }

  /* Main content */
  .main-wrap { flex: 1; overflow: auto; position: relative; }
  .content-panel {
    padding: 24px 28px; max-width: 800px;
  }
  .empty-state {
    display: flex; flex-direction: column; align-items: center;
    justify-content: center; height: 100%; color: var(--muted); text-align: center;
  }
  .empty-state h2 { font-size: 20px; margin-bottom: 6px; color: var(--text); }

  /* Topic detail */
  .topic-header { margin-bottom: 14px; }
  .topic-header h2 { font-size: 24px; font-weight: 700; }
  .phase-badge {
    display: inline-block; font-size: 11px; font-weight: 600;
    padding: 2px 9px; border-radius: 16px; margin-top: 4px;
  }
  .card {
    background: var(--card); border: 1px solid var(--border);
    border-radius: 10px; padding: 16px; margin-bottom: 14px;
  }
  .card h3 { font-size: 14px; font-weight: 700; margin-bottom: 10px; }
  .description { font-size: 14px; color: var(--text); }
  .description h1,.description h2,.description h3 { margin: 12px 0 6px; font-size: 16px; }
  .description p { margin-bottom: 8px; }
  .description ul,.description ol { margin: 0 0 8px 20px; }
  .description li { margin-bottom: 3px; }
  .description a { color: var(--accent); text-decoration: underline; }
  .description code { background: var(--code-bg); padding: 1px 4px; border-radius: 3px; font-size: 12px; color: var(--text); }
  .description pre { background: var(--pre-bg); color: var(--pre-text); padding: 10px; border-radius: 6px; overflow-x: auto; margin-bottom: 8px; }
  .description blockquote { border-left: 3px solid var(--border); padding-left: 10px; color: var(--muted); margin: 0 0 8px; }

  .resource-list { list-style: none; }
  .resource-list li { margin-bottom: 6px; }
  .resource-link {
    display: flex; align-items: center; gap: 8px;
    padding: 8px 10px; border: 1px solid var(--border);
    border-radius: 6px; text-decoration: none; color: var(--text);
    transition: border-color 0.12s;
  }
  .resource-link:hover { border-color: var(--accent); background: var(--hover); }
  .resource-type {
    font-size: 10px; font-weight: 700; text-transform: uppercase;
    padding: 2px 6px; border-radius: 3px; flex-shrink: 0; min-width: 48px; text-align: center;
  }
  .type-video { background: var(--badge-video-bg); color: var(--badge-video-text); }
  .type-article { background: var(--badge-article-bg); color: var(--badge-article-text); }
  .type-official { background: var(--badge-official-bg); color: var(--badge-official-text); }
  .type-opensource { background: var(--badge-opensource-bg); color: var(--badge-opensource-text); }
  .type-course { background: var(--badge-course-bg); color: var(--badge-course-text); }
  .type-roadmap { background: var(--badge-roadmap-bg); color: var(--badge-roadmap-text); }
  .type-feed { background: var(--badge-feed-bg); color: var(--badge-feed-text); }
  .type-default { background: var(--badge-default-bg); color: var(--badge-default-text); }
  .resource-title { font-size: 13px; font-weight: 500; }

  .paid-note {
    font-size: 12px; color: var(--muted); background: var(--paid-bg);
    border: 1px solid var(--paid-border); border-radius: 6px; padding: 8px 10px; margin-top: 8px;
  }
  .lesson-pack { border: 1px solid var(--border); border-radius: 6px; padding: 10px; margin-bottom: 6px; }
  .lesson-pack h4 { font-size: 13px; margin-bottom: 3px; }
  .lesson-pack p { font-size: 12px; color: var(--muted); }
  .lesson-pack .meta { font-size: 11px; color: var(--muted); margin-top: 3px; }

  /* Graph view */
  .graph-wrap {
    flex: 1; position: fixed; top: 98px; left: 0; right: 0; bottom: 0;
    overflow: hidden; background: var(--graph-bg); z-index: 5;
    transition: background 0.2s;
  }
  .graph-controls {
    position: absolute; bottom: 16px; right: 16px; z-index: 10;
    display: flex; flex-direction: column; gap: 4px;
  }
  .graph-btn {
    width: 36px; height: 36px; border-radius: 8px; border: 1px solid var(--border);
    background: var(--graph-btn-bg); cursor: pointer; font-size: 18px; display: flex;
    align-items: center; justify-content: center; box-shadow: 0 1px 4px var(--shadow);
    transition: background 0.12s; color: var(--text);
  }
  .graph-btn:hover { background: var(--graph-btn-hover); }
  svg.roadmap-svg { width: 100%; height: 100%; cursor: grab; background: var(--graph-bg); }
  svg.roadmap-svg:active { cursor: grabbing; }
  svg.roadmap-svg .node-rect {
    transition: filter 0.15s;
  }
  svg.roadmap-svg .node-rect:hover { filter: brightness(0.95) drop-shadow(0 2px 6px rgba(0,0,0,0.18)); }
  svg.roadmap-svg .node-rect.highlighted { stroke-width: 3 !important; filter: drop-shadow(0 3px 8px rgba(37,99,235,0.35)); }
  svg.roadmap-svg .node-label {
    font-size: 11px; font-weight: 600; fill: var(--text); pointer-events: none;
    text-anchor: middle; dominant-baseline: central;
  }
  svg.roadmap-svg .node-btn-rect {
    rx: 6; ry: 6; cursor: pointer; transition: filter 0.15s;
  }
  svg.roadmap-svg .node-btn-rect:hover { filter: brightness(0.9); }
  svg.roadmap-svg .edge-line {
    fill: none; stroke-width: 2; stroke-linecap: round;
  }
  svg.roadmap-svg .node-title {
    font-size: 13px; font-weight: 700; fill: var(--text); pointer-events: none;
    text-anchor: middle; dominant-baseline: central;
  }
  svg.roadmap-svg .node-paragraph {
    font-size: 10px; fill: var(--muted); pointer-events: none;
    text-anchor: middle; dominant-baseline: central;
  }
  svg.roadmap-svg .node-label-text {
    font-size: 11px; fill: var(--muted); pointer-events: none;
    text-anchor: middle; dominant-baseline: central;
  }

  /* Graph node tooltip on hover */
  .graph-tooltip {
    position: absolute; background: var(--tooltip-bg); color: var(--tooltip-text);
    padding: 6px 10px; border-radius: 6px; font-size: 12px;
    pointer-events: none; z-index: 20; white-space: nowrap;
    display: none; box-shadow: 0 4px 8px var(--shadow);
  }

  .footer-note {
    font-size: 11px; color: var(--muted); text-align: center;
    padding: 16px; border-top: 1px solid var(--border);
  }
  @media (max-width: 768px) {
    aside { width: 100%; min-width: 0; max-height: 35vh; }
    .layout { flex-direction: column; }
  }
</style>
</head>
<body>
<header>
  <div class="header-top">
    <h1><span>&#9679;</span> Developer Roadmaps</h1>
    <button class="theme-toggle" id="themeToggle" title="Toggle dark mode" onclick="toggleTheme()">
      <span class="theme-icon" id="themeIcon">&#9789;</span>
    </button>
  </div>
  <div class="roadmap-tabs" id="roadmapTabs"></div>
  <div class="view-tabs" id="viewTabs">
    <div class="view-tab active" data-view="list">List</div>
    <div class="view-tab" data-view="graph">Graph</div>
  </div>
</header>

<div class="layout" id="mainLayout">
  <aside>
    <input type="text" id="search" class="search-box" placeholder="Search topics...">
    <div class="topics-scroll" id="sidebar"></div>
  </aside>
  <div class="main-wrap" id="mainWrap">
    <div class="empty-state" id="welcome">
      <h2>Welcome</h2>
      <p>Select a topic from the sidebar to view its description and free learning resources.</p>
    </div>
    <div class="content-panel" id="content" style="display:none"></div>
  </div>
</div>

<div class="graph-wrap" id="graphWrap" style="display:none">
  <svg class="roadmap-svg" id="roadmapSvg"></svg>
  <div class="graph-tooltip" id="graphTooltip"></div>
  <div class="graph-controls">
    <button class="graph-btn" id="zoomIn" title="Zoom in">+</button>
    <button class="graph-btn" id="zoomOut" title="Zoom out">−</button>
    <button class="graph-btn" id="zoomFit" title="Fit to view">&#8596;</button>
  </div>
</div>

<div class="footer-note">
  Generated offline from roadmap.sh data — free resources are external links.
</div>

<script>
const DATA = PAYLOAD_PLACEHOLDER;
'@

$part2 = @'
// ===== Theme Toggle =====
function toggleTheme() {
  const html = document.documentElement;
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('theme', next);
  updateThemeIcon(next);
  // Re-render graph if visible
  if (currentView === 'graph') {
    setTimeout(() => renderGraph(DATA.roadmaps[currentSlug]), 50);
  }
}
function updateThemeIcon(theme) {
  const icon = document.getElementById('themeIcon');
  icon.innerHTML = theme === 'dark' ? '&#9728;' : '&#9789;';
}
// Initialize theme from localStorage
(function() {
  const saved = localStorage.getItem('theme') || 'light';
  document.documentElement.setAttribute('data-theme', saved);
  updateThemeIcon(saved);
})();

// ===== State =====
let currentSlug = 'full-stack';
let currentView = 'list'; // 'list' or 'graph'
let selectedTopicId = null;

// ===== Helpers =====
function esc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

function renderMarkdown(md) {
  if (!md) return '';
  let lines = md.replace(/\r\n/g,'\n').split('\n');
  let html = '', inList = false, inCode = false, codeBuf = [];
  const closeList = () => { if (inList) { html += '</ul>'; inList = false; } };
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    if (line.trim().startsWith('```')) { if (inCode) { html += '<pre>' + esc(codeBuf.join('\n')) + '</pre>'; codeBuf = []; inCode = false; } else { closeList(); inCode = true; } continue; }
    if (inCode) { codeBuf.push(line); continue; }
    let inline = line.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>').replace(/(^|[^*])\*([^*]+)\*(?!\*)/g, '$1<em>$2</em>').replace(/`([^`]+)`/g, '<code>$1</code>').replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    const h = line.match(/^(#{1,4})\s+(.*)/);
    if (h) { closeList(); const lvl = h[1].length + 1; html += '<h'+lvl+'>'+inline.replace(/^#{1,4}\s+/,'')+'</h'+lvl+'>'; continue; }
    if (/^\s*(---|\*\*\*)\s*$/.test(line)) { closeList(); html += '<hr>'; continue; }
    if (line.trim().startsWith('>')) { closeList(); html += '<blockquote>'+inline.replace(/^\s*>\s?/,'')+'</blockquote>'; continue; }
    if (/^\s*[-*+]\s+/.test(line)) { if (!inList) { html += '<ul>'; inList = true; } html += '<li>'+inline.replace(/^\s*[-*+]\s+/,'')+'</li>'; continue; }
    if (/^\s*\d+\.\s+/.test(line)) { if (!inList) { html += '<ul>'; inList = true; } html += '<li>'+inline.replace(/^\s*\d+\.\s+/,'')+'</li>'; continue; }
    if (line.trim() === '') { closeList(); continue; }
    closeList(); html += '<p>'+inline+'</p>';
  }
  closeList(); if (inCode) html += '<pre>' + esc(codeBuf.join('\n')) + '</pre>';
  return html;
}

const TYPE_CLASS = { video:'type-video', article:'type-article', official:'type-official', opensource:'type-opensource', course:'type-course', roadmap:'type-roadmap', feed:'type-feed' };
function typeClass(t) { return TYPE_CLASS[t] || 'type-default'; }
function typeLabel(t) { return ({ video:'Video', article:'Article', official:'Docs', opensource:'Open Source', course:'Course', roadmap:'Roadmap', feed:'Feed' })[t] || t || 'Link'; }

// ===== Roadmap Tabs =====
function buildRoadmapTabs() {
  const el = document.getElementById('roadmapTabs');
  el.innerHTML = '';
  DATA.slugs.forEach(slug => {
    const meta = DATA.meta[slug];
    const rd = DATA.roadmaps[slug];
    const tab = document.createElement('div');
    tab.className = 'roadmap-tab' + (slug === currentSlug ? ' active' : '');
    tab.dataset.slug = slug;
    tab.innerHTML = '<span class="dot" style="background:'+meta.color+'"></span><span>'+meta.title+'</span><span class="count">'+rd.topics.length+'</span>';
    tab.addEventListener('click', () => switchRoadmap(slug));
    el.appendChild(tab);
  });
}

function switchRoadmap(slug) {
  currentSlug = slug;
  selectedTopicId = null;
  buildRoadmapTabs();
  buildSidebar();
  showWelcome();
  if (currentView === 'graph') {
    requestAnimationFrame(() => { requestAnimationFrame(() => renderGraph()); });
  }
}

// ===== View Tabs =====
document.querySelectorAll('.view-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    currentView = tab.dataset.view;
    document.querySelectorAll('.view-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    const layout = document.getElementById('mainLayout');
    const graphWrap = document.getElementById('graphWrap');
    if (currentView === 'graph') {
      layout.style.display = 'none';
      graphWrap.style.display = 'flex';
      // Defer rendering so the browser can compute layout dimensions
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          renderGraph();
        });
      });
    } else {
      layout.style.display = 'flex';
      graphWrap.style.display = 'none';
    }
  });
});
// Re-render graph on window resize
window.addEventListener('resize', () => {
  if (currentView === 'graph') renderGraph();
});

// ===== Sidebar =====
function getPhase(label) {
  const l = (label||'').toLowerCase();
  if (l.includes('checkpoint')) return 'Checkpoints & Projects';
  if (l.match(/html|css|javascript|npm|git|github|tailwind|react|vue|angular|svelte|next|nuxt|webpack|vite|sass|less|typescript|dom|responsive|accessibility|seo|performance|animation|figma|ui|ux|css-in-js|styled/)) return 'Frontend';
  if (l.match(/node|express|rest|jwt|redis|linux|postgres|mongo|sql|graphql|backend|python|java|go|ruby|php|django|fastapi|flask|spring|api|auth|cache|queue|rabbit|kafka|docker/)) return 'Backend';
  if (l.match(/aws|ec2|vpc|route53|ses|s3|monit|actions|ansible|terraform|devops|ci\/cd|jenkins|kubernetes|k8s|cloud|gcp|azure|nginx|prometheus|grafana|elk|logging|incident|sre|iac|puppet|chef/)) return 'DevOps';
  if (l.match(/cloud|iam|lambda|dynamodb|sqs|sns|cloudfront|route\s*53|ecs|eks|rds|elastic|sam|cdk|waf/)) return 'AWS';
  return 'Other';
}

const PHASE_COLORS = { 'Frontend':'#2563eb', 'Backend':'#16a34a', 'DevOps':'#ea580c', 'AWS':'#f59e0b', 'Checkpoints & Projects':'#dc2626', 'Other':'#64748b' };

function buildSidebar(filter) {
  const rd = DATA.roadmaps[currentSlug];
  const sidebar = document.getElementById('sidebar');
  sidebar.innerHTML = '';
  const groups = {};
  rd.topics.forEach(t => {
    const label = t.title || t.nodeId;
    const phase = getPhase(label);
    if (filter && !label.toLowerCase().includes(filter.toLowerCase())) return;
    if (!groups[phase]) groups[phase] = [];
    groups[phase].push({ ...t, _label: label, _phase: phase });
  });
  const phaseOrder = ['Frontend','Backend','DevOps','AWS','Checkpoints & Projects','Other'];
  phaseOrder.forEach(phase => {
    if (!groups[phase] || groups[phase].length === 0) return;
    const div = document.createElement('div');
    div.className = 'phase';
    div.innerHTML = '<div class="phase-title" style="border-left: 3px solid '+(PHASE_COLORS[phase]||'#64748b')+' padding-left:8px">'+esc(phase)+' ('+groups[phase].length+')</div>';
    groups[phase].forEach(t => {
      const item = document.createElement('div');
      item.className = 'topic-item' + (t.nodeId === selectedTopicId ? ' active' : '');
      item.dataset.id = t.nodeId;
      const rc = (t.resources||[]).length;
      item.innerHTML = '<span class="dot" style="background:'+(PHASE_COLORS[phase]||'#64748b')+'"></span><span>'+esc(t._label)+'</span>' + (rc ? '<span class="res-count">'+rc+'</span>' : '');
      item.addEventListener('click', () => selectTopic(t.nodeId));
      div.appendChild(item);
    });
    sidebar.appendChild(div);
  });
}

// ===== Topic Detail =====
function selectTopic(nodeId) {
  const rd = DATA.roadmaps[currentSlug];
  const t = rd.topics.find(x => x.nodeId === nodeId);
  if (!t) return;
  selectedTopicId = nodeId;
  document.querySelectorAll('.topic-item').forEach(el => el.classList.remove('active'));
  const activeEl = document.querySelector('.topic-item[data-id="'+nodeId+'"]');
  if (activeEl) activeEl.classList.add('active');
  document.getElementById('welcome').style.display = 'none';
  const content = document.getElementById('content');
  content.style.display = 'block';

  const label = t.title || nodeId;
  const phase = getPhase(label);
  let html = '<div class="topic-header"><h2>'+esc(label)+'</h2><span class="phase-badge" style="background:'+PHASE_COLORS[phase]+'22;color:'+PHASE_COLORS[phase]+'">'+esc(phase)+'</span></div>';

  if (t.description) {
    html += '<div class="card"><h3>&#128214; Overview</h3><div class="description">'+renderMarkdown(t.description)+'</div></div>';
  }
  if (t.resources && t.resources.length > 0) {
    html += '<div class="card"><h3>&#127891; Free Resources ('+t.resources.length+')</h3><ul class="resource-list">';
    t.resources.forEach(r => {
      html += '<li><a class="resource-link" href="'+esc(r.url)+'" target="_blank" rel="noopener"><span class="resource-type '+typeClass(r.type)+'">'+esc(typeLabel(r.type))+'</span><span class="resource-title">'+esc(r.title)+'</span></a></li>';
    });
    html += '</ul></div>';
  }
  if (t.lessonPacks && t.lessonPacks.length > 0) {
    html += '<div class="card"><h3>&#128230; Lesson Packs</h3>';
    t.lessonPacks.forEach(p => {
      html += '<div class="lesson-pack"><h4>'+esc(p.title)+'</h4><p>'+esc(p.description||'')+'</p><div class="meta">'+(p.lessonCount||0)+' lessons &middot; '+(p.projectCount||0)+' projects &middot; '+(p.readingTime||0)+' min</div></div>';
    });
    html += '</div>';
  }
  if (t.paidResources && t.paidResources.length > 0) {
    html += '<div class="card"><h3>&#128179; Paid Courses</h3><ul class="resource-list">';
    t.paidResources.forEach(r => {
      html += '<li><a class="resource-link" href="'+esc(r.url)+'" target="_blank" rel="noopener"><span class="resource-type type-course">'+esc(r.partner||'Course')+'</span><span class="resource-title">'+esc(r.title)+'</span></a></li>';
    });
    html += '</ul><div class="paid-note">These are paid courses. The free resources above are the recommended starting point.</div></div>';
  }
  if (!t.description && (!t.resources || t.resources.length === 0)) {
    html += '<div class="empty-state" style="padding:40px"><p>No content available for this item.</p></div>';
  }
  content.innerHTML = html;
  content.scrollTop = 0;
  document.getElementById('mainWrap').scrollTop = 0;

  // Highlight node in graph if visible
  highlightGraphNode(nodeId);
}

function showWelcome() {
  document.getElementById('welcome').style.display = 'flex';
  document.getElementById('content').style.display = 'none';
}

// ===== Search =====
document.getElementById('search').addEventListener('input', e => buildSidebar(e.target.value.trim()));

// ===== Graph Rendering =====
let graphScale = 1, graphPanX = 0, graphPanY = 0, isPanning = false, panStartX = 0, panStartY = 0, panMouseDownX = 0, panMouseDownY = false;

function renderGraph() {
  const svg = document.getElementById('roadmapSvg');
  const rd = DATA.roadmaps[currentSlug];
  const nodes = rd.nodes;
  const edges = rd.edges;

  // Skip decorative nodes for rendering
  const skipTypes = new Set(['horizontal','vertical','label']);
  const renderable = Object.values(nodes).filter(n => !skipTypes.has(n.type));

  // Calculate bounding box with proper node sizes
  function nodeSize(n) {
    const len = (n.label||'').length;
    if (n.type==='title') return { w: Math.max(140, len*9+30), h: 28 };
    if (n.type==='paragraph') return { w: Math.max(160, len*7+20), h: 20 };
    if (n.type==='section') return { w: Math.max(120, len*8+24), h: 32 };
    if (n.type==='button') return { w: Math.max(100, len*8+20), h: 30 };
    // topic, subtopic
    return { w: Math.max(110, len*8+24), h: 30 };
  }

  let minX=Infinity, minY=Infinity, maxX=-Infinity, maxY=-Infinity;
  renderable.forEach(n => {
    const s = nodeSize(n);
    if (n.x < minX) minX = n.x; if (n.y < minY) minY = n.y;
    if (n.x+s.w > maxX) maxX = n.x+s.w; if (n.y+s.h > maxY) maxY = n.y+s.h;
  });

  if (!isFinite(minX)) return; // no nodes

  const padX = 80, padY = 80;
  const vbW = maxX-minX+padX*2, vbH = maxY-minY+padY*2;

  // Get actual container size
  const svgRect = svg.parentElement.getBoundingClientRect();
  const cw = svgRect.width || 800, ch = svgRect.height || 600;

  // Scale to fit
  const scaleX = cw / vbW, scaleY = ch / vbH;
  graphScale = Math.min(scaleX, scaleY, 2.0);
  graphPanX = (cw - vbW*graphScale)/2 - (minX-padX)*graphScale;
  graphPanY = (ch - vbH*graphScale)/2 - (minY-padY)*graphScale;

  // Pre-build node size map
  const sizeMap = {};
  renderable.forEach(n => { sizeMap[n.id] = nodeSize(n); });

  let svgContent = '<g id="graphGroup">';

  // Read theme colors from CSS variables
  const cs = getComputedStyle(document.documentElement);
  const edgeColor = cs.getPropertyValue('--muted').trim() || '#94a3b8';
  const nodeFills = {
    topic: cs.getPropertyValue('--badge-article-bg').trim() || '#dbeafe',
    subtopic: cs.getPropertyValue('--badge-official-bg').trim() || '#dcfce7',
    button: cs.getPropertyValue('--badge-course-bg').trim() || '#fef3c7',
    title: cs.getPropertyValue('--hover').trim() || '#f1f5f9',
    section: cs.getPropertyValue('--bg').trim() || '#f8fafc',
    paragraph: cs.getPropertyValue('--bg').trim() || '#f8fafc',
    default: cs.getPropertyValue('--bg').trim() || '#f8fafc'
  };
  const nodeStrokes = {
    topic: cs.getPropertyValue('--accent').trim() || '#2563eb',
    subtopic: '#16a34a',
    button: '#f59e0b',
    title: cs.getPropertyValue('--muted').trim() || '#334155',
    default: cs.getPropertyValue('--border').trim() || '#cbd5e1'
  };

  // Edges first (behind nodes, dashed lines like roadmap.sh)
  edges.forEach(e => {
    const src = nodes[e.source], tgt = nodes[e.target];
    if (!src || !tgt || !sizeMap[e.source] || !sizeMap[e.target]) return;
    const ss = sizeMap[e.source], ts = sizeMap[e.target];
    const x1=src.x+ss.w/2, y1=src.y+ss.h, x2=tgt.x+ts.w/2, y2=tgt.y;
    // Smoothstep path: down from source, across, down to target
    const midY = (y1 + y2) / 2;
    const path = `M${x1},${y1} L${x1},${midY} L${x2},${midY} L${x2},${y2}`;
    svgContent += `<path class="edge-line" d="${path}" stroke="${edgeColor}" stroke-width="2" fill="none" stroke-dasharray="6,4"/>`;
  });

  // Nodes on top of edges
  renderable.forEach(n => {
    const s = sizeMap[n.id];
    const fill = nodeFills[n.type] || nodeFills.default;
    const stroke = nodeStrokes[n.type] || nodeStrokes.default;
    const labelClass = n.type==='title'?'node-title':n.type==='paragraph'?'node-paragraph':n.type==='section'?'node-label-text':'node-label';
    const isClickable = n.type==='topic'||n.type==='subtopic'||n.type==='button';
    const nodeId = n.id;
    const label = n.label;
    const fontSize = n.type==='title'?13:n.type==='paragraph'?10:n.type==='section'?11:11;
    // Truncate label to fit
    const maxChars = Math.floor(s.w / 7);
    let displayLabel = label;
    if (label.length > maxChars && n.type !== 'title' && n.type !== 'paragraph') {
      displayLabel = label.substring(0, maxChars-1) + '\u2026';
    }
    svgContent += `<g data-nodeid="${esc(nodeId)}" ${isClickable?`style="cursor:pointer" onclick="if(!didDrag)selectTopicFromGraph('${esc(nodeId)}')"`:''}>`;
    svgContent += `<rect class="node-rect${selectedTopicId===nodeId?' highlighted':''}" x="${n.x}" y="${n.y}" width="${s.w}" height="${s.h}" rx="7" ry="7" fill="${fill}" stroke="${stroke}" stroke-width="2"/>`;
    svgContent += `<text class="${labelClass}" x="${n.x+s.w/2}" y="${n.y+s.h/2}" font-size="${fontSize}">${esc(displayLabel)}</text>`;
    svgContent += '</g>';
  });

  svgContent += '</g>';
  svg.innerHTML = svgContent;
  updateGraphTransform();
}

function updateGraphTransform() {
  const g = document.getElementById('graphGroup');
  if (g) g.setAttribute('transform', 'translate('+graphPanX+','+graphPanY+') scale('+graphScale+')');
}

function selectTopicFromGraph(nodeId) {
  // Switch to list view with this topic selected
  document.querySelectorAll('.view-tab').forEach(t => t.classList.remove('active'));
  document.querySelector('.view-tab[data-view="list"]').classList.add('active');
  currentView = 'list';
  document.getElementById('mainLayout').style.display = 'flex';
  document.getElementById('graphWrap').style.display = 'none';
  selectTopic(nodeId);
}

function highlightGraphNode(nodeId) {
  if (currentView !== 'graph') return;
  document.querySelectorAll('.node-rect.highlighted').forEach(el => el.classList.remove('highlighted'));
  const g = document.querySelector('[data-nodeid="'+nodeId+'"]');
  if (g) {
    const rect = g.querySelector('.node-rect');
    if (rect) rect.classList.add('highlighted');
  }
}

// Graph pan/zoom with drag detection
const svgEl = document.getElementById('roadmapSvg');
let didDrag = false;
svgEl.addEventListener('mousedown', e => { isPanning=true; didDrag=false; panStartX=e.clientX-graphPanX; panStartY=e.clientY-graphPanY; panMouseDownX=e.clientX; panMouseDownY=e.clientY; });
svgEl.addEventListener('mousemove', e => { if (!isPanning) return; const dx=e.clientX-panMouseDownX, dy=e.clientY-panMouseDownY; if (Math.abs(dx)>4||Math.abs(dy)>4) didDrag=true; graphPanX=e.clientX-panStartX; graphPanY=e.clientY-panStartY; updateGraphTransform(); });
svgEl.addEventListener('mouseup', () => { isPanning=false; setTimeout(()=>{ didDrag=false; },0); });
svgEl.addEventListener('mouseleave', () => { isPanning=false; didDrag=false; });
svgEl.addEventListener('wheel', e => { e.preventDefault(); const d=e.deltaY>0?0.9:1.1; graphScale=Math.max(0.2,Math.min(5,graphScale*d)); updateGraphTransform(); });
document.getElementById('zoomIn').addEventListener('click', () => { graphScale=Math.min(5,graphScale*1.2); updateGraphTransform(); });
document.getElementById('zoomOut').addEventListener('click', () => { graphScale=Math.max(0.2,graphScale*0.8); updateGraphTransform(); });
document.getElementById('zoomFit').addEventListener('click', () => renderGraph());

// Tooltip on graph hover
const tooltip = document.getElementById('graphTooltip');
svgEl.addEventListener('mouseover', e => {
  const g = e.target.closest('[data-nodeid]');
  if (!g) return;
  const rd = DATA.roadmaps[currentSlug];
  const n = rd.nodes[g.dataset.nodeid];
  if (!n || (n.type!=='topic'&&n.type!=='subtopic'&&n.type!=='button')) return;
  tooltip.textContent = n.label;
  tooltip.style.display = 'block';
});
svgEl.addEventListener('mousemove', e => {
  if (tooltip.style.display==='block') { tooltip.style.left=(e.clientX+12)+'px'; tooltip.style.top=(e.clientY-30)+'px'; }
});
svgEl.addEventListener('mouseout', e => {
  if (!e.target.closest || !e.target.closest('[data-nodeid]')) tooltip.style.display='none';
});

// ===== Init =====
buildRoadmapTabs();
buildSidebar();
</script>
</body>
</html>
'@

# Assemble the final HTML
$htmlContent = $part1 + "`nconst PAYLOAD_DATA = $json;`n" + $part2

# Fix: replace the placeholder with actual data
$htmlContent = $htmlContent.Replace('PAYLOAD_PLACEHOLDER', $json)

# Write
Set-Content -Path $outFile -Value $htmlContent -Encoding UTF8
$size = [math]::Round((Get-Item $outFile).Length/1KB, 1)
Write-Host "Generated: $outFile ($size KB)"
Write-Host "Total topics: $(($roadmapSlugs | ForEach-Object { $allData[$_].topics.Count } | Measure-Object -Sum).Sum)"
