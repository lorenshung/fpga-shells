##############################################################################
# arty_trenz master XDC
# --------------------------------------------------------------------------
# Custom carrier hosting a Trenz TE0712-02 SoM (XC7A100T-2FGG484C).
#
#   FPGA  <-->  SoM  (TE0712-02, REV03, fgg484)
#   SoM   <-->  B2B  (JM1/JM2/JM3 module side  ==  JB1/JB2/JB3 carrier side)
#   B2B   <-->  Carrier (TE0705, REV04)
#
# Sources of truth (in reference/):
#   pin-matching.csv               -- FPGA <-> B2B <-> carrier physical map
#   te0712-rd/constraints/*.xdc    -- SoM-internal pins (clock/reset/cfg)
#   te0712-rd/board_files/.../     -- DDR3 + RMII + QSPI canonical pins
#                                     (mig.prj, part0_pins.xml)
#
# --------------------------------------------------------------------------
# Style: Digilent-style "master" XDC.
#   - Bitstream / configuration block at the top is ACTIVE.
#   - Every signal pin below is COMMENTED OUT.
#   - To wire a signal into a top-level design:
#         1. Uncomment its set_property line.
#         2. Rename `<port_name>` to match the actual top-level Verilog port.
#
# --------------------------------------------------------------------------
# Bank power summary (jumper J21 on carrier selects VIOTB rail):
#     J21 1<->2  -> VIOTB = 3.3VOUT   (default; assumed throughout this XDC)
#     J21 2<->3  -> VIOTB = FMC_VADJ  (typically left open / variable)
#
#     VCCIOA (Bank 16) = VIOTB  -> 3.3 V  -> LVCMOS33 valid
#     VCCIOB (Bank 14) = VIOTB  -> 3.3 V  -> LVCMOS33 valid
#     VCCIOC (Bank 13) = VIOTB  -> 3.3 V  -> LVCMOS33 valid (see caveat)
#     VCCIOD (Bank 15) = VIOTB  -> 3.3 V  -> LVCMOS33 valid
#
#   CAVEAT: on a prior TE0713 + TE0705 build, VCCO_BANK_13 was measured open
#   (i.e., the B2B did NOT deliver VIOTB through to the SoM's bank-13 supply).
#   Before relying on any bank-13 pin (J2 PMod IOC0..7, USB-OTG signals,
#   on-SoM SD/Ethernet MDI lanes routed through B13 user IOs), check VCCO_B13
#   on the SoM with a multimeter.
#
# --------------------------------------------------------------------------
# Carrier connectors covered by this XDC:
#     J1   -- 2x6 PMod (overlaps with SoM MIO bus / USB-UART chip on D11/D12)
#     J2   -- 2x6 PMod (bank 13 only; see caveat)
#     J5   -- 2x6 PMod (bank 14, schematic-labelled JTAG location on pins 1-4)
#     J6   -- 2x6 PMod (bank 15)
#     J11  -- 40-pin header (banks 16/14/15)
#     J13  -- 40-pin header (banks 16/14/15)
#
# Carrier connectors intentionally NOT covered:
#     J14  -- RJ45 Ethernet jack; wired to on-SoM PHY MDI pairs, NOT to
#             FPGA bank-13 user IO. Use the RMII bus in section 4 instead.
#     J15  -- 20-pin ARM-style JTAG; routes through carrier-side buffers
#             D10/D13, not direct to FPGA pins. Not user-accessible from XDC.
#     J3/J7/J9/J12/J16  -- USB connectors / power jumpers; no FPGA wiring.
#     J8   -- microSD slot; wired to on-SoM SD bus on bank 13.
##############################################################################



##############################################################################
# 1. Bitstream / configuration
##############################################################################
# NOTE: Bitstream / config settings live in the sibling file `arty_trenz-config.xdc`
# (auto-included by the same fpga-shells glob), to keep this master XDC purely
# about pin assignments. Values there mirror te0712-rd/constraints/_i_bitgen*.xdc.



