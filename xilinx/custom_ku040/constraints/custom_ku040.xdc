set_property BITSTREAM.GENERAL.COMPRESS TRUE          [current_design]
# TODO: verify bank-0 config wiring on the custom board. Alinx KU040 uses
# CFGBVS VCCO / CONFIG_VOLTAGE 3.3; a 1.8V config bank needs CFGBVS GND /
# CONFIG_VOLTAGE 1.8. Wrong values only warn for JTAG-loaded bitstreams.
set_property CFGBVS VCCO                              [current_design]
set_property CONFIG_VOLTAGE 3.3                       [current_design]
