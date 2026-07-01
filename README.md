# WiFi Pineapple Clone — GL.iNet GL-AR300M16

A documented build procedure for converting a **GL.iNet GL-AR300M16 (Shadow)** travel
router + external USB Wi-Fi adapter into a functional **WiFi Pineapple** clone, using
the open-source **[wifi-pineapple-cloner](https://github.com/xchwarze/wifi-pineapple-cloner)**
project by xchwarze (a.k.a. "Pineapple Termidor").

> ⚠️ **Authorized use only.** This repository is documentation for a homelab build
> performed by a security researcher. The tools referenced (deauth, rogue AP, captive
> portal, PMKID capture, etc.) must only be used against networks you own or are
> explicitly authorized to test. Know your local laws (e.g. Computer Misuse Act 1990,
> CFAA, etc.) before transmitting.

---

## Hardware

### Target router
| Item | Detail |
|------|--------|
| Model | GL.iNet GL-AR300M16 (Shadow, 16 MB NOR variant) |
| SoC | Qualcomm Atheros QCA9531 @ 650 MHz |
| RAM / Flash | 128 MB DDR2 / 16 MB NOR |
| Arch | `mips_24kc` (ath79) |
| Ethernet | 1× WAN + 1× LAN (10/100) |
| USB | 1× USB 2.0 host |
| Power | Micro USB 5V/2A |
| Default LAN IP (stock) | 192.168.8.1 |
| Default Wi-Fi password | `goodlife` |

### Why this router is a good target
* Same `mips_24kc` / ath79 target family as the original Pineapple NANO hardware.
* The OpenWrt 19.07.7 firmware selector exposes the device under the
  `glinet_gl-ar300m-lite` device id — confirmed available at
  `archive.openwrt.org/releases/19.07.7/targets/ath79/generic/`.
* The [WiFi-Mangoapple-Resources](https://github.com/SHUR1K-N/WiFi-Mangoapple-Resources)
  community wiki specifically calls out the AR300M-16 as a recommended board:
  *"using a router with the mips_24kc architecture like the GL.iNet AR300M-16 (Shadow),
  handshakes are shown in the web UI"* (the GL-MT300N-V2 Mango sometimes misplaces
  captured handshakes at `/` instead of `/tmp/handshakes`).

### Additional hardware required
1. **External USB Wi-Fi adapter** — the AR300M16 only has one internal radio (ath9k).
   Pineapple firmware expects ≥2 radios (PineAP pool + management); a 3rd is recommended.
   * **2.4 GHz only** — RT5370 (cheapest, best-supported).
   * **Dual band 2.4 + 5 GHz** — RT5572 (well-supported), MT7612U (avoid — emulated
     storage mode bug, see troubleshooting).
   * Avoid: AR9271, RTL8811AU, MT7601U, MT7610, MT7921AUN (confirmed broken).
2. **USB 2.0 hub** (2+ ports) — the router has only one USB port and you may also want
   a USB flash drive for module storage.
3. **USB flash drive** (any size ≥ 512 MB) — Pineapple modules install to `/sd`, which
   must be an external drive because the 16 MB NOR cannot hold them.
4. Micro USB cable (data + power), 5V/2A PSU.

---

## Firmware artifacts

Two images are needed. Both are flashed in sequence via the OpenWrt LuCI web UI.

### 1. Base image — OpenWrt 19.07.7
The cloner project mandates OpenWrt **19.07.7** as the base; 19.07.2 is the version
the original Pineapple hardware ran and is offered as a fallback if 5 GHz Wi-Fi
drivers misbehave.

```
Base URL: https://archive.openwrt.org/releases/19.07.7/targets/ath79/generic/
File:     openwrt-19.07.7-ath79-generic-glinet_gl-ar300m-lite-squashfs-sysupgrade.bin
SHA-256:  db20f1dac46e4d15e919b97d2c5f0aa18f2bb340bfcc6cfc4b645209440b9745
```

### 2. Pineapple clone sysupgrade — WPC v4 "universal"
Hosted on the author's GitLab build repo. The `universal` flavor emulates a TETRA on
any supported hardware.

```
Repo:  https://gitlab.com/xchwarze/wifi-pineapple-cloner-builds
File:  glinet_gl-ar300m-lite-universal-sysupgrade.bin
Path:  releases/glinet_gl-ar300m-lite-universal-sysupgrade.bin
```

Use the `Get-Firmware.ps1` script in this repo to download both files with checksums.

---

## Step-by-step procedure

### Phase 0 — Prep
1. Connect the AR300M16 to your PC via the **LAN** port (or join its default SSID
   `GL-AR300M-XXX`, password `goodlife`).
2. Browse to `http://192.168.8.1` and complete the stock GL.iNet first-time setup
   (set an admin password). You do **not** need to give the router upstream internet —
   flashing works over LAN.
3. Optional but recommended: plug in your USB Wi-Fi adapter now and verify it lights
   up. You can also attach the USB hub + flash drive.

### Phase 1 — Flash OpenWrt 19.07.7
1. Download `openwrt-19.07.7-ath79-generic-glinet_gl-ar300m-lite-squashfs-sysupgrade.bin`.
2. In the GL.iNet admin panel: **Advanced → System → Upgrade Firmware** → upload the
   `.bin` → **tick "Force upgrade" and untick "Keep settings"** → flash.
3. Wait ~2 minutes for the reboot. The router will come up as a plain OpenWrt device.
4. Re-connect: the LAN IP is now **192.168.1.1** (OpenWrt default). DHCP should hand
   you a 192.168.1.x address. Browse to `http://192.168.1.1`.
   * If LuCI is not installed on the sysupgrade image, use the `initramfs` image first
     (`glinet_gl-ar300m-lite-initramfs-kernel.bin`) to boot, then sysupgrade to the
     squashfs image. In practice the squashfs-sysupgrade image for the AR300M-Lite
     ships with LuCI.

### Phase 2 — Flash the Pineapple clone image
1. Download `glinet_gl-ar300m-lite-universal-sysupgrade.bin` from the GitLab builds
   repo (use `Get-Firmware.ps1`).
2. In OpenWrt LuCI: **System → Backup / Flash Firmware → Flash new firmware image**.
3. Upload the `*-universal-sysupgrade.bin` file.
4. **Tick "Do not keep settings"** — this is mandatory per the WPC install docs; a
   dirty upgrade breaks the Pineapple panel.
5. Click **Flash image**, confirm, and wait patiently for the reboot (90–180 s).

### Phase 3 — First boot of the Pineapple
1. The router now presents the Pineapple management AP. Join the open SSID it
   broadcasts (often `Pineapple` or similar) or plug in via Ethernet — the management
   interface is:
   ```
   http://172.16.42.1:1471/
   ```
2. Default SSH credentials are `root` / `root` (set a real password with `passwd`
   once you log in).
3. The Pineapple panel should load. If the *Recon* live scan or some modules are
   missing, the TETRA image had to drop dependencies to fit 16 MB NOR; on first
   internet-connected boot it auto-installs them. Manually:
   ```
   wpc-tools missing_packages
   ```
4. Format the USB flash drive as `/sd` from the panel:
   **Advanced → USB & Storage → Format SD Card**.
   * If the drive isn't recognised, see `docs/troubleshooting.md`.

### Phase 4 — Connect the external Wi-Fi adapter
1. Plug your supported USB Wi-Fi adapter (RT5370 or RT5572 recommended) into the USB
   port (use the hub if you also have a flash drive connected).
2. In the panel: **Advanced → Networking** — verify a second radio appears
   (`wlan1` / `phy1`). It should also show under **WiFi → Manage**.
3. If you see `"Status: Monitor interface won't start! Try to run airmon-ng..."`,
   your adapter's chipset is **not** supported. Swap it for an RT5370/RT5572.
4. For MT7612U adapters that show as `0e8d:2870` storage devices, follow the mode-switch
   guide linked in `docs/troubleshooting.md`.

### Phase 5 — Verify functionality
A working clone should be able to, at minimum:
* **Recon** — scan nearby APs and clients (timed scan always works; live scan needs the
  `missing_packages` step).
* **PineAP** — run the SSID pool / evil-AP functionality.
* **Handshakes** — captured PMKID / WPA handshakes appear under
  `/tmp/handshakes` *and* in the panel UI on this board (confirmed by the Mangoapple
  community specifically for the AR300M-16).
* **Modules** — install from the panel's Module Manager. Use **Install to SD** so they
  land on the USB drive; if that button is missing run `wpc-tools missing_packages`.

---

## Repository layout

```
.
├── README.md                    # this file
├── Get-Firmware.ps1             # downloads OpenWrt 19.07.7 + WPC clone image
├── docs/
│   ├── troubleshooting.md       # common errors and fixes
│   ├── chipset-compat.md        # supported / unsupported USB Wi-Fi chipsets
│   └── references.md            # upstream sources and further reading
└── notes/
    └── hardware.md              # AR300M16 specs and pinout/serial notes
```

---

## Restoring stock firmware

If you need to revert:
1. Boot the AR300M16 into **U-Boot recovery mode** (hold the reset button during
   power-on — the middle LED will light steady).
2. Set your PC to `192.168.1.2/24`, plug into the LAN port, and browse to
   `http://192.168.1.1` (the U-Boot web recovery UI).
3. Upload the stock GL.iNet image from
   [dl.gl-inet.com/router/ar300m16/stable](https://dl.gl-inet.com/router/ar300m16/stable).

---

## Acknowledgements

* **xchwarze** — author of the [wifi-pineapple-cloner](https://github.com/xchwarze/wifi-pineapple-cloner)
  project and the [Signal Forge](https://discord.gg/jmDaM5qwzY) community.
* **SHUR1K-N** — [WiFi-Mangoapple-Resources](https://github.com/SHUR1K-N/WiFi-Mangoapple-Resources)
  wiki and tutorial videos.
* **Hak5** — original WiFi Pineapple NANO/TETRA hardware and firmware. Please support
  them and buy the genuine Mk7 hardware if your budget allows.

This project is a research/homelab build and is not affiliated with Hak5.