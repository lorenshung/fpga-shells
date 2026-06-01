package sifive.fpgashells.shell.xilinx

import chisel3._
import chisel3.experimental.dataview._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci._
import org.chipsalliance.cde.config._
import sifive.fpgashells.clocks._
import sifive.fpgashells.devices.xilinx.xilinxarty100tmig._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell._

// class SysClockArtyPlacedOverlay(val shell: Arty100TShellBasicOverlays, name: String, val designInput: ClockInputDesignInput, val shellInput: ClockInputShellInput)
//   extends SingleEndedClockInputXilinxPlacedOverlay(name, designInput, shellInput)
// {
//   val node = shell { ClockSourceNode(freqMHz = 100, jitterPS = 50) }

//   shell { InModuleBody {
//     val clk: Clock = io
//     shell.xdc.addPackagePin(clk, "E3")
//     shell.xdc.addIOStandard(clk, "LVCMOS33")
//   } }
// }

class SysClockArtyPlacedOverlay(val shell: Arty100TShellBasicOverlays, name: String,
      val designInput: ClockInputDesignInput, val shellInput: ClockInputShellInput)
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

class SysClockArtyShellPlacer(val shell: Arty100TShellBasicOverlays, val shellInput: ClockInputShellInput)(implicit val valName: ValName)
  extends ClockInputShellPlacer[Arty100TShellBasicOverlays] {
  def place(designInput: ClockInputDesignInput) = new SysClockArtyPlacedOverlay(shell, valName.name, designInput, shellInput)
}


abstract class Arty100TShellBasicOverlays()(implicit p: Parameters) extends Series7Shell {
  val sys_clock = Overlay(ClockInputOverlayKey, new SysClockArtyShellPlacer(this, ClockInputShellInput()))
}

class Arty100TShell()(implicit p: Parameters) extends Arty100TShellBasicOverlays
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
      case Some(x: SysClockArtyPlacedOverlay) => x.clock
    }
    val powerOnReset = PowerOnResetFPGAOnly(sysclk)
    sdc.addAsyncPath(Seq(powerOnReset))

    resetPin := true.B
    pllReset := powerOnReset
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
