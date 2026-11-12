(() => {
  const THEME_URL = chrome.runtime.getURL("theme.css");
  const VAR_RE = /--(bg|surface|primary|secondary|fg|muted)\s*:\s*([^;]+);/g;

  async function syncTheme() {
    try {
      const res = await fetch(`${THEME_URL}?t=${Date.now()}`, { cache: "no-store" });
      if (!res.ok) return;
      const css = await res.text();
      const root = document.documentElement.style;
      for (const match of css.matchAll(VAR_RE)) {
        root.setProperty(`--${match[1]}`, match[2].trim());
      }
    } catch {
      // Ignore transient read errors during atomic theme writes
    }
  }

  requestAnimationFrame(() => {
    document.documentElement.classList.add("ready");
  });

  window.addEventListener("focus", syncTheme);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") {
      syncTheme();
    }
  });
})();
