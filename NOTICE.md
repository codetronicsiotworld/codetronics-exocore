This repository is a derivative work of earlephilhower/arduino-pico
(https://github.com/earlephilhower/arduino-pico), licensed under the
GNU Lesser General Public License v2.1 (see LICENSE). The core (cores/),
bundled libraries (libraries/), toolchain glue (tools/, lib/, system/),
boot2 stage-2 images (boot2/), and OTA support (ota/) are unmodified
upstream code. Modifications in this fork are limited to:

  - boards.txt: regenerated to define only Kratos, Hermes, and Vyper Pico
    (tools/make_boards.py), instead of the ~150 upstream board entries.
  - variants/kratos, variants/hermes, variants/vyper_pico: new variant
    folders (pin mapping currently mirrors stock Pico/Pico 2 -- see README).
  - platform.txt: cosmetic rebrand (name/version) + release-mode tool
    path substitution (same transform upstream's own release CI applies).
  - package/: Boards Manager index template + release workflow, scoped to
    this fork's GitHub repo instead of earlephilhower's.

All upstream copyright notices are retained in LICENSE.
