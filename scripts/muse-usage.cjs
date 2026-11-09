#!/usr/bin/env node
// muse-usage.cjs — read the Muse agent's usage figures out of the running web
// app over CDP, and write them to a cache file the bar widget reads.
//
// The app has no REST endpoint for this: the figures arrive over its websocket
// and are rendered into Settings -> General. So we drive the page the way a
// person would and scrape the rendered text.
//
// Usage: node muse-usage.cjs [--out <file>]
const WS = require('ws');
const fs = require('fs');

const OUT = process.argv.includes('--out')
  ? process.argv[process.argv.indexOf('--out') + 1]
  : `${process.env.HOME}/.cache/omarchy/muse-usage.json`;

const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  const list = await (await fetch('http://localhost:9222/json/list')).json();
  const page = list.find(t => t.type === 'page' && t.url.includes('muse.ai'));
  if (!page) {
    console.error('no muse.ai page open (is the browser running with --remote-debugging-port?)');
    process.exit(2);
  }

  const ws = new WS(page.webSocketDebuggerUrl, { perMessageDeflate: false });
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, { res, rej });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  ws.on('message', (raw) => {
    const msg = JSON.parse(raw);
    if (msg.id && pending.has(msg.id)) {
      const { res, rej } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? rej(new Error(JSON.stringify(msg.error))) : res(msg.result);
    }
  });
  await new Promise(r => ws.on('open', r));
  await send('Runtime.enable');
  await send('Page.enable');

  const evalJs = async (expr) => {
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 200));
    return r.result?.value;
  };
  const click = async (x, y) => {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    for (const type of ['mousePressed', 'mouseReleased']) {
      await send('Input.dispatchMouseEvent', {
        type, x, y, button: 'left', clickCount: 1,
        buttons: type === 'mousePressed' ? 1 : 0
      });
    }
  };
  // Click a labelled control only when it is genuinely on screen.
  const clickLabel = async (re) => {
    const hit = await evalJs(`(() => {
      const re = ${re};
      const vw = innerWidth, vh = innerHeight;
      const els = [...document.querySelectorAll('button,[role="button"],a,[role="menuitem"],[role="tab"],li')];
      const hit = els.find(e => {
        const t = (e.getAttribute('aria-label') || e.textContent || '').trim();
        if (!re.test(t) || t.length > 40) return false;
        const r = e.getBoundingClientRect();
        if (r.width < 8 || r.height < 8) return false;
        if (r.right < 0 || r.bottom < 0 || r.left > vw || r.top > vh) return false;
        const st = getComputedStyle(e);
        return st.visibility !== 'hidden' && st.display !== 'none' && Number(st.opacity) > 0.05;
      });
      if (!hit) return null;
      hit.scrollIntoView({ block: 'center', inline: 'center' });
      const r = hit.getBoundingClientRect();
      return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2) };
    })()`);
    if (!hit) return false;
    await click(hit.x, hit.y);
    return true;
  };

  // The app may already be sitting on the General page (a previous run left it
  // there), or on the chat. Read the figures where they are; only navigate
  // when they are not on screen.
  const readUsage = () => evalJs(`(() => {
    const lines = document.body.innerText.split('\\n').map(l => l.trim()).filter(Boolean);
    const has = lines.some(l => /^\\d+% used \\(/i.test(l));
    if (!has) return null;
    const plan = lines.find(l => /plan$/i.test(l) && l.length < 30) || '';
    const windows = [];
    for (let i = 0; i < lines.length; i++) {
      const m = /^(\\d+)% used \\(([^)]+left)\\)$/i.exec(lines[i]);
      if (!m) continue;
      let name = (lines[i - 1] || '').replace(/\\s*resets? on .*$/i, '').trim();
      if (!name || name.length > 30) name = 'Window';
      windows.push({ name, percentUsed: Number(m[1]), left: m[2] });
    }
    return { plan: plan.replace(/\\s*plan$/i, ''), windows };
  })()`);

  let usage = await readUsage();
  let navigated = false;

  // Walk toward the usage page from wherever the app is: the chat, the More
  // menu, the Settings list, or already there. Each pass clicks the furthest
  // step that is on screen (General, else Settings, else More) and looks again.
  for (let pass = 0; !usage && pass < 5; pass++) {
    navigated = true;
    if (await clickLabel('/^general$/i')) await sleep(3000);
    else if (await clickLabel('/^settings$/i')) await sleep(2000);
    else if (await clickLabel('/^more$/i')) await sleep(1500);
    else break;
    usage = await readUsage();
  }

  if (!usage || !usage.windows.length) {
    console.error('no usage figures found on screen');
    process.exit(6);
  }

  const out = {
    fetchedAt: new Date().toISOString(),
    plan: usage.plan || '',
    windows: usage.windows
  };

  fs.mkdirSync(require('path').dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
  console.log(JSON.stringify(out));

  // Leave the app where we found it, but only if we are the ones who moved it:
  // someone reading the Settings page themselves must not be yanked off it.
  if (navigated) {
    for (const type of ['keyDown', 'keyUp']) {
      await send('Input.dispatchKeyEvent', {
        type, key: 'Escape', code: 'Escape',
        windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27
      });
    }
    await sleep(800);
    if (await readUsage()) await clickLabel('/^chats?$/i');
    await sleep(800);
    const left = !(await readUsage());
    console.error(left ? 'returned to chat' : 'WARNING: still on the usage page');
  }
  ws.close();
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
