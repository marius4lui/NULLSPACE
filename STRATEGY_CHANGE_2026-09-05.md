# Verbindliche Strategieänderung — 5. September 2026

Vom Nutzer ausdrücklich autorisiert. Diese Änderung ersetzt widersprechende Vorgaben zu Architektur, Aufgabenzerlegung, Parallelität und Entwicklungsreihenfolge. Sie kürzt **nicht** den vereinbarten finalen Spielinhalt, senkt keine finalen Qualitätsanforderungen und erklärt den nächsten Abschnitt nicht zum fertigen Spiel. Originalvertrag, frühere Entwürfe, fehlgeschlagene Versuche und Prüfbelege bleiben erhalten. Zeithorizont des Nutzers: höchstens zwei Monate; begrenztes Codex-Kontingent, keine Kontingent- oder Fertigstellungsgarantie.

## Nächster Liefergegenstand

Ein zusammenhängender, sinnvoll etwa5–10 Minuten spielbarer Abschnitt des späteren Spiels:

Start → erkunden → Pistole aufnehmen → Geräusch erzeugen → Listener untersucht/verfolgt → schießen oder entkommen → Relais aktivieren → Ausgang erreichen → Ende oder Tod/Neustart.

Dieser Abschnitt verwendet vorhandene Originalassets und bleibt die erweiterbare Spielszene. Kein neues Wegwerfprojekt, keine weitere reine Vorschau als Ersatz. Der Abschnitt wird schrittweise A–E erweitert; nicht jedes Zwischenstadium besitzt bereits die volle Spielzeit.

## Entscheidungen: behalten / einfacher anbinden / später

| Entscheidung | Konkrete Komponenten |
|---|---|
| Behalten | Godot4.7.2/Blender5.2.1/Exportvorlagen; bestehende native Eingabe-/Aufnahmewerkzeuge; Originalraum/Modulkit inklusive korrigierter3D-Importe; Listener-Modell/Rig und vorhandene3Clips; geprüfte Einstellungen, Speicherung, InputGate, GameFlow und Zeit-/Restore-Verträge; sinnvolle Tests und sämtliche bisherigen Nachweise. |
| Einfacher anbinden | Eine Spielszene koordiniert Abschnitt/Ziel/Neustart/Ende; ein konkreter Player hält Bewegung/Blick/Interaktion/Gesundheit; konkrete Pistole mit eigenem Zustand; konkreter Listener mit Zustandsautomat und alternden Hinweisen; einfache Tür-/Relais-Szenen. Direkte typisierte Referenzen, Signale und wenige Tuning-Resources. Bestehende Speicherverträge nutzen, keine pauschale Kern-Neuschreibung. |
| Bis später zurückstellen | Universelle Adapter/Provider/Registries/Service-Schichten, vollständige Kampagnenakustik, zusätzliche Frameworks und Getter-Tests, unabhängige Übergaben jedes Mini-Details, weitere Website-/Präsentations-/Vorschau-Funktionen. Komplexes Stalking/Pacing, zweite Waffe und volle Kampagne werden auf dem funktionierenden Abschnitt ergänzt, nicht gestrichen. |

## Aktive Aufgabenfolge und sichtbare Ergebnisse

| Block | Danach konkret spielbar | Wirklich fehlend / Wiederverwendung | Praktischer Nachweis |
|---|---|---|---|
| A — Raum + Player | Im Originalraum laufen, kollidieren, umsehen, Taschenlampe und nahe Interaktion benutzen, pausieren/fortsetzen. | Ein Player und eine gemeinsame Spielszene fehlen. Originalraum/Materialien, Kern und InputGate wiederverwenden. Keine neue generische Schnittstellenschicht. | Export starten; Wege/Ecken/Wände, Licht, Interaktionsreichweite und gehaltene Eingaben bei Pause/Fokus testen; tatsächliche Bilder ansehen; konkrete Fehler beheben. |
| B — Pistole | Im selben Abschnitt Pistole aufnehmen, schießen, nachladen, Munition verbrauchen und Treffer sehen. | Originale Pistole/Schusszustand/Feedback fehlen. Vorhandene Spielszene/Player/Kern/Assets weiterführen. | Aufnehmen, leer/taktisch nachladen, leer schießen, unterbrechen; keine Doppelbuchung oder negativen Patronen; echte native Bedienung. |
| C — Listener | Geräusche locken den Listener, Sicht löst Verfolgung aus; er navigiert/greift an, reagiert auf Treffer; Entkommen ist möglich. | Konkreter Zustandsautomat/Navigation/Wahrnehmung fehlen. Vorhandenes Originalmodell/Rig/Clips verwenden und erforderliche Bewegungen ergänzen. | Echte Wände/Türen, alter Schussort nach leiser Verlagerung, Sichtverlust/Suche/Abklingen, Treffer und faire Angriffe praktisch prüfen. |
| D — Ablauf | Relais aktivieren, Ausgang erreichen, gewinnen oder sterben und neu starten. | Konkrete Relais-/Ausgangs-/Neustartverknüpfung und zusammenhängende Wege. Bestehende Speicherung anbinden. | Vollständigen kleinen Ablauf tatsächlich spielen, inklusive Tod/Neustart und belastbarer Ziel-/Speicherzustände. |
| E — Laptop-Prüfung | Den zusammenhängenden5–10-Minuten-Abschnitt auf diesem Laptop spielen und verbessern. | Bedienbare Leistung, Lesbarkeit und konkrete Gameplayfehler prüfen. Kein separates Framework voraussetzen. | Bauen → starten → Aktionen → Ergebnis ansehen → Fehler korrigieren → gezielt erneut prüfen; unabhängiger Prüfer bewertet das zusammenhängende Paket. |

