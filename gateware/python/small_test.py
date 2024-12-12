from migen import *
from migen.fhdl import verilog

from misoc.cores.duc import PhasedDUC, PhasedAccu, CosSinGen
from migen.genlib.fsm import FSM
from math import log,ceil


class PhasedPurePhaseModulator(Module):
    def __init__(self,n=8,output_pwidth=16,mod_depth_width=8,scaling_width=16,fwidth=32,dac_sync_period=8,sync_dly=0):

        accu = PhasedAccu(n=8,fwidth=fwidth, pwidth=20)
        self.submodules.accu = accu
        self.f, self.p, self.clr = accu.f, accu.p, accu.clr

        
               
        
        #Every signal and module below is replicated using list comprehension
        #TO DO: see if it is possibile to share LUTs
        cs_carrier = CosSinGen(z=17 , x=13, zl=9, xd=4)
        self.submodules.cs_carrier = cs_carrier

        

        #The sync statement is replicated n times to
       
        self.sync += [cs_carrier.z.eq(accu.z[0][3:])]
        


class ComplexSignal():
    def __init__(self,pwidth=15):
        self.i = Signal(pwidth)
        self.q = Signal(pwidth)




if __name__ == "__main__":
    my_esbl = PhasedPurePhaseModulator()
    name = "sine_test"
    verilog_code = verilog.convert(my_esbl,
                          name = name,
                          ios={my_esbl.f,
                               my_esbl.p,
                               my_esbl.clr,
                               my_esbl.cs_carrier.x
})
    print(verilog_code)
    verilog_code.write(name+".v")