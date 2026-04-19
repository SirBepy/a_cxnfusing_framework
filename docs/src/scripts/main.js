const MODULES = [
  { slug: "framework", name: "Framework", icon: "ph-cube", group: "Core", blurb: "Loader, helpers, require surface for user code." },
  { slug: "shared", name: "Shared", icon: "ph-share-network", group: "Core", blurb: "Leaf require surface for framework-loaded ModuleScripts." },
  { slug: "network", name: "Network", icon: "ph-broadcast", group: "Core", blurb: "Global (remote) + Local (signal) events." },

  { slug: "info", name: "Info", icon: "ph-identification-card", group: "Data", blurb: "PlayerState and GameState shared tables." },
  { slug: "functions", name: "Functions", icon: "ph-function", group: "Data", blurb: "FastTween, FormatNumber, AddCommas, GenerateUID." },
  { slug: "dataservice", name: "DataService", icon: "ph-database", group: "Data", blurb: "ProfileStore-backed player data. Not authored here." },

  { slug: "vfx", name: "VFX", icon: "ph-sparkle", group: "Services", blurb: "Framework VFX service with client replication." },
  { slug: "dialogueservice", name: "DialogueService", icon: "ph-chat-teardrop-dots", group: "Services", blurb: "Typewriter, effects, reply trees, conversations." },

  { slug: "util-motion", name: "Motion", icon: "ph-wave-sawtooth", group: "Utilities", blurb: "Bezier, Spring, StateMachine, Observer." },
  { slug: "util-collections", name: "Collections", icon: "ph-stack", group: "Utilities", blurb: "Trove, Signal, Promise, Pool." },
  { slug: "util-input", name: "Input", icon: "ph-keyboard", group: "Utilities", blurb: "ConnectToAdded, ConnectToTag, ActionBuffer." },
  { slug: "util-visual", name: "Visual", icon: "ph-eye", group: "Utilities", blurb: "CameraShaker, FlashController, DecalProjector, SFXHandler, Imagine, ViewCheck, LODManager, Ragdoll." },
  { slug: "util-misc", name: "Misc", icon: "ph-dots-three-outline", group: "Utilities", blurb: "DebugUtils, TimeFormatter, IllusionIAS, ExtendedLibraries, SpectateService." },

  { slug: "tagloader", name: "TagLoader", icon: "ph-tag", group: "Client modules", blurb: "Filename-as-tag client handlers: Preset, UIAnimate, AnimatedTexture." },
  { slug: "expressiveprompts", name: "ExpressivePrompts", icon: "ph-cursor-click", group: "Client modules", blurb: "Animated keyboard/gamepad/touch input prompts. Not authored here." },
  { slug: "gamefeel", name: "GameFeel", icon: "ph-game-controller", group: "Client modules", blurb: "CoyoteTime, JumpBuffer, ApexGravity, LandingFX." },
];

const TOP_PAGES = {
  "getting-started": { title: "Getting started", path: "getting-started.md", icon: "ph-rocket-launch" },
  "architecture": { title: "Architecture", path: "architecture.md", icon: "ph-tree-structure" },
};

const TRANSITION_MS = 150;

const contentEl = document.getElementById("content");
const sidebarEl = document.getElementById("sidebar");
const sidebarToggle = document.getElementById("sidebar-toggle");
const progressEl = document.getElementById("nav-progress");

marked.setOptions({
  highlight: (code, lang) => {
    if (lang && hljs.getLanguage(lang)) {
      try { return hljs.highlight(code, { language: lang }).value; } catch (_) {}
    }
    try { return hljs.highlightAuto(code).value; } catch (_) {}
    return code;
  },
  breaks: false,
  gfm: true,
});

const mdCache = new Map();

async function fetchMarkdown(path) {
  if (mdCache.has(path)) return mdCache.get(path);
  const res = await fetch(path);
  if (!res.ok) throw new Error("Failed to load " + path + " (" + res.status + ")");
  const text = await res.text();
  mdCache.set(path, text);
  return text;
}

function renderMarkdownToHtml(md) {
  const wrapper = document.createElement("div");
  wrapper.innerHTML = marked.parse(md);
  wrapper.querySelectorAll("pre code").forEach((block) => {
    if (!block.classList.contains("hljs")) hljs.highlightElement(block);
  });
  return wrapper.innerHTML;
}

function setActiveLink(hash) {
  document.querySelectorAll(".sidebar a").forEach((a) => {
    a.classList.toggle("active", a.getAttribute("href") === hash);
  });
}

function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function showProgress() {
  if (progressEl) progressEl.classList.add("active");
}
function hideProgress() {
  if (progressEl) progressEl.classList.remove("active");
}

