# NULLSPACE v0.1 — Raw Beta

Ein Ausgang ohne Strom. Vier feste Schwierigkeitsgrade. Ein Wesen, das Sicht- und Geräuschspuren verfolgt.

Dieser Build enthält den vollständigen kleinen Ablauf bis zum Ende, ist aber **noch keine fertige Veröffentlichung**. Erstspielzeit, Atmosphäre und Audio müssen weiter geprüft werden. Ziel sind 10–15 Minuten; ein bekannter gezielter Prüfweg ist derzeit deutlich kürzer. Keine Wartezeit wird als Spielzeitnachweis gerechnet.

## Starten

Linux: `./nullspace.x86_64` im entpackten Build-Verzeichnis starten. Falls die Datei beim Kopieren ihr Ausführungsrecht verloren hat: `chmod +x nullspace.x86_64`.

Windows: `NULLSPACE.exe`, sofern der Windows-Cross-Export vorliegt. Native Windows-Prüfung steht aus.

Benötigt werden eine Vulkan-fähige GPU mit aktuellen Treibern, Tastatur/Maus und ein Audioausgang; Kopfhörer sind für Richtungsgeräusche sinnvoll. Prüfgerät: Linux/Fedora, Ryzen 5 7535HS, Radeon 660M, 30 GiB RAM. Das ist keine bestätigte Mindestanforderung für andere Hardware.

Grafikprofil **Laptop**: 75% interne Renderauflösung, reduzierte Schatten, keine SSAO. **Enhanced**: native interne Auflösung und Umgebungsverdeckung. VSync und FPS-Limit sind einstellbar. Keine Leistungszusage für ungeprüfte Hardware.

## Steuerung

WASD bewegen · Maus umsehen · Shift sprinten · Strg ducken · F Taschenlampe · E interagieren · linke Maustaste schießen · R nachladen · Escape Pause.

Die Taschenlampe braucht keine Batterie. Türen können geöffnet und wieder geschlossen werden. Schüsse machen aufmerksam; Treffer verschaffen Zeit. Sichtkontakt zu unterbrechen und einen anderen Weg zu nehmen bleibt wichtig. Stromkästen zuerst öffnen, dann mit E den Schalter umlegen.

Vor **Start** wird Easy, Medium, Hard oder Nightmare gewählt; Medium ist Standard und die Wahl bleibt für den Lauf und seine Checkpoints fest. Easy benötigt nur Office A. Medium behält Office A und Service B. Hard ergänzt Emergency C mit kurzem Sicherheitsriegel. Nightmare nutzt dieselben drei Schalter, verlangt davor aber die deutlich markierte Sicherung im Service Bypass. Hinweise im Pause-Menü zeigen den nächsten Schritt.

## Speicherstand und Einstellungen

Pistolenaufnahme und Stromschalter speichern automatisch. Nach Tod lässt sich der sichere Checkpoint neu starten. **Continue** erscheint bei einem gültigen, noch nicht abgeschlossenen Spielstand. **Start** beginnt eine neue Runde und ersetzt den kleinen Spielstand. Ein abgeschlossenes Spiel bleibt als beendet gespeichert; eine weitere Runde beginnt mit Start.

Linux-Daten liegen unter `${XDG_DATA_HOME:-~/.local/share}/NULLSPACE/`: `saves/checkpoint-short.json`, `preferences/settings.json` und lokale Prüftelemetrie. Alte Entwicklungs-Spielstände `checkpoint.json` werden nicht überschrieben. Das Spiel benötigt kein Konto und sendet keine Telemetrie ins Netz.

## Noch offen

Natürliche Erstspielzeit und Spannung, abschließende Audio-Hörprüfung, einzelne Präsentations-/Erstnutzungsruckler sowie zwei abschließende erfolgreiche Export-Durchläufe. Automatisierte Prüfungen und aufgezeichnetes Audio sind kein Beweis für subjektives Spielgefühl oder gehörte Audioqualität. Aktuelle Details: ISSUES.md und evidence/section/solo-e/ im Repository.