##############################################################################
# 2. SoM-internal -- System clocks
##############################################################################
# Primary user clock: K4 / J4 differential pair  (bank 35, DIFF_SSTL15)
# Period 10 ns -> 100 MHz (per te0712-rd/constraints/_i_timing.xdc).
#set_property -dict { PACKAGE_PIN K4    IOSTANDARD DIFF_SSTL15 } [get_ports { sys_clk_p }];     ;# SoM CLK0_P, B35
#set_property -dict { PACKAGE_PIN J4    IOSTANDARD DIFF_SSTL15 } [get_ports { sys_clk_n }];     ;# SoM CLK0_N, B35
#create_clock -name sys_clk -period 10.000 [get_ports sys_clk_p]

# MIG sys_clk: H4 / G4 differential pair  (bank 35, DIFF_SSTL15)
# When MIG IP is generated from board_files it owns these pins and emits its
# own constraints. Do NOT also constrain them here in that case.
#set_property -dict { PACKAGE_PIN H4    IOSTANDARD DIFF_SSTL15 } [get_ports { mig_sys_clk_p }]; ;# B35 CC pair
#set_property -dict { PACKAGE_PIN G4    IOSTANDARD DIFF_SSTL15 } [get_ports { mig_sys_clk_n }]; ;# B35 CC pair
#create_clock -name mig_sys_clk -period 5.000 [get_ports mig_sys_clk_p]                        ;# 200 MHz assumed

# Secondary single-ended clock: R4 LVCMOS15 (bank 35), 20 ns / 50 MHz.
#set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS15    } [get_ports { aux_clk }];      ;# SoM CLK1B, B35
#create_clock -name aux_clk -period 20.000 [get_ports aux_clk]



##############################################################################
# 3. SoM-internal -- Reset
##############################################################################
# Active-HIGH reset, routed from carrier SC_nRST through the SoM CPLD onto T3.
# Reference design assigns PULLDOWN to keep the line low when CPLD is high-Z.
# CAVEAT (prior trenz branch): T3 measured stuck-high on TE0705 -- if the
# fabric never leaves reset, hard-tie this to 1'b0 in the top-level wrapper
# until the carrier behaviour is understood.
#set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS15    } [get_ports { reset }];        ;# RESET, B35
#set_property PULLTYPE PULLDOWN [get_ports { reset }]



##############################################################################
# 4. SoM-internal -- QSPI configuration flash
##############################################################################
# These are the user-accessible alias pins for the on-SoM QSPI flash, as listed
# in reference/te0712-rd/board_files/.../part0_pins.xml. CCLK itself is
# accessed via STARTUPE2 and is not user-constrainable.
#set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33    } [get_ports { qspi_cs_n }];    ;# spi_ss
#set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVCMOS33    } [get_ports { qspi_dq[0] }];   ;# spi_io_0 (MOSI)
#set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33    } [get_ports { qspi_dq[1] }];   ;# spi_io_1 (MISO)
#set_property -dict { PACKAGE_PIN P21   IOSTANDARD LVCMOS33    } [get_ports { qspi_dq[2] }];   ;# spi_io_2
#set_property -dict { PACKAGE_PIN R21   IOSTANDARD LVCMOS33    } [get_ports { qspi_dq[3] }];   ;# spi_io_3



##############################################################################
# 5. SoM-internal -- RMII Ethernet (to on-SoM 10/100 PHY)
##############################################################################
# The TE0712 SoM carries its own Ethernet PHY; the FPGA talks RMII to it. The
# carrier RJ45 (J14) is wired through to the PHY's MDI pairs, NOT to user IO.
# All pins LVCMOS33 on bank 14.
#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33    } [get_ports { rmii_txd[0] }];
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33    } [get_ports { rmii_txd[1] }];
#set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33    } [get_ports { rmii_tx_en }];
#set_property -dict { PACKAGE_PIN P20   IOSTANDARD LVCMOS33    } [get_ports { rmii_crs_dv }];
#set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33    } [get_ports { rmii_rxd[0] }];
#set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33    } [get_ports { rmii_rxd[1] }];
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33    } [get_ports { phy_mdio }];
#set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33    } [get_ports { phy_mdc }];
#set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33    } [get_ports { phy_rst_n }];



