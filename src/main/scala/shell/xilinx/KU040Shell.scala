package sifive.fpgashells.shell.xilinx

import chisel3._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci._
import org.chipsalliance.cde.config._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell._

// Minimal shell for a custom XCKU040-1SFVA784C board, modeled on the
// (Trenz-modified) Arty100TShell. Only provides the 200 MHz LVDS system
// clock input; UART/JTAG pins are placed by chipyard harness binders.
class SysClockKU040PlacedOverlay(val shell: KU040ShellBasicOverlays, name: String,
      val designInput: ClockInputDesignInput, val shellInput: ClockInputShellInput)
    extends LVDSClockInputXilinxPlacedOverlay(name, designInput, shellInput)
{
  val node = shell { ClockSourceNode(freqMHz = 200, jitterPS = 50) }
  shell { InModuleBody {
    // sysclk_200_p/n; board XML specifies diff_term FALSE (IBUFDS default)
    shell.xdc.addPackagePin(io.p, "R25")
    shell.xdc.addPackagePin(io.n, "R26")
    shell.xdc.addIOStandard(io.p, "LVDS")
    shell.xdc.addIOStandard(io.n, "LVDS")
  } }
}

class SysClockKU040ShellPlacer(val shell: KU040ShellBasicOverlays, val shellInput: ClockInputShellInput)(implicit val valName: ValName)
  extends ClockInputShellPlacer[KU040ShellBasicOverlays] {
  def place(designInput: ClockInputDesignInput) = new SysClockKU040PlacedOverlay(shell, valName.name, designInput, shellInput)
}

abstract class KU040ShellBasicOverlays()(implicit p: Parameters) extends UltraScaleShell {
  val sys_clock = Overlay(ClockInputOverlayKey, new SysClockKU040ShellPlacer(this, ClockInputShellInput()))
}

class KU040Shell()(implicit p: Parameters) extends KU040ShellBasicOverlays
{
  val resetPin = InModuleBody { Wire(Bool()) }
  // PLL reset causes
  val pllReset = InModuleBody { Wire(Bool()) }

  val topDesign = LazyModule(p(DesignKey)(designParameters))

  // Place the sys_clock at the Shell if the user didn't ask for it
  p(ClockInputOverlayKey).foreach(_.place(ClockInputDesignInput()))
  override lazy val module = new Impl
  class Impl extends LazyRawModuleImp(this) {
    override def provideImplicitClockToLazyChildren = true

    val sysclk: Clock = sys_clock.get() match {
      case Some(x: SysClockKU040PlacedOverlay) => x.clock
    }
    val powerOnReset = PowerOnResetFPGAOnly(sysclk)
    sdc.addAsyncPath(Seq(powerOnReset))

    resetPin := true.B
    pllReset := powerOnReset
  }
}
