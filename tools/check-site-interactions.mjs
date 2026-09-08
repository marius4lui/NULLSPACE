// Source-level behavior checks using a minimal DOM double, not browser or visual QA.
// Run: node tools/check-site-interactions.mjs
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
const source = readFileSync(new URL('../site/script.js', import.meta.url), 'utf8');

async function scenario(reduced = false) {
  const frames = new Map();
  let frameId = 0;
  const windowEvents = {};
  const nodes = new Map();
  let context;
  class Node {
    constructor() {
      this.attrs = {}; this.events = {}; this.textContent = ''; this.tabIndex = 0;
      this.offsetTop = 0; this.offsetHeight = 900; this.hidden = false;
      this.styles = {};
      this.style = { setProperty: (k, v) => { this.styles[k] = v; } };
      const classes = new Set();
      this.classList = { contains: (k) => classes.has(k), add: (k) => classes.add(k), remove: (k) => classes.delete(k), toggle: (k, on) => on ? classes.add(k) : classes.delete(k) };
    }
    addEventListener(type, fn) { (this.events[type] ||= []).push(fn); }
    async fire(type, event = {}) { for (const fn of this.events[type] || []) await fn(event); }
    setAttribute(k, v) { this.attrs[k] = v; }
    removeAttribute(k) { if (k === 'style') this.styles = {}; else delete this.attrs[k]; }
    getBoundingClientRect() { return { top: this.offsetTop - context.window.scrollY, left: 0, right: 600, bottom: 900 }; }
    focus() { this.focused = true; }
    querySelector() { return { alt: 'Original asset' }; }
    showModal() { this.open = true; }
    close() { this.open = false; return this.fire('close'); }
  }
  const get = (selector) => { if (!nodes.has(selector)) nodes.set(selector, new Node()); return nodes.get(selector); };
  const body = new Node();
  const sectors = Array.from({ length: 4 }, () => new Node());
  const images = [new Node()]; images[0].href = 'assets/environment.webp'; images[0].dataset = { caption: 'Original render' };
  const preference = { matches: reduced, addEventListener: (_, fn) => { preference.change = fn; } };
  const audioInstances = [];
  class Audio {
    constructor(src) { this.src = src; this.paused = true; this.volume = 1; audioInstances.push(this); }
    async play() { this.paused = false; }
    pause() { this.paused = true; }
  }
  const document = new Node();
  Object.assign(document, { body, hidden: false, querySelector: get, querySelectorAll: (selector) => selector === '[data-sector]' ? sectors : images });
  context = { document, Audio, console, requestAnimationFrame: (fn) => { frames.set(++frameId, fn); return frameId; }, cancelAnimationFrame: (id) => frames.delete(id), window: { scrollY: 0, innerHeight: 900, matchMedia: () => preference, addEventListener: (key, fn) => { (windowEvents[key] ||= []).push(fn); }, scrollTo: ({ top }) => { context.window.scrollY = top; } } };
  get('.sound-toggle').lastElementChild = new Node();
  get('.descent').offsetHeight = 2790;
  get('.encounter').offsetTop = 2790; get('.encounter').offsetHeight = 2340;
  get('.records').offsetTop = 5130; get('.download').offsetTop = 5800; get('.footer').offsetTop = 6700;
  const flush = () => { const pending = [...frames.values()]; frames.clear(); pending.forEach((fn) => fn()); };
  const scroll = async (y) => { context.window.scrollY = y; for (const fn of windowEvents.scroll) fn(); flush(); };
  vm.runInNewContext(source, context, { filename: 'site/script.js' });
  flush();
  assert.equal(audioInstances.length, 0, 'Audio must not be created on page load');
  assert.equal(frames.size, 0, 'No permanent animation loop');
  assert.equal(body.classList.contains('motion-enabled'), !reduced);
  assert.equal(get('.experience-controls').hidden, false);
  if (reduced) { assert.equal(get('.motion-toggle').textContent, 'Motion off'); return; }
  await get('.sound-toggle').fire('click');
  assert.equal(audioInstances.length, 1);
  assert.equal(audioInstances[0].paused, false);
  assert.equal(get('.sound-toggle').attrs['aria-pressed'], 'true');
  await scroll(1890 * .45);
  assert.equal(Number(get('.descent').styles['--arrival']), 0);
  assert.equal(Number(get('.descent').styles['--passage']), 1);
  assert.ok(Number(get('.descent').styles['--office']) > .9);
  await scroll(1890);
  assert.equal(Number(get('.descent').styles['--blackout']), 1);
  assert.equal(audioInstances[0].volume, 0, 'Blackout silences the hum');
  await scroll(2790 + 1440 * .1);
  assert.equal(Number(get('.encounter').styles['--reveal']), 0);
  assert.ok(Number(get('.encounter').styles['--silhouette']) < .3);
  await scroll(2790 + 1440 * .8);
  assert.equal(Number(get('.encounter').styles['--reveal']), 1);
  assert.equal(get('.reveal-copy .text-link').tabIndex, 0);
  await get('.motion-toggle').fire('click');
  assert.equal(body.classList.contains('motion-enabled'), false);
  assert.equal(Object.keys(get('.encounter').styles).length, 0);
  assert.equal(get('.entry-link').tabIndex, 0);
  preference.matches = true; preference.change(); flush();
  assert.equal(body.classList.contains('motion-enabled'), false);
  await sectors[0].fire('keydown', { key: 'End', preventDefault() {} });
  assert.equal(get('#sector-name').textContent, 'Return');
  assert.equal(sectors[3].attrs['aria-pressed'], 'true');
  assert.equal(sectors[3].focused, true);
  await images[0].fire('click', { preventDefault() {} });
  assert.equal(get('.lightbox').open, true);
  assert.equal(get('#lightbox-image').src, images[0].href);
  await get('.lightbox').close();
  assert.equal(images[0].focused, true);
  document.hidden = true; await document.fire('visibilitychange');
  assert.equal(audioInstances[0].paused, true);
  assert.equal(audioInstances[0].volume, 0);
  assert.equal(frames.size, 0);
  document.hidden = false; await document.fire('visibilitychange'); flush();
  await get('.sound-toggle').fire('click');
  assert.equal(audioInstances[0].paused, true);
  assert.equal(get('.sound-toggle').attrs['aria-pressed'], 'false');
}
await scenario();
await scenario(true);
console.log('PASS: opt-in audio, blackout silence, staged reveal, reduced-motion defaults/change, pause control, directory keyboard, dialog focus return, hidden-tab pause. DOM double only; no browser or screenshot validation.');
