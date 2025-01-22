from migen import *
from migen.fhdl import verilog

from local_duc import PhasedDUC, PhasedAccu, MCM
from misoc.cores.cossin import CosSinGen
from migen.genlib.fsm import FSM
from math import log,ceil


class PhasedPurePhaseModulator(Module):
    def __init__(self,mod_depth_width=8,scaling_width=16,fwidth=32,dac_sync_period=8,sync_dly=0):

        parallel_units = 16 

        n, logn = 8, 3
        skip = n//parallel_units

        accum_out_width = 20

        carrier_in_width = accum_out_width - logn
        
        carrier_out_width = 13


        modulation_width = mod_depth_width + carrier_out_width + 1 # This extra bit is likely for a proper sign conversion
        phase_difference_width = modulation_width

        cs_sine_cos_in_width = modulation_width
        cs_sine_cos_out_width = 16

        output_scaled_width = scaling_width + cs_sine_cos_out_width + 1 # This extra bit is likely for a proper sign conversion

        output_pwidth = 16
        
        
        #Instantiation of the phased accumulator that provides n samples at once
        # to the subsequent logics
        accu = PhasedAccu(n=parallel_units,fwidth=fwidth, pwidth=accum_out_width)
        self.submodules.accu = accu
        self.f, self.p, self.accu_clr = accu.f, accu.p, accu.clr

        
        # Instantiation of the digital up converter
        duc = PhasedDUC(n=parallel_units,fwidth=48, pwidth=accum_out_width)
        self.submodules.duc = duc

        self.nco_freq, self.nco_phase, self.nco_clr = duc.f, duc.p, duc.clr             
        
        #Every signal and module below is replicated using list comprehension
        #TO DO: see if it is possibile to share LUTs
        cs_carrier = [CosSinGen(z=carrier_in_width , x=carrier_out_width, zl=9, xd=4) for _ in range(parallel_units)]
        self.submodules.cs_carrier = cs_carrier

        self.multiplier = Signal(mod_depth_width,reset = 2**(mod_depth_width-1)-1)

        self.phase = Signal(phase_difference_width,reset = 2**(output_pwidth+mod_depth_width-1))

        self.i_amp = Signal(scaling_width,reset=2**scaling_width-1)
        self.q_amp = Signal(scaling_width,reset=2**scaling_width-1)

        self.modulation = [Signal(modulation_width) for _ in range(parallel_units)]

        self.packed_output = Signal(parallel_units*16)

        self.cs_cossin = [CosSinGen(z=cs_sine_cos_in_width, x=cs_sine_cos_out_width, zl=9, xd=4) for _ in range(parallel_units)]

        self.submodules.cs_cossin = self.cs_cossin
        
        output_i_scaled = [Signal(output_scaled_width) for _ in range(parallel_units)]
        output_q_scaled = [Signal(output_scaled_width) for _ in range(parallel_units)]

        self.pdh_accumulator = [Signal(accum_out_width) for _ in range(n)]
        self.phase_PDH = Signal(accum_out_width)
        self.pdh_output = Signal(n)
        self.clr = Signal()
        self.nco_update_busy = Signal()
        self.nco_update_req = Signal()
        self.cos = [Signal(cs_sine_cos_out_width+1) for _ in range(parallel_units)] 
        self.sin = [Signal(cs_sine_cos_out_width+1) for _ in range(parallel_units)]

        #The sync statement is replicated n times to
        for k in range(parallel_units): 
            self.sync += [cs_carrier[k].z.eq(accu.z[k*skip][3:]),
                            self.modulation[k].eq((self.multiplier)*cs_carrier[k].x),
                            self.cs_cossin[k].z.eq(self.modulation[k]),
                            self.cos[k].eq(self.cs_cossin[k].x),
                            self.sin[k].eq(self.cs_cossin[k].y),
                            output_i_scaled[k].eq(self.cos[k]*self.i_amp),
                            output_q_scaled[k].eq(self.sin[k]*self.q_amp),
                            self.duc.i[k].i.eq(output_i_scaled[k][output_scaled_width-output_pwidth:output_scaled_width]),
                            self.duc.i[k].q.eq(output_q_scaled[k][output_scaled_width-output_pwidth:output_scaled_width])                   
                         ]

        for k in range(parallel_units):
            self.comb += [ self.packed_output[k*16+2:k*16+16].eq(self.duc.o[k].i[2:16])]
            self.comb += [ self.packed_output[k*16:k*16+2].eq(0)] 
        
        #Connecting all clear signals
        self.comb += [self.nco_clr.eq(self.clr),
                      self.accu_clr.eq(self.clr)]

        for k in range(n):
            self.sync += [                
                          #PDH squarewave
                          self.pdh_accumulator[k].eq(self.phase_PDH + accu.z[k*2]),
                          self.pdh_output[k].eq(self.pdh_accumulator[k][accum_out_width-1]) 
                         ]
        self.sync += [self.nco_update_busy.eq( ~ self.nco_update_req )]


class ComplexSignal():
    def __init__(self,pwidth=15):
        self.i = Signal(pwidth)
        self.q = Signal(pwidth)




if __name__ == "__main__":
    my_esbl = PhasedPurePhaseModulator()
    name = "phase_generator_parallel"
    verilog_code = verilog.convert(my_esbl,
                          name = name,
                          ios={my_esbl.f,
                               my_esbl.phase,
                               my_esbl.i_amp,
                               my_esbl.q_amp,
                               my_esbl.multiplier,
                               my_esbl.phase_PDH,
                               my_esbl.clr,
                               my_esbl.packed_output,
                               my_esbl.pdh_output,
                               my_esbl.nco_freq,
                               my_esbl.nco_phase,
                               my_esbl.nco_update_busy,
                               my_esbl.nco_update_req
                               })
    print(verilog_code)
    verilog_code.write(name + ".v")