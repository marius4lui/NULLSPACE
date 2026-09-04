# Issues

No playable game exists; product gates remain unverified. This is not a zero-defect release.

| ID | Severity/type | State | Evidence / next action |
|---|---|---|---|
| ENV-001 | toolchain blocker | partial; export validation pending | Root executed shared portable Godot4.7.2.stable.official.ed1daf0bf and Blender5.2.1LTS. Matching template download and diagnostic cross-exports still pending; M0 not accepted. |
| ENV-002 | validation blocker | partial; corrective validation active | Root opened native-qa/fixture-dev-01/moved.png at1080p, corroborated RADV660M launch and recorded captured mouse/movement/fire. QA found obscured VSync throttle and PipeWire module cleanup mismatch; fixes/final clean proof pending. Diagnostic evidence only. |
| ENV-003 | performance evidence | open | Only integrated Radeon 660M available; cannot assert target discrete-GPU measurements. Benchmark host and seek defensible target evidence. |
| GOV-001 | configuration discrepancy | open | Root turn metadata Astra/ultra; request says max. Persistent project defaults and explicit worker max set; check supported active-turn control without pretending config retroactive. |
| IP-001 | public naming risk | documented; private production proceeds | User chose NULLSPACE; Kaigan and Domension also use that game title. No trademark/rights clearance claimed; keep user name. Sources in research I; no public storefront commitment authorized or made. |
| QA-001 | release evidence limitation | open | Actual native Windows runtime absent; cross-export/Wine alone cannot be called native certification. |
| QA-002 | experiential review limitation | open; audio modality unavailable | Root emitted actual10s fixture-stereo.ogg via supported AudioContent helper; runtime response: “audio content omitted because you do not support audio input”. No audio heard. Game-only stereo capture/metrics exist, but do not satisfy listening. Continuous temporal review also unverified; other production work continues. |
| DESIGN-001 | pre-freeze audit | resolved | Independent design audit initially failed5 findings. Root corrected docs; independent rereview PASS at c737443. Design readiness only, no game scores. |
| OPS-001 | transient worker availability | recovered, monitor | Previous bootstrap/project workers quota-failed before files/install. Resume inspection found no live workers or partial source; fresh usage0%/no reached-limit. Four replacement Astra/max workers successfully started. No reset credit or purchase used. |
| QA-003 | evidence provenance | open | Native fixture dev01 later showed extra inputs not dispatched by its supervisor. Root supplied no input. QA identifying source and establishing exclusive run ownership; unexplained inputs cannot count as controlled or independent proof. |
| M2-001 | potential P1 state/input defect, unmerged branch | correction assigned | Root inspection: complete_load enters PLAYING even after focus loss during LOADING; world unpauses but InputGate remains disabled. core_m2 must preserve pause/unfocused safety and add regression/native evidence before review. |
