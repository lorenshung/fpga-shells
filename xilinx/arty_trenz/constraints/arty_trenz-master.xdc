# Catalog of carrier-side pins for Trenz TE0705_REV04 + TE0713_REV03
# (SoM: XC7A100T-2FGG484C).
#
# Authoritative pin map: reference/trenz board pinout.,.. again... why - CONN Pin Table.csv
#
# Active pin constraints are auto-generated from the Scala shell into
# <top>.shell.xdc. See:
#   fpga-shells/src/main/scala/shell/xilinx/ArtyTrenzShell.scala (clock/reset/MIG)
#   fpga/src/main/scala/arty_trenz/HarnessBinders.scala         (UART/JTAG/SerialTL)
#
# Pins below are commented out by default. Uncomment + rename {port_name}
# to your top-level RTL port name to wire them up.
#
# DO NOT duplicate ports that the Scala shell already constrains — Vivado
# will accept the redundant property but the placement constraints will
# collide if a port is assigned to two different package pins.

# ============================================================================
# Defensive: belt-and-suspenders PULLUP on JTAG inputs
# ============================================================================
# The shell already emits these via xdc.addPullup. Repeating here is harmless
# and tests whether Vivado 2024.2 treats a port-level PULLUP from a separate
# XDC differently during write_bitstream. If JTAG starts working after adding
# these and didn't before, the constraint-source-file matters.
set_property PULLUP TRUE [get_ports jtag_TCK]
set_property PULLUP TRUE [get_ports jtag_TMS]
set_property PULLUP TRUE [get_ports jtag_TDI]

# ============================================================================
# J11 — 40-pin user header
# ============================================================================
# Power: J11-1, J11-2 = VIOTB (set to 3.3V by J21 jumper bridging pins 1-2)
# GND:   J11-3, J11-4 (plus more)
# Bank:  16 for pins 5-18, 13 for 19-22, 15 for 23-40
#
# *** Pins J11-5..8 are JTAG (shell), J11-9..17 are SerialTL when the         ***
# *** BringupArtyTrenzConfig harness is active. Don't enable below for those. ***
#
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { j11_5  }] ;# IOA0  shell:jtag_TCK         B16_L1_P
#set_property -dict { PACKAGE_PIN D21   IOSTANDARD LVCMOS33 } [get_ports { j11_6  }] ;# IOA1  shell:jtag_TMS         B16_L23_N
#set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { j11_7  }] ;# IOA2  shell:jtag_TDI         B16_L6_P
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { j11_8  }] ;# IOA3  shell:jtag_TDO         B16_L2_P
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { j11_9  }] ;# IOA4  shell:serial_tl in.ready B16_L10_P
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { j11_10 }] ;# IOA5  shell:serial_tl out.phit[0] B16_L10_N
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports { j11_11 }] ;# IOA6  shell:serial_tl out.phit[1] B16_L9_P
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { j11_12 }] ;# IOA7  shell:serial_tl out.phit[2] B16_L9_N
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { j11_13 }] ;# IOA8  shell:serial_tl out.phit[3] B16_L17_P
#set_property -dict { PACKAGE_PIN A19   IOSTANDARD LVCMOS33 } [get_ports { j11_14 }] ;# IOA9  shell:serial_tl in.phit[0]  B16_L17_N
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { j11_15 }] ;# IOA10 shell:serial_tl in.phit[1]  B16_L16_N
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { j11_16 }] ;# IOA11 shell:serial_tl in.phit[2]  B16_L16_P
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { j11_17 }] ;# IOA12 shell:serial_tl in.phit[3]  B16_L15_P
#set_property -dict { PACKAGE_PIN E21   IOSTANDARD LVCMOS33 } [get_ports { j11_18 }] ;# IOA13                            B16_L23_P
#set_property -dict { PACKAGE_PIN AB16  IOSTANDARD LVCMOS33 } [get_ports { j11_19 }] ;# IOA14                            B13_L2_P
#set_property -dict { PACKAGE_PIN AA15  IOSTANDARD LVCMOS33 } [get_ports { j11_20 }] ;# IOA15                            B13_L4_P
#set_property -dict { PACKAGE_PIN AB12  IOSTANDARD LVCMOS33 } [get_ports { j11_21 }] ;# IOA16                            B13_L7_N
#set_property -dict { PACKAGE_PIN AB10  IOSTANDARD LVCMOS33 } [get_ports { j11_22 }] ;# IOA17                            B13_L8_N
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { j11_23 }] ;# IOA18                            B15_L19_N
#set_property -dict { PACKAGE_PIN J20   IOSTANDARD LVCMOS33 } [get_ports { j11_24 }] ;# IOA19                            B15_L11_P
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { j11_25 }] ;# IOA20                            B15_L17_P
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { j11_26 }] ;# IOA21                            B15_L16_P
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33 } [get_ports { j11_27 }] ;# IOA22                            B15_L17_N
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { j11_28 }] ;# IOA23                            B15_L1_N
#set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { j11_29 }] ;# IOA24                            B15_L19_P
#set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS33 } [get_ports { j11_30 }] ;# IOA25                            B15_L11_N
#set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { j11_31 }] ;# IOA26                            B15_IO25
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { j11_32 }] ;# IOA27                            B15_L22_N
#set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { j11_33 }] ;# IOA28                            B15_L21_N
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { j11_34 }] ;# IOA29                            B15_L21_P
#set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33 } [get_ports { j11_35 }] ;# IOA30                            B15_L6_N
#set_property -dict { PACKAGE_PIN M22   IOSTANDARD LVCMOS33 } [get_ports { j11_36 }] ;# IOA31                            B15_L15_N
#set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { j11_37 }] ;# IOA32                            B15_L18_N
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { j11_38 }] ;# IOA33                            B15_L20_P
#set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS33 } [get_ports { j11_39 }] ;# IOA34                            B15_L10_N
#set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS33 } [get_ports { j11_40 }] ;# IOA35                            B15_L10_P

