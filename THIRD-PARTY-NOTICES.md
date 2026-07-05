# Third-Party License Inventory

This package bundles code from multiple upstream projects. Licenses are NOT
uniform across the tree -- do not assume "the whole repo is LGPL 2.1."
Confidence levels below reflect what was actually read in this repo vs.
general public knowledge that was not re-verified this session.

## Verified directly (license file read in this repo)

| Component | Path | License |
|---|---|---|
| arduino-pico core (cores/, boards.txt/platform.txt machinery, most of libraries/) | root `LICENSE` | LGPL **2.1** or later |
| HID_Keyboard / HID_Mouse / HID_Joystick (earlephilhower forks) | `libraries/Keyboard`, `libraries/Mouse`, `libraries/HID_Joystick`, `libraries/KeyboardBLE`, `libraries/KeyboardBT`, etc. | LGPL **v3** (different version than the core -- has anti-tivoization / "Installation Information" clause for consumer devices) |
| http-parser | `libraries/http-parser` | MIT (`LICENSE-MIT`) |

## Not re-verified this session (well-established public licenses, confirm before shipping)

| Component | Expected license | Why it matters |
|---|---|---|
| pico-sdk (Raspberry Pi) | BSD-3-Clause | Permissive, minimal obligation (keep notice) |
| FreeRTOS-Kernel (earlephilhower fork) | MIT | Permissive |
| Adafruit_TinyUSB_Arduino | MIT | Permissive |
| SdFat (greiman) | MIT | Permissive |
| littlefs (littlefs-project) | BSD-3-Clause | Permissive |
| pyserial | BSD-3-Clause | Permissive (build-time tool only, not shipped in firmware) |
| ArduinoCore-API (earlephilhower fork) | LGPL 2.1 | Same family as core |
| bearssl-esp8266, tlsf, uzlib, ESPHost, SPIFTL, AsyncUDP, MIDIUSB | Various (MIT/BSD/LGPL, per earlephilhower's usual convention) | Confirm per-repo before commercial ship |

**Action item before shipping any physical product or binary release:** run a
real license scanner (e.g. `pip install licensecheck`, `scancode-toolkit`, or
GitHub's dependency graph/license detection on the pushed repo) against the
fully checked-out tree (`git submodule update --init --recursive` first --
this inventory was built without submodule contents fetched, since this
sandbox's network allowlist blocks raw file fetches from
raw.githubusercontent.com). Treat this file as a starting map, not a final
audit.
