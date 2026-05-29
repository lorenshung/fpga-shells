package sifive.fpgashells.shell.xilinx

import chisel3._
import chisel3.experimental.dataview._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci._
import org.chipsalliance.cde.config._
import sifive.fpgashells.clocks._
import sifive.fpgashells.devices.xilinx.xilinxarty_trenzmig._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell._

// ----------------------------------------------------------------------------
// System clock: differential 100 MHz on H4 (P) / G4 (N), DIFF_SSTL15 (bank 35).
// Per reference/te0712-rd/board_files/.../part0_pins.xml and .../mig.prj.
// ----------------------------------------------------------------------------
class SysClockArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: ClockInputDesignInput, val shellInput: ClockInputShellInput)
  extends LVDSClockInputXilinxPlacedOverlay(name, designInput, shellInput)
{
  val node = shell { ClockSourceNode(freqMHz = 100, jitterPS = 50)(ValName(name)) }

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

// ----------------------------------------------------------------------------
// UART: routed onto the TE0712 SoM MIO bus, which on the TE0705 carrier feeds
// the on-board USB-UART chips (D11/D12) and PMod J1.
//   TX  (FPGA -> host) = U18  (MIO15, B14_L18_N, JB1-86, carrier J1-5)
//   RX  (host -> FPGA) = P16  (MIO14, B14_L24_P, JB1-91, carrier J1-7)
// Both LVCMOS33 on bank 14.
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// TE0712 on-SoM LEDs. These pins are shared with I2C-to-CPLD in the reference
// design; this shell leaves that I2C bus unused so the LEDs are available for
// bringup/debug indicators.
//   sys_led = U22
//   led2    = W22
// ----------------------------------------------------------------------------
object LEDArtyTrenzPinConstraints {
  val pins = Seq("U22", "W22")
}
class LEDArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: LEDDesignInput, val shellInput: LEDShellInput)
  extends LEDXilinxPlacedOverlay(name, designInput, shellInput, packagePin = Some(LEDArtyTrenzPinConstraints.pins(shellInput.number)))
class LEDArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: LEDShellInput)(implicit val valName: ValName)
  extends LEDShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: LEDDesignInput) = new LEDArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}