##############################################################################
# 6. SoM-internal -- I2C, EEPROM, on-SoM LEDs
##############################################################################
# I2C to on-SoM PLL/clock generator.
#set_property -dict { PACKAGE_PIN W21   IOSTANDARD LVCMOS33    } [get_ports { i2c_pll_scl }];
#set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33    } [get_ports { i2c_pll_sda }];

# I2C to on-SoM CPLD (board status, MAC address proxy). NOTE: U22 / W22 are
# shared with the on-SoM "sys_led" / "led2" status LEDs in part0_pins.xml --
# pick I2C OR LEDs, not both.
#set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33    } [get_ports { i2c_cpld_scl }];
#set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33    } [get_ports { i2c_cpld_sda }];

# 1-wire EEPROM (carries the factory MAC address).
#set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVCMOS33    } [get_ports { eeprom_1wire }];

# On-SoM status LEDs (mutually exclusive with the two I2C-to-CPLD lines above).
#set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33    } [get_ports { sys_led }];
#set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33    } [get_ports { led2 }];



##############################################################################
# 7. SoM-internal -- DDR3 SDRAM                          (REFERENCE ONLY)
##############################################################################
# These pin assignments come from reference/te0712-rd/board_files/.../mig.prj.
# When the design instantiates MIG-7 with the TE0712 board file selected, the
# MIG IP emits these constraints itself -- DO NOT also place them here, or
# Vivado will flag a constraint conflict.
#
#   Memory device   : MT41J256M16XX-125  (DDR3-800, x16, 32-bit, 1 GB total)
#   MIG sys_clk     : H4 / G4   (CC, DIFF_SSTL15, bank 35)
#   TimePeriod      : 2500 ps   -> 400 MHz DDR clock (800 Mbps)
#   InputClkFreq    : 50 (interpret per MIG-prj convention; verify on regen)
#
# Pin catalogue (bank 33/34 typical, all SSTL15 / DIFF_SSTL15):
#   addr [0]=J1   [1]=P6   [2]=N5   [3]=N3   [4]=G1
#   addr [5]=M3   [6]=N2   [7]=J5   [8]=L1   [9]=P2
#   addr [10]=L4  [11]=P5  [12]=K2  [13]=M1  [14]=M5
#   ba   [0]=P4   [1]=H5   [2]=H2
#   cas_n=M2  ras_n=M6  we_n=J2  cs_n[0]=K1  cke[0]=L3  odt[0]=K3  reset_n=H3
#   ck_p [0]=R1   ck_n[0]=P1
#   dq   [0]=T1   [1]=U3   [2]=U2   [3]=U1   [4]=Y2   [5]=W1   [6]=Y1   [7]=V2
#   dq   [8]=V7   [9]=W9   [10]=AB7 [11]=AA8 [12]=AB8 [13]=AB6 [14]=Y8  [15]=Y9
#   dq   [16]=AB1 [17]=AB5 [18]=AB3 [19]=AA1 [20]=Y4  [21]=AA5 [22]=AB2 [23]=W4
#   dq   [24]=T4  [25]=U6  [26]=T6  [27]=AA6 [28]=Y6  [29]=T5  [30]=U5  [31]=R6
#   dqs_p[0]=R3   [1]=V9   [2]=Y3   [3]=W6
#   dqs_n[0]=R2   [1]=V8   [2]=AA3  [3]=W5
#   dm   [0]=W2   [1]=Y7   [2]=V4   [3]=V5



