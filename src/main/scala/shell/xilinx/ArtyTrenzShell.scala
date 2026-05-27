package sifive.fpgashells.shell.xilinx

import chisel3._
import chisel3.experimental.dataview._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci._
import org.chipsalliance.cde.config._
import sifive.fpgashells.clocks._
import sifive.fpgashells.devices.xilinx.xilinxartytrenzmig._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell._

// Trenz TE0712-03-72C36 SoM (XC7A100T-2FGG484C) on a TE0705 carrier.
//
// SoM SI5338 differential clock on H4/G4 (bank 35), IOSTANDARD
// DIFF_SSTL15. The TE0712 reference MIG is configured for a 50 MHz input.
class SysClockArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: ClockInputDesignInput, val shellInput: ClockInputShellInput)
  extends LVDSClockInputXilinxPlacedOverlay(name, designInput, shellInput)
{
  val node = shell { ClockSourceNode(freqMHz = 50, jitterPS = 50) }

  shell { InModuleBody {
    shell.xdc.addPackagePin(io.p, "H4")
    shell.xdc.addPackagePin(io.n, "G4")
    shell.xdc.addIOStandard(io.p, "DIFF_SSTL15")
    shell.xdc.addIOStandard(io.n, "DIFF_SSTL15")
  } }
}
class SysClockArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: ClockInputShellInput)(implicit val valName: ValName)
  extends ClockInputShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: ClockInputDesignInput) = new SysClockArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}

// USB-UART on the TE0705 carrier MIO group.
//   TX = U18 (JB1-86, IO_L18N_T2_A11_D27_14)
//   RX = P16 (JB1-91/JM1-92, IO_L24P_T3_A01_D17_14)
class UARTArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: UARTDesignInput, val shellInput: UARTShellInput)
  extends UARTXilinxPlacedOverlay(name, designInput, shellInput, false)
{
  shell { InModuleBody {
    val packagePinsWithPackageIOs = Seq(("P16", IOPin(io.rxd)),
      ("U18", IOPin(io.txd)))

    packagePinsWithPackageIOs foreach { case (pin, io) => {
      shell.xdc.addPackagePin(io, pin)
      shell.xdc.addIOStandard(io, "LVCMOS33")
      shell.xdc.addIOB(io)
    } }
  } }
}
class UARTArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: UARTShellInput)(implicit val valName: ValName)
  extends UARTShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: UARTDesignInput) = new UARTArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}

// JTAG debug brought out to the carrier 8-pin PMod J5 (bank 14).
//   TCK    = W20 (J5-1, JB2-23)
//   TMS    = V20 (J5-2, JB2-27)
//   TDI    = W19 (J5-3, JB2-21)
//   TDO    = U20 (J5-4, JB2-25)
//   srst_n = Y18 (J5-6, JB2-26)
class JTAGDebugArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: JTAGDebugDesignInput, val shellInput: JTAGDebugShellInput)
  extends JTAGDebugXilinxPlacedOverlay(name, designInput, shellInput)
{
  shell { InModuleBody {
    shell.sdc.addClock("JTCK", IOPin(io.jtag_TCK), 10)
    shell.sdc.addGroup(clocks = Seq("JTCK"))
    shell.xdc.clockDedicatedRouteFalse(IOPin(io.jtag_TCK))
    val packagePinsWithPackageIOs = Seq(("W20", IOPin(io.jtag_TCK)),
      ("V20", IOPin(io.jtag_TMS)),
      ("W19", IOPin(io.jtag_TDI)),
      ("U20", IOPin(io.jtag_TDO)),
      ("Y18", IOPin(io.srst_n)))

    packagePinsWithPackageIOs foreach { case (pin, io) => {
      shell.xdc.addPackagePin(io, pin)
      shell.xdc.addIOStandard(io, "LVCMOS33")
      shell.xdc.addPullup(io)
    } }
  } }
}
class JTAGDebugArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: JTAGDebugShellInput)(implicit val valName: ValName)
  extends JTAGDebugShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: JTAGDebugDesignInput) = new JTAGDebugArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}

