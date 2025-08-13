const portInput = document.getElementById('port');
const pathInput = document.getElementById('path');
const restartBtn = document.getElementById('restart');
const openActiveBtn = document.getElementById('openActive');
const openNewBtn = document.getElementById('openNew');

function buildUrl() {
  const p = (portInput.value || '').toString().trim();
  const rel = (pathInput.value || '').toString().trim().replace(/^\/+/, '');
  return `http://127.0.0.1:${p}/${rel}`;
}

document.querySelectorAll('.quick button[data-path]').forEach(btn => {
  btn.addEventListener('click', () => {
    pathInput.value = btn.getAttribute('data-path');
  });
});

openActiveBtn.addEventListener('click', () => {
  const url = buildUrl();
  chrome.tabs.update({ url });
  chrome.storage.local.set({ lastPort: portInput.value.trim(), lastPath: pathInput.value.trim() });
});

openNewBtn.addEventListener('click', () => {
  const url = buildUrl();
  chrome.tabs.create({ url });
  chrome.storage.local.set({ lastPort: portInput.value.trim(), lastPath: pathInput.value.trim() });
});

restartBtn.addEventListener('click', () => {
  const p = (portInput.value || '').toString().trim();
  chrome.storage.local.set({ lastPort: p, lastPath: pathInput.value.trim() });
  chrome.runtime.sendNativeMessage('porttool.native', { action: 'restart', port: p }, () => {
    const url = buildUrl();
    chrome.tabs.create({ url });
  });
});

chrome.storage.local.get(['lastPort','lastPath'], (s) => {
  if (s.lastPort) portInput.value = s.lastPort;
  if (s.lastPath) pathInput.value = s.lastPath;
});


