# Supreme DH V5 Öhlins demo ranges

Checked 2026-09-13. Applies to the DH38 m.1 Air / TTX22m.2 Coil edition:
https://www.commencal.com/us/en/bikes/bikes/downhill/supreme%20dh%20v5/BT3SUPV5OH3.html

DH38 m.1 200 mm: COMMENCAL lists 15 clicks LSC, 3 clicks HSC and 15 clicks rebound for its supplied fork. Use 0–15, 0–3 and 0–15 respectively, counting out from closed. The generic Öhlins product pages list differing numbers; this demo follows the bike manufacturer's specific fork listing:
https://www.commencal.com/us/en/%C3%B6hlins-dh38-air-ttx18-200mm-29/A21FRKOHLDH38-29.html

TTX22m.2: 0–16 LSC and nominal 0–7 rebound according to Öhlins' feature list. The same page's structured data lists 6 for rebound, while its feature text says 7. The owner's manual also notes temperature-dependent variation in rebound clicks; this is an editable nominal demo range, not a guarantee for every individual damper.
https://www.ohlins.com/en-us/mountain-bike/rear-shocks/ttx22m-2-coil-250x75-am

The linked TTX22m.2 owner's manual, page 9, labels HSC positions I, II, III: stored as 1–3, not 0–3 clicks. Reference-point labels remain hidden as requested. The demo values are illustrative, not manufacturer-recommended rider settings.

No arbitrary ranges are added for air pressure, ramp-up pressure, spring rate, preload or tires. Those need separate specifications/units and are not click adjusters. New demos hide shock air pressure, tokens and HBO because this coil shock has no corresponding external adjusters. Existing saved component visibility and setup values are preserved.

Existing demo bike (id 3, Commencal Supreme V5) receives missing bike ranges once on load. Existing ranges, including explicit null removals, take precedence; setup overrides are preserved. A migration marker prevents removed defaults from reappearing on later launches.
