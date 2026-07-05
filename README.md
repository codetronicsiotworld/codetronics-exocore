# Kratos / Hermes / Vyper Pico — Arduino Board Package

A derivative of [earlephilhower/arduino-pico](https://github.com/earlephilhower/arduino-pico),
trimmed to exactly three boards and locked down so the only exposed build
option is CPU frequency. Everything else (MCU, boot stage 2, flash layout,
optimization level) is hardcoded per board — there is nothing to misconfigure.

## Boards

| Property        | Kratos                  | Hermes                          | Vyper Pico               |
|-----------------|--------------------------|----------------------------------|---------------------------|
| MCU             | RP2040 (Cortex-M0+)      | RP2350 (Cortex-M33, ARM mode)    | RP2040 (Cortex-M0+)      |
| Boot Stage 2    | W25Q16JVxQ QSPI/4        | **N/A — see note below**        | W25Q16JVxQ QSPI/4        |
| Flash           | 2MB (1MB sketch / 1MB FS)| 2MB (1MB sketch / 1MB FS)       | 2MB (1MB sketch / 1MB FS)|
| Optimize        | -O3 (fixed)              | -O3 (fixed)                     | -O3 (fixed)               |
| CPU Speed       | 100MHz default, adjustable 50–200MHz | 100MHz default, adjustable 50–150MHz | 100MHz default, adjustable 50–200MHz |
| Overclock       | Not exposed (no menu entries exist above rated max) | Not exposed | Not exposed |
| Upload method   | UF2 (BOOTSEL drag-and-drop), fixed | UF2, fixed | UF2, fixed |
| Pinout          | Mirrors stock Raspberry Pi Pico | Mirrors stock Raspberry Pi Pico 2 | Mirrors stock Raspberry Pi Pico |

Every other Tools-menu item (Debug Port/Level, RTTI, Exceptions, Stack
Protector, Profiling, USB Stack, OS) is fixed to arduino-pico's stock default
and is **not** shown in the IDE menu — "not adjustable" is enforced
structurally, not just by convention.

## Technical correction: Hermes boot2

Your spec listed "W25Q16JVxQ QSPI/4" as Hermes's boot stage 2. That's not
applicable to RP2350 silicon: RP2350's boot ROM reads flash configuration
directly (via its own flash-parameter block) and does not execute a copied
"boot2" stage the way RP2040 does. Every RP2350 board in upstream
arduino-pico (including the official Pico 2) sets `build.boot2=none` for
this reason. Hermes's `boards.txt` entry has been generated with
`boot2=none` — this is correct behavior, not an omission.

## Technical note: USB VID

Boards reuse Raspberry Pi Foundation's registered USB VID (`0x2e8a`) with
distinct PIDs, which is what nearly every RP2040/RP2350 clone board does —
it's free and functionally harmless for prototyping/competition use.
If Kratos/Hermes/Vyper Pico ever ship as a retail product, get a real VID
(USB-IF, ~$6000) or register a free PID under the shared
[pid.codes](https://pid.codes) VID (`0x1209`) instead. Swap the `VID`/`pid`
values in `tools/make_boards.py` and regenerate `boards.txt`.

## Pin mapping

All three boards currently mirror the stock Raspberry Pi Pico (RP2040) /
Pico 2 (RP2350) pinout exactly — see `variants/kratos/pins_arduino.h`,
`variants/hermes/pins_arduino.h`, `variants/vyper_pico/pins_arduino.h`.
Each file has a `TODO` marking where to correct pins once your actual PCB
pinout (LED GPIO, default SPI/I2C/UART routing, ADC-capable pins, etc.)
diverges from stock Pico/Pico 2.

## Repository layout

```
boards.txt              <- generated, do not hand-edit (see tools/make_boards.py)
platform.txt            <- build recipes, rebranded, release-mode tool paths
tools/make_boards.py    <- regenerate boards.txt from here
variants/kratos/        <- Kratos pinout
variants/hermes/        <- Hermes pinout
variants/vyper_pico/    <- Vyper Pico pinout
variants/generic/       <- shared by RP2040 variants (upstream dependency)
variants/generic_rp2350/<- shared by RP2350 variants (upstream dependency)
cores/, lib/, libraries/, boot2/, ota/, include/, system/, tools/
                         <- unmodified upstream arduino-pico core/toolchain glue
pico-sdk/, ArduinoCore-API/, FreeRTOS-Kernel/
                         <- git submodules (populated by --recurse-submodules)
package/package_kratos_hermes_vyper_index.template.json
                         <- Boards Manager index template, filled in by CI
.github/workflows/release.yml
                         <- builds + publishes a release on every `git tag vX.Y.Z push`
```

## One-time setup (you do this once)

1. Create a new **public** GitHub repository (Boards Manager needs to fetch
   a public URL — private repos won't work without extra auth plumbing).
2. Inside this folder:
   ```bash
   git init
   git remote add origin https://github.com/<you>/<repo>.git
   git add -A
   git commit -m "Initial Kratos/Hermes/Vyper Pico board package"
   git branch -M main
   git push -u origin main
   ```
3. Edit `package/package_kratos_hermes_vyper_index.template.json`: replace
   `YOUR_GITHUB_USERNAME` and the repo name placeholders with your real
   values (or just re-run `python3 tools/... ` — see `tools/make_boards.py`
   comments — whichever you find easier). Commit and push that change.

## Cutting a release (this is your "one click" moment)

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions (`.github/workflows/release.yml`) then automatically:
1. Checks out the repo **with submodules** (pulls actual pico-sdk source,
   not just the pointer).
2. Zips everything needed to compile into a release archive.
3. Computes its SHA-256 + size.
4. Publishes a GitHub Release with that zip attached.
5. Fills in `package_kratos_hermes_vyper_index.json` (URL, checksum, size)
   and commits it to `main`, so the Boards Manager URL never changes across
   versions.

Typical CI run: a couple of minutes (no compiler build — you're reusing
earlephilhower's prebuilt `pico-quick-toolchain` releases directly, not
rebuilding GCC).

## Installing in Arduino IDE (what your day-to-day workflow looks like)

1. File → Preferences → **Additional Boards Manager URLs**, add:
   ```
   https://raw.githubusercontent.com/<you>/<repo>/main/package_kratos_hermes_vyper_index.json
   ```
2. Tools → Board → Boards Manager → search "Kratos" → Install.
3. Tools → Board → select **Kratos**, **Hermes**, or **Vyper Pico**.
4. Tools → CPU Speed → pick anything from 50MHz up to the rated max
   (200MHz RP2040 / 150MHz RP2350). Nothing above that exists in the menu.
5. Plug in over USB (hold BOOTSEL if it's the board's first-ever flash),
   hit Upload. Done — no manual boot2/flash-size/optimize configuration,
   ever.

Updating later: bump the version, `git tag vX.Y.Z && git push origin vX.Y.Z`,
and Arduino IDE's Boards Manager will offer the update automatically (same
URL, same install flow).

## Failure modes / known limitations

- **First release only, no multi-version history yet**: the release
  workflow merges against whatever `package_kratos_hermes_vyper_index.json`
  already exists on `main`, so version history accumulates correctly from
  your second release onward. Nothing to do here, just noting it.
- **Pin mapping is a placeholder** until you replace the `TODO`s in the
  three `pins_arduino.h` files with your real schematic. Compiling now will
  succeed and behave exactly like a stock Pico/Pico 2 — which is only
  correct if your GPIO routing actually matches stock.
- **VID/PID reuse** (see above) is fine for internal/competition use, not
  for retail distribution.
- **Public repo requirement**: if you need this private, you'll need to
  either self-host the index JSON + zip somewhere reachable (e.g. your own
  webserver, or a private GitHub Pages-style setup with a token), since
  Arduino Boards Manager does a plain unauthenticated HTTP GET.
- **RP2350 arch is locked to ARM Cortex-M33.** RP2350 also supports a
  RISC-V (Hazard3) build target; it's intentionally not exposed since it
  wasn't in your spec and "everything not mentioned is fixed to default."
  Trivial to add back as a menu in `tools/make_boards.py` if you ever want
  it.

Confidence: boards.txt/platform.txt structure and property resolution
verified directly against the upstream generator (`tools/makeboards.py`)
and the actual generated entries for the official Raspberry Pi Pico /
Pico 2 boards — this is not a guess at the file format. Unverified:
whether your actual PCBs' pinouts, and their real VID/PID choices, match
what's currently checked in (placeholders, by design, per your answer to
skip custom pin mapping for now).