##############################################################################
# 8. Carrier J5 PMod (2x6)  --  bank 14
# --------------------------------------------------------------------------
# Routing topology:
#     FPGA  ->  R49  ->  D16  ->  J5 pins 1..4
#     FPGA  ->  R37  ->  D17  ->  J5 pins 5..8
#
# D16 / D17 are 4-channel TVS / ESD arrays in SOT-23-6 (pins 1/3/4/6 = I/O,
# pins 2/5 = GND / V). They are PASSIVE -- not level translators -- so signals
# pass through transparently. R49 / R37 are series resistor packs.
#
# Carrier silkscreen + pin-matching.csv "intermediate"/last columns label
# J5 pins 1..4 as TCK / TMS / TDI / TDO. This is the intended external-JTAG
# location (FTDI dongle on the PMod).
#
# Note: J5 pin labels "PA0_P" / "PA1_P" etc. (carrier net names) do NOT match
# the FPGA differential-pair P/N polarity in every case -- e.g. PA0_P lands on
# B14_L12_N. Trust the CSV's FPGA Pin column, not the carrier net name suffix.
#
# VCCIO: VCCIOB = VIOTB (3.3 V via J21 1<->2)  -> bank 14  -> LVCMOS33.
##############################################################################
# External JTAG (recommended use of J5-1..4)
# jtag_TCK is on W19 (IO_L12P_T1_MRCC_14, J5-3) -- a clock-capable _P pin. It was on
# W20 (IO_L12N_T1_MRCC_14, the N-side), which has no dedicated clock route -> the TAP
# never clocked -> OpenOCD "all ones". TDI (data) takes W20. Swap the cable's TCK &
# TDI leads (J5-1 <-> J5-3, both top row). Authoritative pin source: the J5 row of
# reference/pin-matching.csv and the xc7a100t_fgg484 package pin functions.
#set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 PULLTYPE PULLUP } [get_ports { jtag_TCK }]; ;# J5-3, B14_L12_P (MRCC P-side), JB2-21/JM2-22
#set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 PULLTYPE PULLUP } [get_ports { jtag_TMS }]; ;# J5-2, PA1_P, B14_L11_N, JB2-27/JM2-28
#set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 PULLTYPE PULLUP } [get_ports { jtag_TDI }]; ;# J5-1, B14_L12_N, JB2-23/JM2-24
#set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 PULLTYPE PULLUP } [get_ports { jtag_TDO }]; ;# J5-4, PA1_N, B14_L11_P, JB2-25/JM2-26
#create_clock -name jtag_TCK -period 100.000 [get_ports jtag_TCK]                                      ;# 10 MHz nominal

# Or, if J5 is used as plain GPIO instead of JTAG:
#set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33    } [get_ports { j5_1 }];           ;# PA0_P, B14_L12_N, JB2-23
#set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33    } [get_ports { j5_2 }];           ;# PA1_P, B14_L11_N, JB2-27
#set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33    } [get_ports { j5_3 }];           ;# PA0_N, B14_L12_P, JB2-21
#set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33    } [get_ports { j5_4 }];           ;# PA1_N, B14_L11_P, JB2-25

# Optional JTAG probe mirrors on J5 pins 5..8 -- output-only copies driven by
# WithArtyTrenzJTAG for probing. These are NOT alternate JTAG input pins.
#set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33    } [get_ports { jtag_probe_TCK }]; ;# J5-5, mirror of TCK
#set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33    } [get_ports { jtag_probe_TMS }]; ;# J5-6, mirror of TMS
#set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33    } [get_ports { jtag_probe_TDI }]; ;# J5-7, mirror of TDI
#set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33    } [get_ports { jtag_probe_TDO }]; ;# J5-8, mirror of TDO

# Or, if J5 pins 5..8 are used as plain GPIO instead of JTAG probes:
#set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33    } [get_ports { j5_5 }];           ;# PA3_P, B14_L14_P, JB2-22
#set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33    } [get_ports { j5_6 }];           ;# PA2_P, B14_L13_P, JB2-26
#set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33    } [get_ports { j5_7 }];           ;# PA3_N, B14_L14_N, JB2-24
#set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33    } [get_ports { j5_8 }];           ;# PA2_N, B14_L13_N, JB2-28



