(() => {
  'use strict';
  const $ = (selector) => document.querySelector(selector);
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const controls = $('.experience-controls');
  const motionButton = $('.motion-toggle');
  const soundButton = $('.sound-toggle');
  const descent = $('.descent');
  const encounter = $('.encounter');
  let motionEnabled = !reducedMotion.matches;
  let frame = 0;
  let geometry = null;
  let ambience = null;
  let soundEnabled = false;
  let soundPending = false;
  let lightLevel = 1;
  const clamp = (n) => Math.max(0, Math.min(1, n));
  const ease = (n) => { n = clamp(n); return n * n * (3 - 2 * n); };
  const range = (n, start, end) => ease((n - start) / (end - start));
  const property = (element, name, value) => element.style.setProperty(name, String(value));

  function measure() {
    geometry = {
      buildingTop: descent.getBoundingClientRect().top + window.scrollY,
      buildingLength: Math.max(1, descent.offsetHeight - $('.building-stage').offsetHeight),
      listenerTop: encounter.getBoundingClientRect().top + window.scrollY,
      listenerLength: Math.max(1, encounter.offsetHeight - $('.encounter-stage').offsetHeight)
    };
    schedule();
  }

  function render() {
    frame = 0;
    if (!geometry) return;
    if (!motionEnabled) { lightLevel = window.scrollY < encounter.offsetTop ? 1 : 0; updateVolume(); return; }
    const p = clamp((window.scrollY - geometry.buildingTop) / geometry.buildingLength);
    const q = clamp((window.scrollY - geometry.listenerTop) / geometry.listenerLength);
    const arrival = 1 - range(p, .06, .27);
    const passage = range(p, .23, .36) * (1 - range(p, .58, .72));
    const blackout = range(p, .72, .87);
    property(descent, '--travel', p.toFixed(4));
    property(descent, '--arrival', arrival.toFixed(4));
    property(descent, '--arrival-pointer', arrival > .2 ? 'auto' : 'none');
    property(descent, '--passage', passage.toFixed(4));
    property(descent, '--blackout', blackout.toFixed(4));
    property(descent, '--office', (range(p, .25, .49) * (1 - range(p, .68, .91))).toFixed(4));
    property(descent, '--dark', range(p, .53, .91).toFixed(4));
    property(descent, '--advance', (1 + p * .34).toFixed(4));
    property(descent, '--slide', (-p * 70) + 'px');
    property(descent, '--turn', (p * 3) + 'deg');
    property(descent, '--door', (-p * 150) + 'px');
    const reveal = range(q, .37, .66);
    property(encounter, '--reveal', reveal.toFixed(4));
    property(encounter, '--lurk', (1 - range(q, .29, .43)).toFixed(4));
    property(encounter, '--silhouette', ((.09 + range(q, 0, .32) * .6) * (1 - range(q, .36, .56))).toFixed(4));
    property(encounter, '--approach', (1 + range(q, .05, .35) * .1).toFixed(4));
    property(encounter, '--aperture', ((1 - range(q, .35, .67)) * 85) + '%');
    $('.entry-link').tabIndex = arrival > .2 ? 0 : -1;
    $('.reveal-copy .text-link').tabIndex = reveal > .5 ? 0 : -1;
    const sceneText = p < .28 ? '01 — Arrival' : p < .68 ? '01 — Past reception' : '02 — Power lost';
    if ($('.scene-status').textContent !== sceneText) $('.scene-status').textContent = sceneText;
    const encounterText = reveal > .75 ? 'It knows you are here.' : 'Something is listening.';
    if ($('.encounter-status').textContent !== encounterText) $('.encounter-status').textContent = encounterText;
    lightLevel = 1 - range(p, .52, .87);
    updateVolume();
  }

  function schedule() { if (!frame && !document.hidden) frame = requestAnimationFrame(render); }

  function setMotion(enabled) {
    const anchor = [$('.footer'), $('.download'), $('.records'), encounter, descent].find((element) => window.scrollY >= element.offsetTop) || descent;
    const wasEnabled = document.body.classList.contains('motion-enabled');
    const relativeTop = Math.max(-window.innerHeight * .25, anchor.getBoundingClientRect().top);
    motionEnabled = enabled;
    document.body.classList.toggle('motion-enabled', enabled);
    motionButton.textContent = enabled ? 'Motion on' : 'Motion off';
    motionButton.setAttribute('aria-pressed', String(enabled));
    if (!enabled) {
      descent.removeAttribute('style'); encounter.removeAttribute('style');
      $('.entry-link').tabIndex = 0; $('.reveal-copy .text-link').tabIndex = 0;
      if (wasEnabled && anchor === descent && window.scrollY > window.innerHeight) window.scrollTo({ top: window.innerHeight, behavior: 'instant' });
    }
    if (wasEnabled !== enabled && anchor !== descent) window.scrollTo({ top: Math.max(0, anchor.offsetTop - relativeTop), behavior: 'instant' });
    measure();
  }

  function updateVolume() {
    if (ambience) ambience.volume = soundEnabled && !document.hidden ? .22 * lightLevel : 0;
  }

  async function toggleSound() {
    if (soundPending) return;
    if (soundEnabled) {
      soundEnabled = false;
      ambience.pause();
    } else {
      // Created only inside this user gesture. Never preloaded or autoplayed.
      ambience ||= new Audio('assets/audio/hum.wav');
      ambience.loop = true;
      ambience.volume = .22 * lightLevel;
      soundPending = true;
      try {
        await ambience.play();
        soundEnabled = true;
        if (document.hidden) ambience.pause();
      } catch {
        $('#sound-status').textContent = 'Sound could not start. You can continue without it.';
        return;
      } finally { soundPending = false; }
    }
    soundButton.setAttribute('aria-pressed', String(soundEnabled));
    soundButton.lastElementChild.textContent = soundEnabled ? 'Sound on' : 'Sound off';
    updateVolume();
  }

  controls.hidden = false;
  motionButton.addEventListener('click', () => setMotion(!motionEnabled));
  reducedMotion.addEventListener('change', () => setMotion(!reducedMotion.matches));
  soundButton.addEventListener('click', toggleSound);
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', measure, { passive: true });
  window.addEventListener('load', measure, { once: true });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      if (frame) cancelAnimationFrame(frame);
      frame = 0;
      if (ambience) ambience.pause();
    } else {
      if (soundEnabled) ambience.play().catch(() => {
        soundEnabled = false;
        soundButton.setAttribute('aria-pressed', 'false');
        soundButton.lastElementChild.textContent = 'Sound off';
      });
      measure();
    }
    updateVolume();
  });
  window.addEventListener('pagehide', () => { if (ambience) ambience.pause(); });
  window.addEventListener('pageshow', measure);
  $('.entry-link').addEventListener('click', (event) => {
    if (!motionEnabled) return;
    event.preventDefault();
    window.scrollTo({ top: geometry.buildingTop + geometry.buildingLength * .43, behavior: 'smooth' });
  });
  setMotion(motionEnabled);

  const sectors = [
    ['Arrival', 'An empty reception. A dead exit. Find out what it needs before going deeper.', 'Find the exit. Understand the two circuits.'],
    ['Offices', 'Quiet rooms and familiar doors. The first switch is somewhere in the offices. Remember your landmarks.', 'Restore the office circuit.'],
    ['Service / Blackout', 'The service route takes you past the light. Use the flashlight, watch the doors, and find the second switch.', 'Restore the service circuit.'],
    ['Return', 'Both circuits are live. The same building, on the way back. The Listener is still inside.', 'Return to the exit.']
  ];
  const sectorButtons = [...document.querySelectorAll('[data-sector]')];
  function selectSector(index) {
    sectorButtons.forEach((button, i) => button.setAttribute('aria-pressed', String(i === index)));
    [$('#sector-name').textContent, $('#sector-description').textContent, $('#sector-objective').textContent] = sectors[index];
  }
  sectorButtons.forEach((button, index) => {
    button.addEventListener('click', () => selectSector(index));
    button.addEventListener('keydown', (event) => {
      const target = { ArrowRight: (index + 1) % 4, ArrowDown: (index + 1) % 4, ArrowLeft: (index + 3) % 4, ArrowUp: (index + 3) % 4, Home: 0, End: 3 }[event.key];
      if (target === undefined) return;
      event.preventDefault(); selectSector(target); sectorButtons[target].focus();
    });
  });

  const lightbox = $('.lightbox');
  let lastTrigger = null;
  document.querySelectorAll('[data-lightbox]').forEach((link) => link.addEventListener('click', (event) => {
    if (typeof lightbox.showModal !== 'function' || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    lastTrigger = link;
    $('#lightbox-image').src = link.href;
    $('#lightbox-image').alt = link.querySelector('img').alt;
    $('#lightbox-caption').textContent = link.dataset.caption;
    lightbox.showModal();
    document.body.classList.add('viewing-image');
  }));
  lightbox.addEventListener('close', () => { document.body.classList.remove('viewing-image'); lastTrigger?.focus({ preventScroll: true }); });
  lightbox.addEventListener('click', (event) => {
    if (event.target !== lightbox) return;
    const rect = lightbox.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) lightbox.close();
  });
})();
