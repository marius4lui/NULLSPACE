"use strict";

// Native disclosure remains usable when JavaScript is unavailable.
const mobileMenu = document.querySelector(".mobile-menu");
if (mobileMenu) {
  mobileMenu.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => { mobileMenu.open = false; });
  });
  mobileMenu.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    mobileMenu.open = false;
    mobileMenu.querySelector("summary").focus();
  });
}

// Static, local-only interactions. No tracking, external requests or saved state.
const sectors = [
  {letter:"A",type:"Orientation / Quiet arrival",name:"Arrival",quote:"Everything looks almost normal.",description:"An empty reception suite. A dead exit. A circuit diagram that promises a way out. Learn the building while it is still quiet.",objective:"Find the exit. Understand what it needs."},
  {letter:"B",type:"Circulation / Nested offices",name:"Offices",quote:"You have passed this wall before.",description:"Offset partitions, boxed columns and a carpet repair worth remembering. Find the pistol and the office power switch. A loop gives you more than one way out.",objective:"Restore the office circuit. Remember the doors."},
  {letter:"C",type:"Power failure / Service route",name:"Service / Blackout",quote:"The worst part is the missing hum.",description:"Lower ceilings, utility doors and a short dark passage. The second switch waits beyond the familiar light. Your flashlight and directional hearing matter now.",objective:"Restore the service circuit. Keep an escape route."},
  {letter:"D",type:"Escape / Return route",name:"Return",quote:"The exit is where you left it.",description:"Both circuits are restored. Return through a building you now partly understand. Doors, quiet movement and a well-timed shot can buy the time you need. You do not have to kill the Listener.",objective:"Reach the powered exit."}
];

const sectorButtons = [...document.querySelectorAll("[data-sector]")];
function selectSector(index) {
  const sector = sectors[index];
  if (!sector) return;
  sectorButtons.forEach((button, buttonIndex) => {
    const selected = buttonIndex === index;
    button.classList.toggle("active", selected);
    button.setAttribute("aria-pressed", String(selected));
  });
  document.querySelectorAll("[data-route]").forEach((node) => {
    node.classList.toggle("active", Number(node.dataset.route) === index);
  });
  for (const key of ["letter", "type", "name", "quote", "description", "objective"]) {
    document.getElementById(`sector-${key}`).textContent = sector[key];
  }
}
sectorButtons.forEach((button, index) => {
  button.addEventListener("click", () => selectSector(index));
  button.addEventListener("keydown", (event) => {
    let next;
    if (event.key === "ArrowDown" || event.key === "ArrowRight") next = (index + 1) % sectors.length;
    if (event.key === "ArrowUp" || event.key === "ArrowLeft") next = (index + sectors.length - 1) % sectors.length;
    if (event.key === "Home") next = 0;
    if (event.key === "End") next = sectors.length - 1;
    if (next === undefined) return;
    event.preventDefault();
    sectorButtons[next].focus();
    selectSector(next);
  });
});

const lightbox = document.getElementById("lightbox");
const lightboxImage = document.getElementById("lightbox-image");
const lightboxCaption = document.getElementById("lightbox-caption");
let opener = null;
if (lightbox && typeof lightbox.showModal === "function") {
  document.querySelectorAll("[data-lightbox]").forEach((link) => {
    link.addEventListener("click", (event) => {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      event.preventDefault();
      opener = link;
      lightboxImage.src = link.href;
      lightboxImage.alt = link.querySelector("img").alt;
      lightboxCaption.textContent = link.dataset.caption;
      lightbox.showModal();
    });
  });
  lightbox.addEventListener("click", (event) => {
    const rect = lightbox.getBoundingClientRect();
    if (event.target === lightbox && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) lightbox.close();
  });
  lightbox.addEventListener("close", () => opener?.focus());
}

// Optional motion follows the system preference. No saved state or tracking.
const motionToggle = document.querySelector(".motion-toggle");
if (motionToggle) {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  let manualPause = false;
  function syncMotion() {
    const paused = reducedMotion.matches || manualPause;
    document.documentElement.dataset.motion = paused ? "off" : "on";
    motionToggle.setAttribute("aria-pressed", String(paused));
    motionToggle.textContent = paused ? "Motion: off" : "Motion: on";
    motionToggle.setAttribute("aria-label", reducedMotion.matches
      ? "Motion disabled by your system preference"
      : paused ? "Enable background motion" : "Pause background motion");
    motionToggle.disabled = reducedMotion.matches;
  }
  motionToggle.hidden = false;
  motionToggle.addEventListener("click", () => {
    manualPause = !manualPause;
    syncMotion();
  });
  reducedMotion.addEventListener("change", syncMotion);
  syncMotion();
}