##############################################################################
# 9. Carrier J6 PMod (2x6)  --  bank 15
# --------------------------------------------------------------------------
# Routing topology:
#     FPGA  ->  R38  ->  D19  ->  J6 pins 1..4
#     FPGA  ->  R50  ->  D21  ->  J6 pins 5..8
# Same TVS/ESD topology as J5 (D19/D21 are passive). VCCIOD = VIOTB.
##############################################################################
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33    } [get_ports { j6_1 }];           ;# PB3_N, B15_L13_N, JB2-47
#set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33    } [get_ports { j6_2 }];           ;# PB2_N, B15_L14_P, JB2-51
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33    } [get_ports { j6_3 }];           ;# PB3_P, B15_L13_P, JB2-45
#set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33    } [get_ports { j6_4 }];           ;# PB2_P, B15_L14_N, JB2-53
#set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS33    } [get_ports { j6_5 }];           ;# PB1_N, B15_L7_P,  JB2-43
#set_property -dict { PACKAGE_PIN K21   IOSTANDARD LVCMOS33    } [get_ports { j6_6 }];           ;# PB0_N, B15_L9_P,  JB2-33
#set_property -dict { PACKAGE_PIN H22   IOSTANDARD LVCMOS33    } [get_ports { j6_7 }];           ;# PB1_P, B15_L7_N,  JB2-41
#set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS33    } [get_ports { j6_8 }];           ;# PB0_P, B15_L9_N,  JB2-31



##############################################################################
# 10. Carrier J11 40-pin header  --  banks 16 / 14 / 15
# --------------------------------------------------------------------------
# Pins 1..4 = power / ground (VIOTB / GND).
# Pins 5..18  land on bank 16  (carrier net group "IOA0..IOA13",  via JB1).
# Pins 19..22 land on bank 14  (carrier net group "IOA14..IOA17", via JB2).
# Pins 23..40 land mostly on bank 15 (group "IOA18..IOA35", via JB2).
#
# Per the CSV "intermediate" column for all J11 pins: direct B2B-to-header
# wiring (no series resistors, no buffers, no level translators).
# VCCIOA / VCCIOB / VCCIOD = VIOTB  -> LVCMOS33 valid throughout.
##############################################################################
# --- Bank 16 segment (J11-5 .. J11-18) ---
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33    } [get_ports { j11_5  }];          ;# IOA0,  B16_L1_P,  JB1-99
#set_property -dict { PACKAGE_PIN D21   IOSTANDARD LVCMOS33    } [get_ports { j11_6  }];          ;# IOA1,  B16_L23_N, JB1-44
#set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33    } [get_ports { j11_7  }];          ;# IOA2,  B16_L6_P,  JB1-87
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33    } [get_ports { j11_8  }];          ;# IOA3,  B16_L2_P,  JB1-81
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33    } [get_ports { j11_9  }];          ;# IOA4,  B16_L10_P, JB1-71
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33    } [get_ports { j11_10 }];          ;# IOA5,  B16_L10_N, JB1-69
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33    } [get_ports { j11_11 }];          ;# IOA6,  B16_L9_P,  JB1-57
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33    } [get_ports { j11_12 }];          ;# IOA7,  B16_L9_N,  JB1-55
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33    } [get_ports { j11_13 }];          ;# IOA8,  B16_L17_P, JB1-47
#set_property -dict { PACKAGE_PIN A19   IOSTANDARD LVCMOS33    } [get_ports { j11_14 }];          ;# IOA9,  B16_L17_N, JB1-45
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33    } [get_ports { j11_15 }];          ;# IOA10, B16_L16_N, JB1-37
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33    } [get_ports { j11_16 }];          ;# IOA11, B16_L16_P, JB1-35
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33    } [get_ports { j11_17 }];          ;# IOA12, B16_L15_P, JB1-46
#set_property -dict { PACKAGE_PIN E21   IOSTANDARD LVCMOS33    } [get_ports { j11_18 }];          ;# IOA13, B16_L23_P, JB1-42

