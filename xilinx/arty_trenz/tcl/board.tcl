# See LICENSE for license details.

# Trenz TE0713-02 SoM (XC7A100T-2FGG484C) on a TE0705 carrier.
# No Vivado board store entry: pins are constrained directly from the
# Scala shell via xdc.addPackagePin.
set name {arty-trenz}
set part_fpga {xc7a100tfgg484-2}
# No Vivado board store entry exists for the TE0713/TE0705 — leave
# BOARD_PART unset by passing an empty string. prologue.tcl skips the
# property when this is empty.
set part_board {}
set bootrom_inst {rom}
