# Generates a fully self-contained offline index.html for the full-stack roadmap.
# Embeds the roadmap graph + all topic details directly into the HTML so it
# works offline with the file:// protocol (no CORS / network needed).

$ErrorActionPreference = 'Stop'
$base = 'D:\FullStack-Roadmap-Offline'
$dataDir = Join-Path $base 'data'
$topicsDir = Join-Path $dataDir 'topics'

$roadmap = Get-Content (Join-Path $dataDir 'roadmap.json') -Raw | ConvertFrom-Json

# ---- Build topic map: nodeId -> {label, description, resources, lessonPacks, paidResources} ----
$topicMap = @{}
foreach ($node in $roadmap.nodes) {
  if ($node.data.label -and $node.data.label -notmatch 'horizontal|vertical') {
    $topicMap[$node.id] = @{
      label = $node.data.label
      href  = $node.data.href
    }
  }
}

# Load each downloaded topic detail
$topics = @()
foreach ($file in Get-ChildItem (Join-Path $topicsDir '*.json')) {
  $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
  $nodeId = $t.nodeId
  $label = if ($topicMap.ContainsKey($nodeId)) { $topicMap[$nodeId].label } else { $nodeId }
  $topics += [PSCustomObject]@{
    nodeId        = $nodeId
    label         = $label
    description   = $t.description
    resources     = @($t.resources)
    lessonPacks   = @($t.lessonPacks)
    paidResources = @($t.paidResources)
  }
}

# ---- Phase classification based on label ----
function Get-Phase($label) {
  $l = $label.ToLower()
  if ($l -match 'checkpoint') { return 'Checkpoints & Projects' }
  if ($l -match 'html|css|javascript|npm|git|github|tailwind|react|frontend') { return 'Frontend' }
  if ($l -match 'node|restful|jwt|redis|linux|postgres|backend') { return 'Backend' }
  if ($l -match 'aws|ec2|vpc|route53|ses|s3|monit|actions|ansible|terraform|devops') { return 'DevOps' }
  return 'Other'
}

# ---- Serialize to JSON for embedding ----
$payload = @{
  title       = $roadmap.title
  description = $roadmap.description
  updatedAt   = $roadmap.updatedAt
  topics      = @($topics | ForEach-Object {
    [PSCustomObject]@{
      nodeId        = $_.nodeId
      label         = $_.label
      phase         = Get-Phase $_.label
      description   = $_.description
      resources     = $_.resources
      lessonPacks   = $_.lessonPacks
      paidResources = $_.paidResources
    }
  })
}

$json = $payload | ConvertTo-Json -Depth 10 -Compress

# Escape for embedding in a <script> tag safely
$json = $json.Replace('</', '<\/')