# --- Bank 14 segment (J11-19 .. J11-22) ---
#set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33    } [get_ports { j11_19 }];          ;# IOA14, B14_L8_P,  JB2-14
#set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33    } [get_ports { j11_20 }];          ;# IOA15, B14_L17_N, JB2-16
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33    } [get_ports { j11_21 }];          ;# IOA16, B14_L16_P, JB2-32
#set_property -dict { PACKAGE_PIN AA19  IOSTANDARD LVCMOS33    } [get_ports { j11_22 }];          ;# IOA17, B14_L15_P, JB2-36

# --- Bank 15 segment (J11-23 .. J11-40) ---
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33    } [get_ports { j11_23 }];          ;# IOA18, B15_L19_N, JB2-48
#set_property -dict { PACKAGE_PIN J20   IOSTANDARD LVCMOS33    } [get_ports { j11_24 }];          ;# IOA19, B15_L11_P, JB2-52
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33    } [get_ports { j11_25 }];          ;# IOA20, B15_L17_P, JB2-64
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33    } [get_ports { j11_26 }];          ;# IOA21, B15_L16_P, JB2-66
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS33    } [get_ports { j11_27 }];          ;# IOA22, B15_L17_N, JB2-62
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33    } [get_ports { j11_28 }];          ;# IOA23, B15_L1_N,  JB2-74
#set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33    } [get_ports { j11_29 }];          ;# IOA24, B15_L19_P, JB2-46
#set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS33    } [get_ports { j11_30 }];          ;# IOA25, B15_L11_N, JB2-54
#set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33    } [get_ports { j11_31 }];          ;# IOA26, B15_IO25,  JB2-99
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33    } [get_ports { j11_32 }];          ;# IOA27, B15_L22_N, JB2-95
#set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33    } [get_ports { j11_33 }];          ;# IOA28, B15_L21_N, JB2-87
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33    } [get_ports { j11_34 }];          ;# IOA29, B15_L21_P, JB2-85
#set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33    } [get_ports { j11_35 }];          ;# IOA30, B15_L6_N,  JB2-81
#set_property -dict { PACKAGE_PIN M22   IOSTANDARD LVCMOS33    } [get_ports { j11_36 }];          ;# IOA31, B15_L15_N, JB2-77
#set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33    } [get_ports { j11_37 }];          ;# IOA32, B15_L18_N, JB2-67
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33    } [get_ports { j11_38 }];          ;# IOA33, B15_L20_P, JB2-71
#set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS33    } [get_ports { j11_39 }];          ;# IOA34, B15_L10_N, JB2-61
#set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS33    } [get_ports { j11_40 }];          ;# IOA35, B15_L10_P, JB2-63