## Architektur- und Prüfregeln ab jetzt

Listener zunächst: Roaming, Untersuchen, Verfolgen, Suchen, Angreifen, Taumeln, Rückzug. Godot-Navigation und echte Sichtprüfungen; Erinnerung an letzte glaubwürdige Sicht-/Geräuschposition, Zeitpunkt und abnehmende Sicherheit. Geräusche berücksichtigen die vorhandenen Räume/Türen, nicht eine hypothetische vollständige Kampagne. Kein Wandsichtzugriff, verborgenes Dauertracking, Teleport zum Spieler oder Angriff durch Hindernisse. Ohne neue Hinweise endet die Suche. Beobachten/Anschleichen/Pacing werden danach ergänzt.

Keine neue allgemeine Service-, Adapter-, Provider-, Registry- oder Plugin-Schicht ohne aktuellen nachgewiesenen Bedarf. Vorhandene Zeit-/Restore-Verträge dürfen direkt genutzt werden; zusätzliche universelle Infrastruktur ist keine Eintrittsbedingung für A. Die alten M3/M6-Schnittstellenpläne sind historische Empfehlungen, keine Sperre vor dem nächsten spielbaren Schritt.

Neue Tests konzentrieren sich auf Absturz, Softlock, Munition, Speicherschäden, Steuerung und unfairen Monsterzugriff. Bestehende sinnvolle Tests bleiben. Kein neues Testframework außer bei einem reproduzierten Problem, das eine jetzt notwendige Prüfung verhindert. Nicht verfügbare Audio-/Plattformprüfung bleibt offen, blockiert aber unabhängige Gameplay-Arbeit nicht automatisch. Keine erfundenen Erlebnisse, Ergebnisse, Fertigstellungsprozente oder Kontingentversprechen.

Root bleibt Orchestrator; Implementierung ausschließlich Astra/max in isolierten Worktrees. Normalerweise ein zusammenhängender Implementierungsauftrag plus ein unabhängiger Prüfer/Integrator; weitere Agenten nur für konkret hilfreiche parallele Arbeit. Die vorhandene Kapazität ist eine Obergrenze, kein Auslastungsziel. Keine konkurrierenden Dateibesitzer. Kandidaten dürfen in einer isolierten Abschnitts-Worktree zusammengeführt werden, bevor alle früher vorgesehenen Einzel-Meilensteinprüfungen abgeschlossen sind; das ist keine Abnahme oder Main-Freigabe. Unabhängige Prüfung und sequenzielle Integration gelten für den zusammenhängenden spielbaren Block. Main wird erst nach dessen tatsächlichem Lauf/gezielter Prüfung gefördert.

Berichtsform: „Du kannst jetzt X spielen; Y fehlt noch.“ Solange nichts Entsprechendes tatsächlich funktioniert, ausdrücklich sagen, dass es noch nicht spielbar ist. Wenn ein Block nur Infrastruktur hervorbringt, den konkreten Blocker benennen und den Ansatz ändern.

## Gesicherter Ausgangsstand

Main0873180 enthält noch keine integrierte Spielszene. M0Quelle9bdcfc3/Nachweisb647a1e ist unabhängig cef92e4 angenommen. NativeQuellefb3a09d/Nachweis5389c4c ist unabhängig2f10706 angenommen. Kernquelle891344e/Nachweis7923b80 hat unabhängige Speicher-/Zeit-/Restore-Prüfungen und33 tatsächlich geöffnete native Selbstprüfbilder; die alte separate Gesamt-M2-Prüfung ist nicht abgeschlossen. Raumquellee70fec5 enthält Importe01fdb0; Material-/Leistungsqualität ist weiter offen. Listener3b67be9 enthält Originalquelle/Rig und3Clips, keine vollständige Kreaturenabnahme.

Beim Strategieeingang meldeten drei Agenten Kontingentfehler und das Goal `usageLimited`; die anschließende direkte Kontingentabfrage meldet1% verwendet und keine aktive Sperrmarkierung. Das ist widersprüchliche Laufzeitinformation, keine Verfügbarkeitsgarantie. Kein Kauf, Reset oder Modellwechsel wurde vorgenommen. Root stoppte ausschließlich die eindeutig agenteneigene, unbeaufsichtigt gebliebene Vorschau `native-m4-03` über das vorhandene Werkzeug: `cleanup_errors=[]`, globale Audioeinstellungen unverändert. Vorhandene uncommittete Belege bleiben erhalten; diese unterbrochene Vorschau ist kein bestandener Material-/Leistungstest.
