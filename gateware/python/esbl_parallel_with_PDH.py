from migen import *
from migen.fhdl import verilog

from misoc.cores.duc import PhasedDUC, PhasedAccu, CosSinGen
from migen.genlib.fsm import FSM
from math import log,ceil


class PhasedPurePhaseModulator(Module):
    def __init__(self,parallel_units=1,mod_depth_width=8,scaling_width=16,fwidth=32,dac_sync_period=8,sync_dly=0):

        if not ( parallel_units in {1,2,4,8} ):
            raise Exception("parallel units can only be 1, 2, 4 or 8") 

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
        accu = PhasedAccu(n=8,fwidth=fwidth, pwidth=accum_out_width)
        self.submodules.accu = accu
        self.f, self.p, self.clr = accu.f, accu.p, accu.clr

        
               
        
        #Every signal and module below is replicated using list comprehension
        #TO DO: see if it is possibile to share LUTs
        cs_carrier = [CosSinGen(z=carrier_in_width , x=carrier_out_width, zl=9, xd=4) for _ in range(parallel_units)]
        self.submodules.cs_carrier = cs_carrier

        self.multiplier = Signal(mod_depth_width,reset = 2**(mod_depth_width-1)-1)

        self.phase = Signal(phase_difference_width,reset = 2**(output_pwidth+mod_depth_width-1))

        self.i_amp = Signal(scaling_width,reset=2**scaling_width-1)
        self.q_amp = Signal(scaling_width,reset=2**scaling_width-1)

        self.modulation = [Signal(modulation_width) for _ in range(parallel_units)]
        self.o = [ComplexSignal(pwidth = output_pwidth) for _ in range(parallel_units)]

        self.packed_output = Signal(parallel_units*32)

        cs_sine = [CosSinGen(z=cs_sine_cos_in_width, x=cs_sine_cos_out_width, zl=9, xd=4) for _ in range(parallel_units)]
        cs_cosine = [CosSinGen(z=cs_sine_cos_in_width, x=cs_sine_cos_out_width, zl=9, xd=4) for _ in range(parallel_units)]
        self.submodules.cs_sine = cs_sine
        self.submodules.cs_cosine = cs_cosine
        
        output_i_scaled = [Signal(output_scaled_width) for _ in range(parallel_units)]
        output_q_scaled = [Signal(output_scaled_width) for _ in range(parallel_units)]

        self.pdh_accumulator = [Signal(accum_out_width) for _ in range(n)]
        self.phase_PDH = Signal(accum_out_width)
        self.pdh_output = Signal(n)

        #The sync statement is replicated n times to
        for k in range(parallel_units): 
            self.sync += [cs_carrier[k].z.eq(accu.z[k*skip][3:]),
                            self.modulation[k].eq((self.multiplier)*cs_carrier[k].x),
                            self.cs_sine[k].z.eq(self.modulation[k]),
                            self.cs_cosine[k].z.eq(self.modulation[k] + self.phase),
                            output_i_scaled[k].eq(cs_cosine[k].x*self.i_amp),
                            output_q_scaled[k].eq(cs_sine[k].x*self.q_amp),
                            self.o[k].i.eq(output_i_scaled[k][output_scaled_width-output_pwidth:output_scaled_width]),
                            self.o[k].q.eq(output_q_scaled[k][output_scaled_width-output_pwidth:output_scaled_width])]

        for k in range(parallel_units):
            self.comb += [ self.packed_output[k*32:k*32+32].eq( Cat(self.o[k].i,self.o[k].q))]    
        

        for k in range(n):
            self.sync += [                
                          #PDH squarewave
                          self.pdh_accumulator[k].eq(self.phase_PDH + accu.z[k]),
                          self.pdh_output[k].eq(self.pdh_accumulator[k][accum_out_width-1]) 
                         ]
        


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
                               my_esbl.pdh_output})
    print(verilog_code)
    verilog_code.write(name + ".v")