##############################################################################
# 11. Carrier J13 40-pin header  --  banks 16 / 14 / 15
# --------------------------------------------------------------------------
# Pins 1..4 = power / ground.
# Pins 5..21  land on bank 16  (carrier "IOB0..IOB16",  via JB1).
# Pins 22..40 mostly on bank 15 with a few bank 14 pins mixed in (29, 33).
# Pin 22 / pin 23 specifically land on bank 14. See per-line bank tags.
# All J13 pins are direct B2B-to-header (no series R, no buffer, no TVS).
##############################################################################
# --- Bank 16 segment (J13-5 .. J13-21) ---
#set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33    } [get_ports { j13_5  }];          ;# IOB0,  B16_L4_N,  JB1-93
#set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33    } [get_ports { j13_6  }];          ;# IOB1,  B16_L4_P,  JB1-95
#set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33    } [get_ports { j13_7  }];          ;# IOB2,  B16_L3_N,  JB1-70
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33    } [get_ports { j13_8  }];          ;# IOB3,  B16_L2_N,  JB1-79
#set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33    } [get_ports { j13_9  }];          ;# IOB4,  B16_L5_P,  JB1-77
#set_property -dict { PACKAGE_PIN D16   IOSTANDARD LVCMOS33    } [get_ports { j13_10 }];          ;# IOB5,  B16_L5_N,  JB1-75
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33    } [get_ports { j13_11 }];          ;# IOB6,  B16_L7_P,  JB1-61
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33    } [get_ports { j13_12 }];          ;# IOB7,  B16_L7_N,  JB1-59
#set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33    } [get_ports { j13_13 }];          ;# IOB8,  B16_L18_P, JB1-51
#set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33    } [get_ports { j13_14 }];          ;# IOB9,  B16_L18_N, JB1-49
#set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33    } [get_ports { j13_15 }];          ;# IOB10, B16_L19_P, JB1-41
#set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33    } [get_ports { j13_16 }];          ;# IOB11, B16_L19_N, JB1-39
#set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVCMOS33    } [get_ports { j13_17 }];          ;# IOB12, B16_L21_N, JB1-58
#set_property -dict { PACKAGE_PIN B21   IOSTANDARD LVCMOS33    } [get_ports { j13_18 }];          ;# IOB13, B16_L21_P, JB1-56
#set_property -dict { PACKAGE_PIN B22   IOSTANDARD LVCMOS33    } [get_ports { j13_19 }];          ;# IOB14, B16_L20_N, JB1-52
#set_property -dict { PACKAGE_PIN C22   IOSTANDARD LVCMOS33    } [get_ports { j13_20 }];          ;# IOB15, B16_L20_P, JB1-50
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33    } [get_ports { j13_21 }];          ;# IOB16, B16_L15_N, JB1-48

# --- Bank 14 / 15 mixed segment (J13-22 .. J13-40) ---
#set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33    } [get_ports { j13_22 }];          ;# IOB17, B14_L8_N,  JB2-12  -- bank 14
#set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33    } [get_ports { j13_23 }];          ;# IOB18, B14_L17_P, JB2-18  -- bank 14
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33    } [get_ports { j13_24 }];          ;# IOB19, B15_L23_N, JB2-44  -- bank 15
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33    } [get_ports { j13_25 }];          ;# IOB20, B15_L16_N, JB2-68  -- bank 15
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33    } [get_ports { j13_26 }];          ;# IOB21, B15_L3_P,  JB2-56  -- bank 15
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33    } [get_ports { j13_27 }];          ;# IOB22, B15_L3_N,  JB2-58  -- bank 15
#set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33    } [get_ports { j13_28 }];          ;# IOB23, B15_L1_P,  JB2-72  -- bank 15
#set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33    } [get_ports { j13_29 }];          ;# IOB24, B14_L15_N, JB2-38  -- bank 14
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33    } [get_ports { j13_30 }];          ;# IOB25, B15_L23_P, JB2-42  -- bank 15
#set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33    } [get_ports { j13_31 }];          ;# IOB26, B15_L8_N,  JB2-35  -- bank 15
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33    } [get_ports { j13_32 }];          ;# IOB27, B15_L22_P, JB2-97  -- bank 15
#set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33    } [get_ports { j13_33 }];          ;# IOB28, B14_L16_N, JB2-34  -- bank 14
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33    } [get_ports { j13_34 }];          ;# IOB29, B15_L24_N, JB2-91  -- bank 15
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33    } [get_ports { j13_35 }];          ;# IOB30, B15_L6_P,  JB2-83  -- bank 15
#set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVCMOS33    } [get_ports { j13_36 }];          ;# IOB31, B15_L15_P, JB2-75  -- bank 15
#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33    } [get_ports { j13_37 }];          ;# IOB32, B15_L20_N, JB2-73  -- bank 15
#set_property -dict { PACKAGE_PIN N20   IOSTANDARD LVCMOS33    } [get_ports { j13_38 }];          ;# IOB33, B15_L18_P, JB2-65  -- bank 15
#set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33    } [get_ports { j13_39 }];          ;# IOB34, B15_L12_P, JB2-55  -- bank 15
#set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33    } [get_ports { j13_40 }];          ;# IOB35, B15_L12_N, JB2-57  -- bank 15



