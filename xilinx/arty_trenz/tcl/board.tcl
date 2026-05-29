# See LICENSE for license details.
#
# arty_trenz is driven from the raw FPGA part + explicit addPackagePin / xdc
# pin assignments (see ArtyTrenzShell.scala + arty_trenz-master.xdc). No
# Vivado board file is needed: the MIG IP is configured from our own embedded
# .prj XML (see ip/xilinx/arty_trenzmig/arty_trenzmig.scala) and the shell
# never calls addBoardPin. Leaving $part_board empty tells prologue.tcl to
# skip BOARD_PART entirely.
set name {arty-trenz}
set part_fpga {xc7a100tfgg484-2}
set part_board {}
set bootrom_inst {rom}