# ============================================================================
# J13 — second 40-pin user header
# ============================================================================
# Power: J13-1, J13-2 = VIOTB (3.3V)
# GND:   J13-3, J13-4
# Bank:  16 for pins 5-21, mixed 13/15 for higher pins
#
#set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33 } [get_ports { j13_5  }] ;# IOB0  B16_L4_N
#set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33 } [get_ports { j13_6  }] ;# IOB1  B16_L4_P
#set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { j13_7  }] ;# IOB2  B16_L3_N
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { j13_8  }] ;# IOB3  B16_L2_N
#set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { j13_9  }] ;# IOB4  B16_L5_P
#set_property -dict { PACKAGE_PIN D16   IOSTANDARD LVCMOS33 } [get_ports { j13_10 }] ;# IOB5  B16_L5_N
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports { j13_11 }] ;# IOB6  B16_L7_P
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { j13_12 }] ;# IOB7  B16_L7_N
#set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { j13_13 }] ;# IOB8  B16_L18_P
#set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { j13_14 }] ;# IOB9  B16_L18_N
#set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { j13_15 }] ;# IOB10 B16_L19_P
#set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33 } [get_ports { j13_16 }] ;# IOB11 B16_L19_N
#set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVCMOS33 } [get_ports { j13_17 }] ;# IOB12 B16_L21_N
#set_property -dict { PACKAGE_PIN B21   IOSTANDARD LVCMOS33 } [get_ports { j13_18 }] ;# IOB13 B16_L21_P
#set_property -dict { PACKAGE_PIN B22   IOSTANDARD LVCMOS33 } [get_ports { j13_19 }] ;# IOB14 B16_L20_N
#set_property -dict { PACKAGE_PIN C22   IOSTANDARD LVCMOS33 } [get_ports { j13_20 }] ;# IOB15 B16_L20_P
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { j13_21 }] ;# IOB16 B16_L15_N
#set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS33 } [get_ports { j13_22 }] ;# IOB17 B13_L2_N
#set_property -dict { PACKAGE_PIN AB15  IOSTANDARD LVCMOS33 } [get_ports { j13_23 }] ;# IOB18 B13_L4_N
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { j13_24 }] ;# IOB19 B15_L23_N
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { j13_25 }] ;# IOB20 B15_L16_N
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { j13_26 }] ;# IOB21 B15_L3_P
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { j13_27 }] ;# IOB22 B15_L3_N
#set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { j13_28 }] ;# IOB23 B15_L1_P
#set_property -dict { PACKAGE_PIN AA9   IOSTANDARD LVCMOS33 } [get_ports { j13_29 }] ;# IOB24 B13_L8_P
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { j13_30 }] ;# IOB25 B15_L23_P
#set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33 } [get_ports { j13_31 }] ;# IOB26 B15_L8_N
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { j13_32 }] ;# IOB27 B15_L22_P
#set_property -dict { PACKAGE_PIN AB11  IOSTANDARD LVCMOS33 } [get_ports { j13_33 }] ;# IOB28 B13_L7_P
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { j13_34 }] ;# IOB29 B15_L24_N
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { j13_35 }] ;# IOB30 B15_L6_P
#set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVCMOS33 } [get_ports { j13_36 }] ;# IOB31 B15_L15_P