// DDR3 on TE0712-03: two MT41J256M16-compatible parts (x16 each) in single-rank
// x32 = 1 GB total. Trenz reference MIG configured for 400 MHz mem
// (DDR3-800 effective) with 50 MHz input from the SoM SI5338. The MIG MMCM
// generates the 200 MHz IDELAYCTRL ref clock internally. UI clock is 100 MHz.
case object ArtyTrenzDDRSize extends Field[BigInt](0x40000000L) // 1 GB
class DDRArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: DDRDesignInput, val shellInput: DDRShellInput)
  extends DDRPlacedOverlay[XilinxArtyTrenzMIGPads](name, designInput, shellInput)
{
  val size = p(ArtyTrenzDDRSize)

  val ddrClk = shell { ClockSinkNode(freqMHz = 50) }
  val ddrGroup = shell { ClockGroup() }
  ddrClk := di.wrangler := ddrGroup := di.corePLL

  val migParams = XilinxArtyTrenzMIGParams(address = AddressSet.misaligned(di.baseAddress, size))
  val mig = LazyModule(new XilinxArtyTrenzMIG(migParams))
  val ddrUI     = shell { ClockSourceNode(freqMHz = 100) }
  val areset    = shell { ClockSinkNode(Seq(ClockSinkParameters())) }
  areset := di.wrangler := ddrUI

  def overlayOutput = DDROverlayOutput(ddr = mig.node)
  def ioFactory = new XilinxArtyTrenzMIGPads(size)

  shell { InModuleBody {
    require (shell.sys_clock.get.isDefined, "Use of DDRArtyTrenzPlacedOverlay depends on SysClockArtyTrenzPlacedOverlay")
    val (ui, _) = ddrUI.out(0)
    val (dclk, _) = ddrClk.in(0)
    val (ar, _) = areset.in(0)
    val port = mig.module.io.port

    io <> port.viewAsSupertype(new XilinxArtyTrenzMIGPads(mig.depth))
    ui.clock := port.ui_clk
    ui.reset := !port.mmcm_locked || port.ui_clk_sync_rst
    port.sys_clk_i := dclk.clock.asUInt
    port.sys_rst := !shell.pllReset
    port.aresetn := !(ar.reset.asBool)
  } }

  shell.sdc.addGroup(clocks = Seq("clk_pll_i"), pins = Seq(mig.island.module.blackbox.io.ui_clk))
}
class DDRArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: DDRShellInput)(implicit val valName: ValName)
  extends DDRShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: DDRDesignInput) = new DDRArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}

// Core to shell external resets
class CTSResetArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: CTSResetDesignInput, val shellInput: CTSResetShellInput)
  extends CTSResetPlacedOverlay(name, designInput, shellInput)
class CTSResetArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: CTSResetShellInput)(implicit val valName: ValName)
  extends CTSResetShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: CTSResetDesignInput) = new CTSResetArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}


abstract class ArtyTrenzShellBasicOverlays()(implicit p: Parameters) extends Series7Shell {
  // Order matters; ddr depends on sys_clock
  val sys_clock = Overlay(ClockInputOverlayKey, new SysClockArtyTrenzShellPlacer(this, ClockInputShellInput()))
  val ddr       = Overlay(DDROverlayKey, new DDRArtyTrenzShellPlacer(this, DDRShellInput()))
  val uart      = Overlay(UARTOverlayKey, new UARTArtyTrenzShellPlacer(this, UARTShellInput()))
  val jtag      = Overlay(JTAGDebugOverlayKey, new JTAGDebugArtyTrenzShellPlacer(this, JTAGDebugShellInput()))
  val cts_reset = Overlay(CTSResetOverlayKey, new CTSResetArtyTrenzShellPlacer(this, CTSResetShellInput()))
}

class ArtyTrenzShell()(implicit p: Parameters) extends ArtyTrenzShellBasicOverlays
{
  // resetPin holds the post-IBUF reset pin value. TE0712's carrier reset
  // input on T3 is ACTIVE HIGH.
  val resetPin = InModuleBody { Wire(Bool()) }
  // PLL reset causes
  val pllReset = InModuleBody { Wire(Bool()) }

  val topDesign = LazyModule(p(DesignKey)(designParameters))

  // Place the sys_clock at the Shell if the user didn't ask for it
  p(ClockInputOverlayKey).foreach(_.place(ClockInputDesignInput()))
  override lazy val module = new Impl
  class Impl extends LazyRawModuleImp(this) {
    override def provideImplicitClockToLazyChildren = true

    // Active-HIGH reset on T3 (bank 34, LVCMOS15). Wire a button to GND
    // through a pulldown if you want a manual reset; otherwise leave
    // floating and rely on power-on reset.
    val reset = IO(Input(Bool()))
    xdc.addPackagePin(reset, "T3")
    xdc.addIOStandard(reset, "LVCMOS15")

    val reset_ibuf = Module(new IBUF)
    reset_ibuf.io.I := reset
    val sysclk: Clock = sys_clock.get() match {
      case Some(x: SysClockArtyTrenzPlacedOverlay) => x.clock
    }
    val powerOnReset = PowerOnResetFPGAOnly(sysclk)
    sdc.addAsyncPath(Seq(powerOnReset))

    // TEMP: ignore external T3 reset pin - suspected stuck-high on the carrier,
    // which would hold pllReset asserted forever, keep the PLL from locking,
    // and park the JTAG-DTM in reset (TDO floats -> openocd sees all ones).
    // Re-enable once we confirm T3 wiring/level.
    resetPin := false.B
    pllReset := powerOnReset
    val _unused_reset_ibuf = reset_ibuf.io.O
  }
}

/*
   Copyright 2016 SiFive, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