// ----------------------------------------------------------------------------
// JTAG: external FTDI probe on carrier J5 PMod pins 1..4 (per pin-matching.csv
// silkscreen). Routing FPGA -> R49 (series resistor) -> D16 (passive 4-channel
// TVS/ESD array, SOT-23-6) -> J5 pin. No level translation in the path.
//   J5-1 TCK = W20  (B14_L12_N, JB2-23, PA0_P)
//   J5-2 TMS = V20  (B14_L11_N, JB2-27, PA1_P)
//   J5-3 TDI = W19  (B14_L12_P, JB2-21, PA0_N)
//   J5-4 TDO = U20  (B14_L11_P, JB2-25, PA1_N)
// All LVCMOS33 on bank 14, with PULLUP added to keep idle JTAG defined when
// the cable is unplugged.
// ----------------------------------------------------------------------------
class JTAGDebugArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: JTAGDebugDesignInput, val shellInput: JTAGDebugShellInput)
  extends JTAGDebugXilinxPlacedOverlay(name, designInput, shellInput)
{
  shell { InModuleBody {
    shell.sdc.addClock("JTCK", IOPin(io.jtag_TCK), 10)
    shell.sdc.addGroup(clocks = Seq("JTCK"))
    shell.xdc.clockDedicatedRouteFalse(IOPin(io.jtag_TCK))
    val packagePinsWithPackageIOs = Seq(("W20", IOPin(io.jtag_TCK)),  // J5-1
                                        ("V20", IOPin(io.jtag_TMS)),  // J5-2
                                        ("W19", IOPin(io.jtag_TDI)),  // J5-3
                                        ("U20", IOPin(io.jtag_TDO)),  // J5-4
                                        ("F18", IOPin(io.srst_n)))    // J11-17 (spare bank-16 pin)

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

// ----------------------------------------------------------------------------
// DDR3: TE0712 has 1 GB of MT41J256M16XX-125 (32-bit data, DDR3-800).
// MIG sys_clk_i and clk_ref_i are PLL-driven (No Buffer mode in mig.prj).
// ----------------------------------------------------------------------------
case object ArtyTrenzDDRSize extends Field[BigInt](0x40000000L) // 1 GB
class DDRArtyTrenzPlacedOverlay(val shell: ArtyTrenzShellBasicOverlays, name: String, val designInput: DDRDesignInput, val shellInput: DDRShellInput)
  extends DDRPlacedOverlay[XilinxArtyTrenzMIGPads](name, designInput, shellInput)
{
  val size = p(ArtyTrenzDDRSize)

  val ddrClk1 = shell { ClockSinkNode(freqMHz = 200) }
  val ddrClk2 = shell { ClockSinkNode(freqMHz = 200) }
  val ddrGroup = shell { ClockGroup() }
  ddrClk1 := di.wrangler := ddrGroup := di.corePLL
  ddrClk2 := di.wrangler := ddrGroup

  val migParams = XilinxArtyTrenzMIGParams(address = AddressSet.misaligned(di.baseAddress, size))
  val mig = LazyModule(new XilinxArtyTrenzMIG(migParams))
  val ddrUI     = shell { ClockSourceNode(freqMHz = 100) }
  val areset    = shell { ClockSinkNode(Seq(ClockSinkParameters())) }
  areset := di.wrangler := ddrUI

  def overlayOutput = DDROverlayOutput(ddr = mig.node)
  def ioFactory = new XilinxArtyTrenzMIGPads(size)

  shell { InModuleBody {
    require (shell.sys_clock.get.isDefined, "Use of DDRArtyTrenzPlacedOverlay depends on SysClockArtyTrenzPlacedOverlay")
    val (sys, _) = shell.sys_clock.get.get.overlayOutput.node.out(0)
    val (ui, _) = ddrUI.out(0)
    val (dclk1, _) = ddrClk1.in(0)
    val (dclk2, _) = ddrClk2.in(0)
    val (ar, _) = areset.in(0)
    val port = mig.module.io.port

    io <> port.viewAsSupertype(new XilinxArtyTrenzMIGPads(mig.depth))
    ui.clock := port.ui_clk
    ui.reset := !port.mmcm_locked || port.ui_clk_sync_rst
    port.sys_clk_i := dclk1.clock.asUInt
    port.clk_ref_i := dclk2.clock.asUInt
    port.sys_rst := shell.pllReset
    port.aresetn := !(ar.reset.asBool)
  } }

  shell.sdc.addGroup(clocks = Seq("clk_pll_i"), pins = Seq(mig.island.module.blackbox.io.ui_clk))
}
class DDRArtyTrenzShellPlacer(val shell: ArtyTrenzShellBasicOverlays, val shellInput: DDRShellInput)(implicit val valName: ValName)
  extends DDRShellPlacer[ArtyTrenzShellBasicOverlays] {
  def place(designInput: DDRDesignInput) = new DDRArtyTrenzPlacedOverlay(shell, valName.name, designInput, shellInput)
}


abstract class ArtyTrenzShellBasicOverlays()(implicit p: Parameters) extends Series7Shell {
  // Order matters: ddr depends on sys_clock.
  val sys_clock = Overlay(ClockInputOverlayKey, new SysClockArtyTrenzShellPlacer(this, ClockInputShellInput()))
  val ddr       = Overlay(DDROverlayKey,        new DDRArtyTrenzShellPlacer(this, DDRShellInput()))
  val led       = Seq.tabulate(2)(i => Overlay(LEDOverlayKey, new LEDArtyTrenzShellPlacer(this, LEDMetas(i))(valName = ValName(s"led_$i"))))
  val uart      = Overlay(UARTOverlayKey,       new UARTArtyTrenzShellPlacer(this, UARTShellInput()))
  val jtag      = Overlay(JTAGDebugOverlayKey,  new JTAGDebugArtyTrenzShellPlacer(this, JTAGDebugShellInput()))

  def LEDMetas(i: Int): LEDShellInput =
    LEDShellInput(
      color = if (i == 0) "red" else "green",
      number = i)
}

class ArtyTrenzShell()(implicit p: Parameters) extends ArtyTrenzShellBasicOverlays
{
  // Active-HIGH reset routed from carrier SC_nRST through the SoM CPLD to T3
  // (LVCMOS15, bank 35). Suspected stuck-high on prior boards -- if the design
  // never leaves reset, the HarnessBinder / wrapper can mask this to 1'b0.
  val resetPin = InModuleBody { Wire(Bool()) }
  val pllReset = InModuleBody { Wire(Bool()) }

  val topDesign = LazyModule(p(DesignKey)(designParameters))

  // Place the sys_clock at the Shell if the user didn't ask for it
  p(ClockInputOverlayKey).foreach(_.place(ClockInputDesignInput()))

  override lazy val module = new Impl
  class Impl extends LazyRawModuleImp(this) {
    override def provideImplicitClockToLazyChildren = true

    val reset = IO(Input(Bool()))
    xdc.addPackagePin(reset, "T3")
    xdc.addIOStandard(reset, "LVCMOS15")
    xdc.addPullup(reset) // matches te0712-rd: PULLDOWN, but we keep PULLUP-style behavior consistent

    val reset_ibuf = Module(new IBUF)
    reset_ibuf.io.I := reset
    val sysclk: Clock = sys_clock.get() match {
      case Some(x: SysClockArtyTrenzPlacedOverlay) => x.clock
    }
    val powerOnReset = PowerOnResetFPGAOnly(sysclk)
    sdc.addAsyncPath(Seq(powerOnReset))

    resetPin := reset_ibuf.io.O

    // TE0712 reset is active-HIGH (per board.xml SysResetPolarity), but the
    // prior trenz attempt observed T3 stuck-high -> design never left reset.
    // Until that is resolved, treat external reset as advisory (powerOnReset
    // is the authoritative cold-boot reset).
    pllReset := powerOnReset
  }
}
