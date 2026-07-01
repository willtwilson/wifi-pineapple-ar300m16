# USB Wi-Fi adapter chipset compatibility

Source: [WiFi-Mangoapple-Resources](https://github.com/SHUR1K-N/WiFi-Mangoapple-Resources#chipsets)
plus community issue reports.

The AR300M16 has **one internal radio** (QCA9531 / ath9k, 2.4 GHz only). The Pineapple
firmware wants **≥2 radios** (management AP + PineAP pool), **3 recommended** for full
functionality. The external adapter(s) plug into the USB 2.0 port — use a hub if you
also need a USB flash drive for `/sd` module storage.

## Supported — 2.4 GHz only
| Chipset | Notes |
|---------|-------|
| RT5370  | **Best choice.** Cheap, widely available, personally confirmed by SHUR1K-N. |
| RT3070  | Confirmed in comments. |
| RT3071 / RT3072 / RT3370 | |
| RT2070 / RT2400 / RT2500 / RT2570 / RT2671 / RT2770 / RT2870 | |
| MT7603E/EN, MT7620A/N, MT7621, MT7622, MT7628 | |
| RTL8187L/B | Legacy, supported. |

## Supported — dual band (2.4 + 5 GHz)
| Chipset | Notes |
|---------|-------|
| RT5572  | **Best dual-band choice.** Personally confirmed by SHUR1K-N + others. |
| RT3572  | Confirmed via repo Issues. |
| MT7610U, MT7632U, MT7613, MT7662U/E, MT7915 | |
| MT7612U | **Avoid** unless you can mode-switch it — adapters often present as emulated
            storage (`lsusb` shows `0e8d:2870`). See troubleshooting.md. |

## Confirmed NOT supported
| Chipset | Reason |
|---------|--------|
| AR9271  | Classic Alfa AWUS036NHA chipset — but broken under WPC. |
| RTL8811AU / RTL8811CU | Realtek 8812/8814 family — no driver in the WPC image. |
| MT7601U | Common cheap adapter; no driver. |
| MT7610   | |
| MT7921AUN | |

## Sourcing (non-affiliate, per SHUR1K-N)
* **RT5370 (2.4 GHz)** — search AliExpress/eBay for "RT5370 wifi adapter".
  ~USD 2-5.
* **RT5572 (dual-band)** — search AliExpress for "RT5572 dual band wifi adapter".
  ~USD 8-15.

Always verify the chipset with `lsusb` before relying on the adapter; many sellers
rebadge generic adapters with marketing names unrelated to the silicon.