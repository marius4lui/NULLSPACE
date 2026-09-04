"use strict";

// Static, local-only interactions. No tracking, external requests or saved state.
const sectors = [
  {letter:"A",type:"Orientation / 08 spaces planned",name:"Arrival",quote:"Everything looks almost normal.",description:"An empty reception suite. A dead exit. A circuit diagram that promises a way out. Learn the building while it is still quiet.",objective:"Find the exit. Understand what it needs."},
  {letter:"B",type:"Circulation / 10 spaces planned",name:"Grid",quote:"You have passed this wall before.",description:"Offset partitions, boxed columns and a single carpet repair worth remembering. The first relay reconnects a useful return loop—and gives the quiet a reason to end.",objective:"Restore the circulation relay. Remember the shortcut."},
  {letter:"C",type:"Exposure / 11 spaces planned",name:"Open Plan",quote:"You can see a long way. So can it.",description:"Broad diagonals and low partitions offer distance without the comfort of cover. The second relay changes the light and opens a passage toward the service rooms.",objective:"Restore distribution. Cross the open floor."},
  {letter:"D",type:"Infrastructure / 10 spaces planned",name:"Service",quote:"A closed door buys you seconds.",description:"Lower ceilings, painted doors, pipes and machinery. The shotgun belongs here. So do choices about which sound to follow, which door to close and when to leave.",objective:"Restore the return feed. Open the next route."},
  {letter:"E",type:"Power failure / 09 spaces planned",name:"Blackout",quote:"The worst part is the missing hum.",description:"The fixtures have failed. Familiar construction remains, but light and electrical room tone have withdrawn. Your flashlight, route memory and directional hearing matter now.",objective:"Follow the familiar architecture through the dark."},
  {letter:"F",type:"Phase control / 08 spaces planned",name:"Red Threshold",quote:"The building does not quite connect.",description:"Red oxide frames, faded maintenance paint and secondary passages that return at the wrong angle. Beyond the three restored relays, the main phase breaker waits.",objective:"Power the exit. Find your way back."}
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