let navSeq = 0;
async function navigate(prepare, activeHash) {
  const seq = ++navSeq;

  let html;
  try {
    const maybeHtml = prepare();
    if (maybeHtml && typeof maybeHtml.then === "function") {
      // Async path: show progress bar, await.
      showProgress();
      html = await maybeHtml;
      hideProgress();
    } else {
      html = maybeHtml;
    }
  } catch (err) {
    html = buildErrorHtml(err && err.message);
    hideProgress();
  }

  if (seq !== navSeq) return;

  contentEl.classList.add("leaving");
  await wait(TRANSITION_MS);
  if (seq !== navSeq) return;

  contentEl.innerHTML = html;
  contentEl.querySelectorAll("pre code").forEach((block) => {
    if (!block.classList.contains("hljs")) hljs.highlightElement(block);
  });

  contentEl.classList.add("entering");
  contentEl.classList.remove("leaving");
  void contentEl.offsetHeight;
  contentEl.classList.remove("entering");

  setActiveLink(activeHash);
  window.scrollTo({ top: 0 });
}

function buildLandingHtml() {
  const groups = {};
  MODULES.forEach((m) => {
    if (!groups[m.group]) groups[m.group] = [];
    groups[m.group].push(m);
  });

  const groupOrder = ["Core", "Data", "Services", "Utilities", "Client modules"];

  let html = `
    <section class="landing-hero">
      <h1>a_cxnfusing_framework</h1>
      <p>A batteries-included Roblox Luau framework for beginners and senior devs. Drop it into a Rojo project, require <code>Framework</code>, and get a loader plus utilities, functions, info tables, services, network events, and tag-discovered modules wired up on both client and server.</p>
      <div class="landing-cta">
        <a class="btn btn-primary" href="#/getting-started"><i class="ph ph-rocket-launch"></i> Get started</a>
        <a class="btn btn-outline" href="#/architecture"><i class="ph ph-tree-structure"></i> Architecture</a>
        <a class="btn btn-outline" href="https://github.com/cxnfusingworld/a_cxnfusing_framework" target="_blank" rel="noopener"><i class="ph ph-github-logo"></i> View on GitHub</a>
      </div>
    </section>
  `;

  groupOrder.forEach((g) => {
    if (!groups[g]) return;
    html += `<div class="group-title">${g}</div>`;
    html += `<div class="module-grid">`;
    groups[g].forEach((m) => {
      html += `
        <a class="card module-card" href="#/modules/${m.slug}">
          <div class="module-card-head">
            <i class="ph-duotone ${m.icon}"></i>
            <strong>${m.name}</strong>
          </div>
          <p>${m.blurb}</p>
        </a>
      `;
    });
    html += `</div>`;
  });

  return html;
}

async function buildMarkdownHtml(path) {
  if (mdCache.has(path)) return renderMarkdownToHtml(mdCache.get(path));
  const md = await fetchMarkdown(path);
  return renderMarkdownToHtml(md);
}

function buildMarkdownHtmlMaybeSync(path) {
  if (mdCache.has(path)) return renderMarkdownToHtml(mdCache.get(path));
  return buildMarkdownHtml(path);
}

function buildErrorHtml(reason) {
  return `
    <h1><i class="ph ph-warning-circle"></i> Not found</h1>
    <p>${reason || "This page doesn't exist."}</p>
    <p><a href="#/"><i class="ph ph-arrow-left"></i> Back to home</a></p>
  `;
}

function route() {
  const hash = window.location.hash || "#/";
  if (sidebarEl) sidebarEl.classList.remove("open");

  if (hash === "#/" || hash === "#") {
    navigate(() => buildLandingHtml(), "#/");
    return;
  }

  const parts = hash.replace(/^#\//, "").split("/").filter(Boolean);

  if (parts[0] === "modules" && parts[1]) {
    const slug = parts[1];
    const mod = MODULES.find((m) => m.slug === slug);
    if (!mod) {
      navigate(() => buildErrorHtml("Unknown module: " + slug), "#/");
      return;
    }
    navigate(() => buildMarkdownHtmlMaybeSync(`modules/${slug}.md`), `#/modules/${slug}`);
    return;
  }

  if (parts.length === 1) {
    const slug = parts[0];
    const def = TOP_PAGES[slug];
    if (!def) {
      navigate(() => buildErrorHtml("Unknown page: " + slug), "#/");
      return;
    }
    navigate(() => buildMarkdownHtmlMaybeSync(def.path), `#/${slug}`);
    return;
  }

  navigate(() => buildErrorHtml(), "#/");
}

function idlePrefetchAll() {
  const urls = [
    ...Object.values(TOP_PAGES).map((p) => p.path),
    ...MODULES.map((m) => `modules/${m.slug}.md`),
  ];
  const runIdle = (cb) => {
    if (window.requestIdleCallback) {
      window.requestIdleCallback(cb, { timeout: 2000 });
    } else {
      setTimeout(cb, 50);
    }
  };
  const step = (i) => {
    if (i >= urls.length) return;
    runIdle(() => {
      fetchMarkdown(urls[i]).catch(() => {}).finally(() => step(i + 1));
    });
  };
  runIdle(() => step(0));
}

window.addEventListener("hashchange", route);
window.addEventListener("DOMContentLoaded", () => {
  route();
  idlePrefetchAll();
});

if (sidebarToggle && sidebarEl) {
  sidebarToggle.addEventListener("click", () => {
    sidebarEl.classList.toggle("open");
  });
}
