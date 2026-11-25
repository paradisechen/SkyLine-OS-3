export interface BrowserBookmark {
  label: string;
  url: string;
  isFavorite?: boolean;
}

export const BROWSER_HOME_URL = 'https://www.nintendo.com';

export const DEFAULT_BROWSER_BOOKMARKS: BrowserBookmark[] = [
  { label: 'Nintendo', url: 'https://www.nintendo.com' },
  { label: 'Google', url: 'https://www.google.com' },
  { label: 'APKPorts', url: 'https://www.apkports.com/games' },
  { label: 'YouTube', url: 'https://www.youtube.com' },
];

export function normalizeBrowserInput(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return BROWSER_HOME_URL;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  if (trimmed.includes('.') && !trimmed.includes(' ')) {
    return `https://${trimmed}`;
  }
  return `https://www.google.com/search?q=${encodeURIComponent(trimmed)}`;
}

export function extractYouTubeVideoId(rawUrl: string): string | null {
  try {
    const parsed = new URL(rawUrl);
    const host = parsed.hostname.toLowerCase().replace(/^www\./, '').replace(/^m\./, '');
    if (host === 'youtu.be') {
      const id = parsed.pathname.replace(/^\//, '').split('/')[0];
      return /^[A-Za-z0-9_-]{6,15}$/.test(id) ? id : null;
    }
    if (host === 'youtube.com' || host === 'youtube-nocookie.com') {
      const v = parsed.searchParams.get('v');
      if (v && /^[A-Za-z0-9_-]{6,15}$/.test(v)) return v;
      const m = parsed.pathname.match(/^\/(?:embed|shorts|live)\/([A-Za-z0-9_-]{6,15})/);
      if (m) return m[1];
    }
  } catch {
    return null;
  }
  return null;
}

export function isSafeExternalHttpUrl(rawUrl: string): boolean {
  try {
    const u = new URL(rawUrl);
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return false;
    const host = u.hostname.toLowerCase();
    if (
      host === 'localhost' ||
      host === '0.0.0.0' ||
      host === '::1' ||
      host.endsWith('.local') ||
      host.startsWith('127.') ||
      host.startsWith('10.') ||
      host.startsWith('192.168.') ||
      host.startsWith('169.254.') ||
      /^172\.(1[6-9]|2\d|3[01])\./.test(host)
    ) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

export function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function buildInAppBridgeScript(currentUrl: string): string {
  const safeCurrent = JSON.stringify(currentUrl);
  return `
<script>
(function() {
  var CURRENT_URL = ${safeCurrent};
  try {
    var origPush = history.pushState;
    var origReplace = history.replaceState;
    history.pushState = function(state, title, url) {
      try { return origPush.call(history, state, title, url); } catch (e) {}
    };
    history.replaceState = function(state, title, url) {
      try { return origReplace.call(history, state, title, url); } catch (e) {}
    };
  } catch (e) {}

  function revealLazyContent() {
    try {
      var imgs = document.querySelectorAll('img[data-src]');
      for (var i = 0; i < imgs.length; i++) {
        var ds = imgs[i].getAttribute('data-src');
        if (ds && !imgs[i].getAttribute('src')) imgs[i].setAttribute('src', ds);
      }
      var main = document.querySelector('main');
      if (main) {
        var blocks = main.querySelectorAll('section, [data-testid], div, img');
        for (var j = 0; j < blocks.length; j++) {
          var el = blocks[j];
          if (el.getAttribute('aria-hidden') === 'true' || el.getAttribute('role') === 'dialog') continue;
          var cs = window.getComputedStyle(el);
          if (cs && cs.display !== 'none' && (cs.opacity === '0' || cs.visibility === 'hidden')) {
            var rect = el.getBoundingClientRect();
            if (rect.height >= 40 && rect.width >= 40) {
              el.style.opacity = '1';
              el.style.visibility = 'visible';
            }
          }
        }
      }
    } catch (e) {}
  }

  function notifyLoaded() {
    revealLazyContent();
    try {
      window.parent.postMessage({
        type: 'skyline-browser-loaded',
        url: CURRENT_URL,
        title: document.title || CURRENT_URL
      }, '*');
    } catch (e) {}
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', notifyLoaded);
  } else {
    notifyLoaded();
  }
  window.addEventListener('load', notifyLoaded);

  window.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      e.preventDefault();
      e.stopPropagation();
      try { window.parent.postMessage({ type: 'skyline-browser-escape' }, '*'); } catch (err) {}
    } else if (e.key === 'BrowserBack' || e.key === 'GoBack' || e.key === 'XF86Back') {
      e.preventDefault();
      e.stopPropagation();
      try { window.parent.postMessage({ type: 'skyline-browser-home-back' }, '*'); } catch (err) {}
    }
  }, true);

  document.addEventListener('click', function(e) {
    var el = e.target;
    while (el && el.tagName !== 'A') el = el.parentElement;
    if (!el) return;
    var href = el.getAttribute('href');
    if (!href || href.charAt(0) === '#' || /^javascript:/i.test(href)) return;
    e.preventDefault();
    e.stopPropagation();
    try {
      var abs = new URL(href, CURRENT_URL).toString();
      window.parent.postMessage({ type: 'skyline-browser-nav', url: abs }, '*');
    } catch (err) {}
  }, true);

  document.addEventListener('submit', function(e) {
    var form = e.target;
    if (!form || form.tagName !== 'FORM') return;
    var method = (form.getAttribute('method') || 'get').toLowerCase();
    if (method !== 'get') return;
    e.preventDefault();
    e.stopPropagation();
    try {
      var action = form.getAttribute('action') || CURRENT_URL;
      var target = new URL(action, CURRENT_URL);
      var fd = new FormData(form);
      fd.forEach(function(val, key) {
        target.searchParams.set(key, String(val));
      });
      window.parent.postMessage({ type: 'skyline-browser-nav', url: target.toString() }, '*');
    } catch (err) {}
  }, true);
})();
</script>`;
}

function toProxiedAssetUrl(rawRef: string, baseUrl: string): string {
  const trimmed = rawRef.trim();
  if (
    !trimmed ||
    trimmed.startsWith('data:') ||
    trimmed.startsWith('blob:') ||
    trimmed.startsWith('#') ||
    trimmed.startsWith('/api/browser/asset?') ||
    /^javascript:/i.test(trimmed)
  ) {
    return rawRef;
  }
  try {
    const abs = new URL(trimmed, baseUrl).toString();
    if (!/^https?:\/\//i.test(abs)) return rawRef;
    return `/api/browser/asset?url=${encodeURIComponent(abs)}`;
  } catch {
    return rawRef;
  }
}

export function rewriteCssForInAppProxy(cssText: string, cssUrl: string): string {
  return cssText
    .replace(/url\(\s*(['"]?)([^)'"]+)\1\s*\)/gi, (full, _q, ref) => {
      const proxied = toProxiedAssetUrl(ref, cssUrl);
      return proxied === ref ? full : `url("${proxied}")`;
    })
    .replace(/@import\s+(['"])([^'"]+)\1/gi, (full, q, ref) => {
      const proxied = toProxiedAssetUrl(ref, cssUrl);
      return proxied === ref ? full : `@import ${q}${proxied}${q}`;
    });
}

export function rewriteHtmlForInAppFrame(
  rawHtml: string,
  finalUrl: string,
  opts?: { proxyAssets?: boolean }
): { title: string; rewrittenHtml: string } {
  const titleMatch = rawHtml.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  const title = titleMatch ? titleMatch[1].replace(/\s+/g, ' ').trim() : finalUrl;

  let baseHref = finalUrl;
  try {
    baseHref = new URL(finalUrl).origin + '/';
  } catch {
    baseHref = finalUrl;
  }

  // Strip frame-blocking meta CSP / X-Frame-Options, base targets, and destructive SPA hydration/consent scripts
  // that hijack /api/browser/view routes, wipe SSR bodies, or trap keyboard focus
  let cleaned = rawHtml
    .replace(/<meta[^>]+http-equiv=["']?(?:Content-Security-Policy|X-Frame-Options)[^>]*>/gi, '')
    .replace(/<base[^>]*>/gi, '')
    .replace(/\btarget=["']_(?:top|parent)["']/gi, 'target="_self"')
    .replace(/<link\b[^>]*\brel=["']?modulepreload\b[^>]*>/gi, '')
    .replace(/<script\b[^>]*\bsrc=["'][^"']+["'][^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<script\b[^>]*type=["'][^"']*text\/javascript["'][^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/\bloading=["']lazy["']/gi, 'loading="eager"');

  if (opts?.proxyAssets) {
    // Proxy stylesheets, icons, and font preloads
    cleaned = cleaned.replace(/<link\b([^>]*)>/gi, (full, attrs) => {
      if (!/\brel=["']?(?:stylesheet|icon|apple-touch-icon|preload|manifest)\b/i.test(attrs)) {
        return full;
      }
      const nextAttrs = attrs
        .replace(/\bcrossorigin(?:=["'][^"']*["'])?/gi, '')
        .replace(/\bhref=(["'])([^"']+)\1/i, (_m: string, q: string, val: string) => {
          return `href=${q}${toProxiedAssetUrl(val, finalUrl)}${q}`;
        })
        .replace(/\b(imageSrcSet|srcset)=(["'])([^"']+)\2/gi, (_m: string, attr: string, q: string, val: string) => {
          const rewritten = val
            .split(/,\s+(?=(?:https?:\/\/|\/))/i)
            .map((part: string) => {
              const bits = part.trim().split(/\s+/);
              if (!bits[0]) return part;
              bits[0] = toProxiedAssetUrl(bits[0], finalUrl);
              return bits.join(' ');
            })
            .join(', ');
          return `${attr}=${q}${rewritten}${q}`;
        });
      return `<link${nextAttrs}>`;
    });

    // Proxy img & source src / srcset
    cleaned = cleaned.replace(/<(img|source)\b([^>]*)>/gi, (_full, tag, attrs) => {
      let nextAttrs = attrs.replace(/\bsrc=(["'])([^"']+)\1/i, (_m: string, q: string, val: string) => {
        return `src=${q}${toProxiedAssetUrl(val, finalUrl)}${q}`;
      });
      nextAttrs = nextAttrs.replace(/\bsrcset=(["'])([^"']+)\1/i, (_m: string, q: string, val: string) => {
        const rewritten = val
          .split(/,\s+(?=(?:https?:\/\/|\/))/i)
          .map((part: string) => {
            const bits = part.trim().split(/\s+/);
            if (!bits[0]) return part;
            bits[0] = toProxiedAssetUrl(bits[0], finalUrl);
            return bits.join(' ');
          })
          .join(', ');
        return `srcset=${q}${rewritten}${q}`;
      });
      return `<${tag}${nextAttrs}>`;
    });
  }

  const noBlueFocusCss = `<style>*:focus:not(:focus-visible){outline:none!important;}input:focus,textarea:focus{outline:none!important;}</style>`;
  // Only inject external <base> when NOT proxying assets locally, otherwise /api/browser/asset resolves to external origin
  const headInject = opts?.proxyAssets
    ? `<meta name="viewport" content="width=device-width, initial-scale=1">\n${noBlueFocusCss}`
    : `<base href="${escapeHtml(baseHref)}">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n${noBlueFocusCss}`;
  const bridge = buildInAppBridgeScript(finalUrl);

  if (/<head[^>]*>/i.test(cleaned)) {
    cleaned = cleaned.replace(/<head[^>]*>/i, (m) => `${m}\n${headInject}\n${bridge}`);
  } else {
    cleaned = `<!doctype html><html><head>${headInject}${bridge}</head><body>${cleaned}</body></html>`;
  }

  return { title, rewrittenHtml: cleaned };
}

export interface YouTubeVideoCard {
  videoId: string;
  title: string;
  channel: string;
  thumbnail: string;
  url: string;
}

export function extractYouTubeVideosFromHtml(html: string): YouTubeVideoCard[] {
  const cards: YouTubeVideoCard[] = [];
  const seen = new Set<string>();

  // Match videoRenderer objects inside ytInitialData JSON
  const re =
    /"videoId":"([A-Za-z0-9_-]{11})"[\s\S]{0,600}?"title":\{"runs":\[\{"text":"([^"\\]*(?:\\.[^"\\]*)*)"\}\][\s\S]{0,900}?"(?:longBylineText|ownerText)":\{"runs":\[\{"text":"([^"\\]*(?:\\.[^"\\]*)*)"/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null && cards.length < 18) {
    const videoId = m[1];
    if (seen.has(videoId)) continue;
    seen.add(videoId);
    let title = m[2];
    let channel = m[3];
    try {
      title = JSON.parse(`"${title}"`);
    } catch {
      /* keep raw */
    }
    try {
      channel = JSON.parse(`"${channel}"`);
    } catch {
      /* keep raw */
    }
    cards.push({
      videoId,
      title,
      channel,
      thumbnail: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
      url: `https://www.youtube.com/watch?v=${videoId}`,
    });
  }

  return cards;
}

export interface SearchResultItem {
  title: string;
  url: string;
  snippet: string;
}

export function parseDuckDuckGoHtmlResults(html: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const seen = new Set<string>();
  const linkRe = /<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
  let m: RegExpExecArray | null;
  while ((m = linkRe.exec(html)) !== null && items.length < 15) {
    let href = m[1].replace(/&amp;/g, '&');
    if (href.includes('uddg=')) {
      try {
        const parsed = new URL(href, 'https://duckduckgo.com');
        const target = parsed.searchParams.get('uddg');
        if (target) href = target;
      } catch {
        /* keep */
      }
    }
    if (!/^https?:\/\//i.test(href) || seen.has(href)) continue;
    seen.add(href);
    const title = m[2].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
    const after = html.slice(m.index + m[0].length, m.index + m[0].length + 600);
    const snipM = after.match(/class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/a>/i);
    const snippet = snipM ? snipM[1].replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim() : '';
    if (title) items.push({ title, url: href, snippet });
  }
  return items;
}
