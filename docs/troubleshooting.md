# Troubleshooting

Curated from the upstream WPC issues and the WiFi-Mangoapple-Resources wiki.

## "Status: Monitor interface won't start! Try to run airmon-ng..."

You are using a Wi-Fi adapter with an **unsupported chipset**. This is a catch-all
error; fiddling with `airmon-ng` will not fix it. Swap to a supported adapter — see
[chipset-compat.md](./chipset-compat.md).

## Can't connect to an open AP that the Pineapple is broadcasting

1. Panel → **Filters** → set both client and SSID filtering to **Deny List**.
2. Panel → **Networking → Config** → ensure **Hide Open SSID** is *unchecked*.
   (It can leak the SSID even when set, so uncheck regardless.)
3. Click **Update Access Point**.

## OpenWRT v19.07.7 not in the firmware selector

It was deprecated from the live selector. Download directly from the archive:
```
https://archive.openwrt.org/releases/19.07.7/targets/ath79/generic/
```
Fallback: use 19.07.2 (matches original Pineapple hardware) — same install steps,
but deselect "Keep settings" and select "Force upgrade".

## Handshakes not shown in the web UI

Known issue on the GL-MT300N-V2 (Mango) where captures land at `/` instead of
`/tmp/handshakes`. The AR300M-16 (Shadow) is specifically recommended as a
workaround — handshakes display correctly on this board. If you still don't see
them, SSH in and check:
```
ls -la /tmp/handshakes/
ls -la /
```

## USB flash drive not recognised / can't format

1. Verify the drive on a Windows/Linux host first.
2. Format it manually on a PC (FAT32 or ext4 default is fine).
3. Re-attach, check **Advanced → USB & Storage** in the panel, or run `lsusb` / `lsblk`
   over SSH.
4. From outside `/sd/`, run:
   ```
   wpc-tools format_sd
   ```
5. If still broken:
   ```
   opkg update
   opkg install kmod-usb-storage-uas
   wpc-tools format_sd
   ```
6. As a last resort try a different pendrive — multiple users report some drives
   simply won't enumerate on this kernel.

## No "Install to SD" button for modules

Missing dependencies. Run:
```
wpc-tools missing_packages
```

## MT7612U adapter shows up as storage (`0e8d:2870`)

The MT7612U is the most problematic supported chipset — many adapters ship in an
emulated CD-ROM/storage mode. Follow the mode-switch guide at
<https://github.com/SHUR1K-N/WiFi-Shadowapple-Resources/issues/4#issue-3398474745>
to flip it into Wi-Fi mode. If it still fails, switch to an RT5572 or RT5370.

## Panel unreachable at 172.16.42.1:1471

* Make sure you are on the Pineapple's management network (Ethernet to LAN port or
  joined to its management SSID).
* Try a hard refresh / different browser.
* SSH to `root@172.16.42.1` (password `root`) and check the lighttpd service:
  ```
  /etc/init.d/lighttpd status
  /etc/init.d/lighttpd restart
  ```
* If the panel is totally broken, re-flash the WPC universal image with
  "Do not keep settings" ticked.

## Restoring stock GL.iNet firmware

1. Hold the **reset** button while powering on; release when the middle LED stays lit
   (U-Boot recovery mode).
2. Set PC NIC to static `192.168.1.2 / 255.255.255.0`.
3. Browse to `http://192.168.1.1` — the U-Boot web recovery UI.
4. Upload stock firmware from
   <https://dl.gl-inet.com/router/ar300m16/stable>.