# ---- Build the HTML ----
$html = @'
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
    --green: #16a34a;
    --yellow: #f59e0b;
    --red: #dc2626;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
  }
  header {
    background: #0f172a;
    color: #fff;
    padding: 20px 28px;
    position: sticky;
    top: 0;
    z-index: 50;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  }
  header h1 { font-size: 22px; font-weight: 700; }
  header p { color: #94a3b8; font-size: 13px; margin-top: 2px; }
  .layout { display: flex; min-height: calc(100vh - 76px); }
  /* Sidebar */
  aside {
    width: 320px;
    min-width: 320px;
    background: var(--card);
    border-right: 1px solid var(--border);
    padding: 16px;
    overflow-y: auto;
    max-height: calc(100vh - 76px);
    position: sticky;
    top: 76px;
  }
  .search-box {
    width: 100%;
    padding: 9px 12px;
    border: 1px solid var(--border);
    border-radius: 8px;
    font-size: 14px;
    margin-bottom: 14px;
    outline: none;
  }
  .search-box:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }
  .phase { margin-bottom: 18px; }
  .phase-title {
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--muted);
    padding: 6px 8px;
    border-bottom: 1px solid var(--border);
    margin-bottom: 6px;
  }
  .topic-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 10px;
    border-radius: 7px;
    cursor: pointer;
    font-size: 14px;
    color: var(--text);
    transition: background 0.12s;
  }
  .topic-item:hover { background: #f1f5f9; }
  .topic-item.active { background: #dbeafe; color: var(--accent-dark); font-weight: 600; }
  .topic-item .dot {
    width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0;
  }
  .dot.frontend { background: var(--accent); }
  .dot.backend { background: var(--green); }
  .dot.devops { background: var(--yellow); }
  .dot.checkpoint { background: var(--red); }
  .dot.other { background: var(--muted); }
  .topic-item .count {
    margin-left: auto;
    font-size: 11px;
    color: var(--muted);
    background: #f1f5f9;
    padding: 1px 6px;
    border-radius: 10px;
  }
  /* Main content */
  main {
    flex: 1;
    padding: 28px 32px;
    max-width: 900px;
  }
  .topic-header { margin-bottom: 16px; }
  .topic-header h2 { font-size: 26px; font-weight: 700; }
  .topic-header .phase-badge {
    display: inline-block;
    font-size: 12px;
    font-weight: 600;
    padding: 3px 10px;
    border-radius: 20px;
    margin-top: 6px;
  }
  .phase-badge.frontend { background: #dbeafe; color: var(--accent-dark); }
  .phase-badge.backend { background: #dcfce7; color: #166534; }
  .phase-badge.devops { background: #fef3c7; color: #92400e; }
  .phase-badge.checkpoint { background: #fee2e2; color: #991b1b; }
  .phase-badge.other { background: #f1f5f9; color: var(--muted); }
  .card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 18px;
  }
  .card h3 {
    font-size: 15px;
    font-weight: 700;
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .card h3 .icon { font-size: 16px; }
  .description { font-size: 15px; color: #334155; }
  .description h1, .description h2, .description h3 { margin: 14px 0 8px; font-size: 17px; }
  .description p { margin-bottom: 10px; }
  .description ul, .description ol { margin: 0 0 10px 22px; }
  .description li { margin-bottom: 4px; }
  .description a { color: var(--accent); text-decoration: underline; }
  .description code { background: #f1f5f9; padding: 1px 5px; border-radius: 4px; font-size: 13px; }
  .description pre { background: #0f172a; color: #e2e8f0; padding: 12px; border-radius: 8px; overflow-x: auto; margin-bottom: 10px; }
  .description blockquote { border-left: 3px solid var(--border); padding-left: 12px; color: var(--muted); margin: 0 0 10px; }
  .resource-list { list-style: none; }
  .resource-list li { margin-bottom: 8px; }
  .resource-link {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px;
    border: 1px solid var(--border);
    border-radius: 8px;
    text-decoration: none;
    color: var(--text);
    transition: border-color 0.12s, background 0.12s;
  }
  .resource-link:hover { border-color: var(--accent); background: #f8fafc; }
  .resource-type {
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    padding: 2px 8px;
    border-radius: 4px;
    flex-shrink: 0;
    min-width: 58px;
    text-align: center;
  }
  .type-video { background: #fee2e2; color: #991b1b; }
  .type-article { background: #dbeafe; color: var(--accent-dark); }
  .type-official { background: #dcfce7; color: #166534; }
  .type-opensource { background: #f3e8ff; color: #6b21a8; }
  .type-course { background: #fef3c7; color: #92400e; }
  .type-roadmap { background: #f1f5f9; color: var(--muted); }
  .type-feed { background: #e0f2fe; color: #075985; }
  .type-default { background: #f1f5f9; color: var(--muted); }
  .resource-title { font-size: 14px; font-weight: 500; }
  .empty-state {
    text-align: center;
    padding: 60px 20px;
    color: var(--muted);
  }
  .empty-state h2 { font-size: 22px; margin-bottom: 8px; color: var(--text); }
  .paid-note {
    font-size: 13px;
    color: var(--muted);
    background: #fefce8;
    border: 1px solid #fde68a;
    border-radius: 8px;
    padding: 10px 12px;
    margin-top: 10px;
  }
  .lesson-pack {
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 12px;
    margin-bottom: 8px;
  }
  .lesson-pack h4 { font-size: 14px; margin-bottom: 4px; }
  .lesson-pack p { font-size: 13px; color: var(--muted); }
  .lesson-pack .meta { font-size: 12px; color: var(--muted); margin-top: 4px; }
  .footer-note {
    font-size: 12px;
    color: var(--muted);
    text-align: center;
    padding: 20px;
    border-top: 1px solid var(--border);
    margin-top: 20px;
  }
  @media (max-width: 768px) {
    .layout { flex-direction: column; }
    aside { width: 100%; min-width: 0; max-height: 40vh; position: static; top: auto; }
    main { padding: 20px; }
  }
</style>
</head>
<body>
<header>
  <h1>Full Stack Developer Roadmap</h1>
  <p>Offline copy &mdash; click any topic to see its description and free resources</p>
</header>
<div class="layout">
  <aside>
    <input type="text" id="search" class="search-box" placeholder="Search topics...">
    <div id="sidebar"></div>
  </aside>
  <main id="main">
    <div class="empty-state" id="welcome">
      <h2>Welcome to the Full Stack Roadmap</h2>
      <p>Select a topic from the sidebar to view its description and free learning resources.</p>
    </div>
    <div id="content" style="display:none"></div>
  </main>
</div>
<div class="footer-note">
  Generated offline from roadmap.sh data &mdash; free resources are external links (YouTube, docs, articles).
</div>

<script>
const DATA = __PAYLOAD__;

const PHASE_ORDER = ['Frontend', 'Backend', 'DevOps', 'Checkpoints & Projects', 'Other'];
const PHASE_COLORS = { 'Frontend':'frontend', 'Backend':'backend', 'DevOps':'devops', 'Checkpoints & Projects':'checkpoint', 'Other':'other' };

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// Minimal markdown renderer (headings, bold, italic, code, links, lists, paragraphs, blockquote, hr)
function renderMarkdown(md) {
  if (!md) return '';
  let lines = md.replace(/\r\n/g,'\n').split('\n');
  let html = '';
  let inList = false, inCode = false, codeBuf = [];
  const closeList = () => { if (inList) { html += '</ul>'; inList = false; } };

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];

    // Code block
    if (line.trim().startsWith('```')) {
      if (inCode) { html += '<pre>' + esc(codeBuf.join('\n')) + '</pre>'; codeBuf = []; inCode = false; }
      else { closeList(); inCode = true; }
      continue;
    }
    if (inCode) { codeBuf.push(line); continue; }

    // Inline formatting
    let inline = line;
    inline = inline.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    inline = inline.replace(/(^|[^*])\*([^*]+)\*(?!\*)/g, '$1<em>$2</em>');
    inline = inline.replace(/`([^`]+)`/g, '<code>$1</code>');
    inline = inline.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');

    // Headings
    const h = line.match(/^(#{1,4})\s+(.*)/);
    if (h) { closeList(); const lvl = h[1].length + 1; html += `<h${lvl}>${inline.replace(/^#{1,4}\s+/,'')}</h${lvl}>`; continue; }

    // Horizontal rule
    if (/^\s*(---|\*\*\*)\s*$/.test(line)) { closeList(); html += '<hr>'; continue; }

    // Blockquote
    if (line.trim().startsWith('>')) { closeList(); html += '<blockquote>' + inline.replace(/^\s*>\s?/,'') + '</blockquote>'; continue; }

    // List items
    if (/^\s*[-*+]\s+/.test(line)) {
      if (!inList) { html += '<ul>'; inList = true; }
      html += '<li>' + inline.replace(/^\s*[-*+]\s+/,'') + '</li>';
      continue;
    }
    if (/^\s*\d+\.\s+/.test(line)) {
      if (!inList) { html += '<ul>'; inList = true; }
      html += '<li>' + inline.replace(/^\s*\d+\.\s+/,'') + '</li>';
      continue;
    }

    // Blank line
    if (line.trim() === '') { closeList(); continue; }

    // Paragraph
    closeList();
    html += '<p>' + inline + '</p>';
  }
  closeList();
  if (inCode) html += '<pre>' + esc(codeBuf.join('\n')) + '</pre>';
  return html;
}

const TYPE_CLASS = {
  'video':'type-video', 'article':'type-article', 'official':'type-official',
  'opensource':'type-opensource', 'course':'type-course', 'roadmap':'type-roadmap',
  'feed':'type-feed'
};
function typeClass(t) { return TYPE_CLASS[t] || 'type-default'; }

function resourceTypeLabel(t) {
  const map = { 'video':'Video', 'article':'Article', 'official':'Docs', 'opensource':'Open Source', 'course':'Course', 'roadmap':'Roadmap', 'feed':'Feed' };
  return map[t] || t || 'Link';
}

// Build sidebar grouped by phase
function buildSidebar(filter) {
  const sidebar = document.getElementById('sidebar');
  sidebar.innerHTML = '';
  const groups = {};
  DATA.topics.forEach(t => {
    if (filter && !t.label.toLowerCase().includes(filter.toLowerCase())) return;
    if (!groups[t.phase]) groups[t.phase] = [];
    groups[t.phase].push(t);
  });

  PHASE_ORDER.forEach(phase => {
    if (!groups[phase] || groups[phase].length === 0) return;
    const div = document.createElement('div');
    div.className = 'phase';
    div.innerHTML = `<div class="phase-title">${esc(phase)} (${groups[phase].length})</div>`;
    groups[phase].forEach(t => {
      const item = document.createElement('div');
      item.className = 'topic-item';
      item.dataset.id = t.nodeId;
      item.innerHTML = `<span class="dot ${PHASE_COLORS[t.phase]}"></span><span>${esc(t.label)}</span><span class="count">${t.resources.length}</span>`;
      item.addEventListener('click', () => selectTopic(t.nodeId));
      div.appendChild(item);
    });
    sidebar.appendChild(div);
  });
}

function selectTopic(nodeId) {
  const t = DATA.topics.find(x => x.nodeId === nodeId);
  if (!t) return;
  document.querySelectorAll('.topic-item').forEach(el => el.classList.remove('active'));
  const activeEl = document.querySelector(`.topic-item[data-id="${nodeId}"]`);
  if (activeEl) activeEl.classList.add('active');

  document.getElementById('welcome').style.display = 'none';
  const content = document.getElementById('content');
  content.style.display = 'block';

  let html = '';
  html += `<div class="topic-header"><h2>${esc(t.label)}</h2><span class="phase-badge ${PHASE_COLORS[t.phase]}">${esc(t.phase)}</span></div>`;

  // Description
  if (t.description) {
    html += `<div class="card"><h3><span class="icon">📖</span> Overview</h3><div class="description">${renderMarkdown(t.description)}</div></div>`;
  }

  // Free resources
  if (t.resources && t.resources.length > 0) {
    html += `<div class="card"><h3><span class="icon">🎓</span> Free Resources (${t.resources.length})</h3><ul class="resource-list">`;
    t.resources.forEach(r => {
      html += `<li><a class="resource-link" href="${esc(r.url)}" target="_blank" rel="noopener"><span class="resource-type ${typeClass(r.type)}">${esc(resourceTypeLabel(r.type))}</span><span class="resource-title">${esc(r.title)}</span></a></li>`;
    });
    html += `</ul></div>`;
  }

  // Lesson packs
  if (t.lessonPacks && t.lessonPacks.length > 0) {
    html += `<div class="card"><h3><span class="icon">📦</span> Lesson Packs</h3>`;
    t.lessonPacks.forEach(p => {
      html += `<div class="lesson-pack"><h4>${esc(p.title)}</h4><p>${esc(p.description || '')}</p><div class="meta">${p.lessonCount||0} lessons · ${p.projectCount||0} projects · ${p.readingTime||0} min</div></div>`;
    });
    html += `</div>`;
  }

  // Paid resources note
  if (t.paidResources && t.paidResources.length > 0) {
    html += `<div class="card"><h3><span class="icon">💳</span> Paid Courses</h3><ul class="resource-list">`;
    t.paidResources.forEach(r => {
      html += `<li><a class="resource-link" href="${esc(r.url)}" target="_blank" rel="noopener"><span class="resource-type type-course">${esc(r.partner || 'Course')}</span><span class="resource-title">${esc(r.title)}</span></a></li>`;
    });
    html += `</ul><div class="paid-note">These are paid courses. The free resources above are the recommended starting point.</div></div>`;
  }

  if (!t.description && (!t.resources || t.resources.length === 0)) {
    html += `<div class="empty-state"><p>No content available for this item.</p></div>`;
  }

  content.innerHTML = html;
  content.scrollTop = 0;
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Search
document.getElementById('search').addEventListener('input', (e) => {
  buildSidebar(e.target.value.trim());
});

// Init
buildSidebar('');
</script>
</body>
</html>
'@

# Replace payload placeholder
$html = $html.Replace('__PAYLOAD__', $json)

$outFile = Join-Path $base 'index.html'
Set-Content -Path $outFile -Value $html -Encoding UTF8
Write-Host "Generated: $outFile ($([math]::Round((Get-Item $outFile).Length/1KB,1)) KB)"
