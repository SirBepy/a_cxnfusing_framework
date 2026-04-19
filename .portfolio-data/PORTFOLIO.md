## The What

A static documentation site for `a_cxnfusing_framework`, a batteries-included Roblox Luau framework by cxnfusion. The site renders the framework's markdown docs as a single-page app with a landing grid, sidebar navigation grouped by concern (core, data, services, utilities, client modules), syntax-highlighted code blocks, and hash-based routing so deep links to specific modules work.

Every module has its own page. Modules not authored by cxnfusion (DataService by Leif, ExpressivePrompts by iGottic) show a short attribution page pointing at the real upstream docs instead of claiming the work.

## The Why

cxnfusion open-sourced the framework on Discord with no docs and the community wanted a readable reference. A plain README does not scale to 16 modules plus architecture and getting-started content, and most readers are beginners who need a navigable site, not a 2000-line file. This repo is the hosted version of the docs in the framework repo, rebuilt as a browsable site so people can share direct links like `/modules/gamefeel` instead of scrolling through markdown on GitHub.

## The How

Zero build step: marked parses markdown at runtime, highlight.js colors code blocks, and a tiny router reads the URL hash to pick which `.md` file to fetch from `content/`. The module list and sidebar groupings live in a single JavaScript constant so adding a new module is one object literal plus one sidebar entry. The styleguide layer is imported as a CDN stylesheet so the site inherits the same visual tokens as the rest of the SirBepy portfolio.
