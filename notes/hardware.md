# GL.iNet GL-AR300M16 hardware notes

## Specifications (from GL.iNet product page)
| Field | Value |
|-------|-------|
| SoC | Qualcomm Atheros QCA9531 @ 650 MHz |
| RAM | 128 MB DDR2 |
| Flash | 16 MB NOR (the "16" in AR300M**16**) |
| Wi-Fi | 802.11 b/g/n, 2.4 GHz only, up to 300 Mbps, <20 dBm TX |
| Ethernet | 1× WAN + 1× LAN, 10/100 |
| USB | 1× USB 2.0 host |
| Power | Micro USB, 5V/2A, <2 W consumption |
| Dimensions | 58 × 58 × 25 mm, 40 g |
| Operating temp | 0–40 °C |

## Variants in the AR300M family
| Model | Flash | Ethernet | Notes |
|-------|-------|----------|-------|
| GL-AR300M-Lite | 16 MB NOR | 1× WAN only | Cheapest, single port. |
| **GL-AR300M16** | 16 MB NOR | 1× WAN + 1× LAN | **This project's target.** |
| GL-AR300M16-Ext | 16 MB NOR | 1× WAN + 1× LAN | With external antennas. |
| GL-AR300M | 128 MB NAND | 1× WAN + 1× LAN | Bigger flash; different sysupgrade path. |

All variants share the QCA9531 SoC and the `glinet_gl-ar300m-lite` OpenWrt device id
for the NOR-flash models. The NAND variant (`gl-ar300m`) uses a separate sysupgrade
image — do **not** cross-flash.

## OpenWrt target
* Target: `ath79/generic`
* Subtarget device id: `glinet_gl-ar300m-lite`
* Architecture: `mips_24kc`
* Same target family as the Pineapple NANO (ath9k radio).

## Serial console (optional, for recovery / debugging)
* UART pads exposed on the PCB ( labelled `TX`, `RX`, `GND` ).
* Baudrate: **115200 8N1**.
* Useful if a flash goes wrong and LuCI/U-Boot recovery is unreachable.
* GL.iNet dev docs: <https://docs.gl-inet.com/router/en/3/dev/serial/>

## Power budget considerations
The single USB 2.0 port is rated 500 mA by spec. A typical RT5370 adapter draws
~350–450 mA peak — borderline on its own. If you also need a USB flash drive,
**use a powered USB hub** to avoid brownouts that reboot the router mid-flash.