##############################################################################
# 12. Carrier J1 PMod (2x6)  --  bank 14, SHARED with SoM MIO / USB-UART
# --------------------------------------------------------------------------
# The J1 PMod sits on the SoM "MIO" bus. Every signal here is also wired
# through carrier-side series resistors (R29 / R30) to D11 / D12, which on the
# TE0705 carrier are the USB-UART bridge chips (and their associated buffers).
# If a USB serial cable is plugged into the carrier's USB port, that chip
# will be actively driving / receiving on the same nets the FPGA constrains
# here -- expect contention. Use J1 only when the carrier USB-UART is unused,
# or only as a tap-point for monitoring those same MIO signals.
#
# UART convention: MIO15 (J1-5, FPGA U18)  = serial TX (FPGA -> host)
#                  MIO14 (J1-7, FPGA P16)  = serial RX (host -> FPGA)
# J1-6 is a BUFFERED output of MIO12 (FPGA R17 drives buffer U1 input, U1
# output drives J1-6) -- it cannot be reconfigured by XDC.
##############################################################################
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33    } [get_ports { uart_txd_o }];      ;# J1-5,  MIO15, B14_L18_N, JB1-86
#set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33    } [get_ports { uart_rxd_i }];      ;# J1-7,  MIO14, B14_L24_P, JB1-91
#set_property -dict { PACKAGE_PIN Y22   IOSTANDARD LVCMOS33    } [get_ports { j1_8  }];           ;# MIO11, B14_L9_N,  JB1-94
#set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33    } [get_ports { j1_9  }];           ;# MIO9,  B14_L9_P,  JB1-92
#set_property -dict { PACKAGE_PIN T21   IOSTANDARD LVCMOS33    } [get_ports { j1_10 }];           ;# MIO10, B14_L4_P,  JB1-96
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33    } [get_ports { j1_11 }];           ;# MIO0,  B14_L18_P, JB1-88
#set_property -dict { PACKAGE_PIN U21   IOSTANDARD LVCMOS33    } [get_ports { j1_12 }];           ;# MIO13, B14_L4_N,  JB1-98
# (J1-6 not user-routable: buffered output of FPGA R17 via on-carrier chip U1.)



##############################################################################
# 13. Carrier J2 PMod (2x6)  --  bank 13   (UNVERIFIED VCCO -- see caveat)
# --------------------------------------------------------------------------
# All J2 pins land on bank 13. VCCIOC is wired to VIOTB on the CARRIER side,
# but on the prior TE0713 build the bank-13 supply was found to be open at
# the SoM (no actual VCCO reaching the bank). Until VCCO_BANK_13 is confirmed
# with a multimeter on this TE0712 build, treat these constraints as untested.
##############################################################################
#set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS33    } [get_ports { j2_5  }];           ;# IOC6, B13_L12_P, JB3-57
#set_property -dict { PACKAGE_PIN W12   IOSTANDARD LVCMOS33    } [get_ports { j2_6  }];           ;# IOC7, B13_L12_N, JB3-59
#set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS33    } [get_ports { j2_7  }];           ;# IOC4, B13_L2_N,  JB3-51
#set_property -dict { PACKAGE_PIN AB16  IOSTANDARD LVCMOS33    } [get_ports { j2_8  }];           ;# IOC5, B13_L2_P,  JB3-53
#set_property -dict { PACKAGE_PIN AA15  IOSTANDARD LVCMOS33    } [get_ports { j2_9  }];           ;# IOC2, B13_L4_P,  JB3-47
#set_property -dict { PACKAGE_PIN AB15  IOSTANDARD LVCMOS33    } [get_ports { j2_10 }];           ;# IOC3, B13_L4_N,  JB3-49
#set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33    } [get_ports { j2_11 }];           ;# IOC0, B13_L1_P,  JB3-41
#set_property -dict { PACKAGE_PIN AA16  IOSTANDARD LVCMOS33    } [get_ports { j2_12 }];           ;# IOC1, B13_L1_N,  JB3-43



##############################################################################
# End of master XDC.
##############################################################################
