# References & upstream sources

## Primary project
* **wifi-pineapple-cloner** (xchwarze) — <https://github.com/xchwarze/wifi-pineapple-cloner>
  * Method: minimal filesystem patch + universal TETRA-emulation sysupgrade.
  * Discord: **Signal Forge** — <https://discord.gg/jmDaM5qwzY>
  * Patreon (private test builds): <https://www.patreon.com/xchwarze>

## Prebuilt firmware images
* **wifi-pineapple-cloner-builds** (GitLab) —
  <https://gitlab.com/xchwarze/wifi-pineapple-cloner-builds>
  * AR300M-Lite image: `releases/glinet_gl-ar300m-lite-universal-sysupgrade.bin`
  * 19.07.7 (recommended) and 19.07.2 (fallback) flavours available.

## Updated panel + modules
* Panel: <https://github.com/xchwarze/wifi-pineapple-panel>
* Community packages: <https://github.com/xchwarze/wifi-pineapple-community-packages>
* Community modules: <https://github.com/xchwarze/wifi-pineapple-community/tree/main/modules>

## Companion community wiki
* **WiFi-Mangoapple-Resources** (SHUR1K-N) —
  <https://github.com/SHUR1K-N/WiFi-Mangoapple-Resources>
  * Hardware & install video: <https://youtu.be/udnxagkSzoA>
  * Upgrades / chipsets / troubleshooting video: <https://youtu.be/pHtpso21P0o>

## Base firmware (OpenWrt)
* Firmware selector: <https://firmware-selector.openwrt.org/>
* 19.07.7 ath79/generic archive:
  <https://archive.openwrt.org/releases/19.07.7/targets/ath79/generic/>
* AR300M-Lite sysupgrade:
  `openwrt-19.07.7-ath79-generic-glinet_gl-ar300m-lite-squashfs-sysupgrade.bin`
  SHA-256: `db20f1dac46e4d15e919b97d2c5f0aa18f2bb340bfcc6cfc4b645209440b9745`

## GL.iNet docs
* AR300M product page: <https://www.gl-inet.com/products/gl-ar300m/>
* Stock firmware (recovery): <https://dl.gl-inet.com/router/ar300m16/stable>
* First-time setup guide: <https://docs.gl-inet.com/router/en/3/setup/mini_router/first_time_setup/>

## Original Pineapple hardware (Hak5)
* WiFi Pineapple NANO / TETRA (EOL 2020).
* Current Mk7: <https://shop.hak5.org> — please support them if you can.

## Related tooling
* `wpc-tools` — built into the WPC image. Key subcommands:
  * `wpc-tools missing_packages` — reinstall deps dropped from the 16 MB image.
  * `wpc-tools format_sd` — format the USB pendrive as `/sd`.
  * `wpc-tools theme_install` — swap panel theme.

## Legal / ethical
This documentation is for authorised security research and homelab use only. In the
UK see the Computer Misuse Act 1990; in the US see the CFAA (18 U.S.C. §1030). Deauth
frames and rogue APs against networks you do not own or are not authorised to test are
illegal in most jurisdictions.