# ============================================================================
# J5 — 8-pin user Pmod ** WARNING: ROUTED THROUGH LEVEL TRANSLATOR D16/D17 **
# ============================================================================
# J5-1..4 pass through carrier IC D16 + series pack R49 before reaching the
# header. J5-5..8 pass through D17 + R37. The translators need OE/direction
# control on the carrier; without it the J5-side floats regardless of what
# the FPGA pin does. Prefer J11/J13 for new uses.
#
#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { j5_1 }] ;# PA0_P (via R49->D16) B13_L14_N
#set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { j5_2 }] ;# PA1_P (via R49->D16) B13_L13_N
#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { j5_3 }] ;# PA0_N (via R49->D16) B13_L14_P
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { j5_4 }] ;# PA1_N (via R49->D16) B13_L13_P
#set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS33 } [get_ports { j5_5 }] ;# PA3_P (via R37->D17) B13_L12_P
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { j5_6 }] ;# PA2_P (via R37->D17) B13_L11_P
#set_property -dict { PACKAGE_PIN W12   IOSTANDARD LVCMOS33 } [get_ports { j5_7 }] ;# PA3_N (via R37->D17) B13_L12_N
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { j5_8 }] ;# PA2_N (via R37->D17) B13_L11_N

# ============================================================================
# J6 — 8-pin user Pmod ** WARNING: ROUTED THROUGH LEVEL TRANSLATOR D19/D21 **
# ============================================================================
# Same level-translator caveat as J5. J6-1..4 via D19/R38, J6-5..8 via D21/R50.
#
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { j6_1 }] ;# PB3_N (via R38->D19) B15_L13_N
#set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { j6_2 }] ;# PB2_N (via R38->D19) B15_L14_P
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { j6_3 }] ;# PB3_P (via R38->D19) B15_L13_P
#set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { j6_4 }] ;# PB2_P (via R38->D19) B15_L14_N
#set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS33 } [get_ports { j6_5 }] ;# PB1_N (via R50->D21) B15_L7_P
#set_property -dict { PACKAGE_PIN K21   IOSTANDARD LVCMOS33 } [get_ports { j6_6 }] ;# PB0_N (via R50->D21) B15_L9_P
#set_property -dict { PACKAGE_PIN H22   IOSTANDARD LVCMOS33 } [get_ports { j6_7 }] ;# PB1_P (via R50->D21) B15_L7_N
#set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS33 } [get_ports { j6_8 }] ;# PB0_P (via R50->D21) B15_L9_N

# ============================================================================
# J2 — 6-pin user Pmod (bank 14, DIRECT connection — no level translator)
# ============================================================================
# J2-5, J2-6 (IOC6, IOC7) route directly to the USB controller, not the FPGA.
# Only J2-7..12 are FPGA-routable.
#
#set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33 } [get_ports { j2_7  }] ;# IOC4 B14_L15_P
#set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { j2_8  }] ;# IOC5 B14_L15_N
#set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33 } [get_ports { j2_9  }] ;# IOC2 B14_L17_P
#set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { j2_10 }] ;# IOC3 B14_L17_N
#set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { j2_11 }] ;# IOC0 B14_L16_N
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { j2_12 }] ;# IOC1 B14_L16_P

# ============================================================================
# Gigabit Ethernet (J14 RJ45, magnetics-to-MDIO0..3 pairs)
# ============================================================================
# This is the direct MDI (PHY-to-magnetics) interface, not RGMII.
# Suitable for a soft Ethernet MAC that handles 1000BASE-T PCS itself.
#
#set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi0_p }] ;# B13_L16_P  J14-2
#set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi0_n }] ;# B13_L16_N  J14-3
#set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi1_p }] ;# B13_L17_P  J14-4
#set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi1_n }] ;# B13_L17_N  J14-5
#set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi2_p }] ;# B13_L6_N   J14-6
#set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi2_n }] ;# B13_L6_P   J14-7
#set_property -dict { PACKAGE_PIN AA14  IOSTANDARD LVCMOS33 } [get_ports { eth_mdi3_p }] ;# B13_L5_N   J14-8
#set_property -dict { PACKAGE_PIN Y13   IOSTANDARD LVCMOS33 } [get_ports { eth_mdi3_n }] ;# B13_L5_P   J14-9

# ============================================================================
# microSD slot (U2 socket, 4-bit SDIO + CMD + CLK)
# ============================================================================
#set_property -dict { PACKAGE_PIN AA10  IOSTANDARD LVCMOS33 } [get_ports { sd_dat0 }] ;# B13_L9_P   U2-6
#set_property -dict { PACKAGE_PIN AA11  IOSTANDARD LVCMOS33 } [get_ports { sd_dat1 }] ;# B13_L9_N   U2-7
#set_property -dict { PACKAGE_PIN AB13  IOSTANDARD LVCMOS33 } [get_ports { sd_dat2 }] ;# B13_L3_N   U2-1
#set_property -dict { PACKAGE_PIN AA13  IOSTANDARD LVCMOS33 } [get_ports { sd_dat3 }] ;# B13_L3_P   U2-3
#set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { sd_cmd  }] ;# B13_L10_P  U2-4
#set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS33 } [get_ports { sd_clk  }] ;# B13_L10_N  R44-1
