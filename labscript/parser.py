from pynq import Overlay, MMIO, allocate
from pynq.overlays.base import BaseOverlay
import numpy as np
import socket
import threading
from subprocess import call


def ramp_generator(startfreq,endfreq,stepnum,sampling_rate = 6_881_280_000):
    # Frequencies in Hz
    freqList = np.linspace(startfreq,endfreq,stepnum)
    XRFDC_NCO_FREQ_MULTIPLIER = np.array(0x1 << 48,dtype = np.uint64)
    return np.array( (freqList * XRFDC_NCO_FREQ_MULTIPLIER) // sampling_rate,dtype = np.uint64)



def start_server(host="192.168.2.99", port=6750):
    server_stopEvent = threading.Event()
    try:
        with open("parser_error.txt", "x") as f:
            f.close()
    except:
        pass
    class ESBL(BaseOverlay):
        def __init__(self):
            Overlay.__init__(self,'main.bit')
            if self.is_loaded():
                self.lock = threading.Lock()
                self.i2c_initialized = False
                self.display_port_initialized = False
                self.radio = self.usp_rf_data_converter_0
                self.reg = MMIO(self.ip_dict['ESBL_control_reg']['phys_addr'],
                                self.ip_dict['ESBL_control_reg']['addr_range']).array
                self.init_rf_clks()
                self.dma_init()
                self.mod_sample_rate = 430_080_000
                self.dmasender = self.axi_dma_0.sendchannel

                self.freq = 0.001
    #             self.radio.dac_tiles[0].blocks[0].MixerSettings['EventSource'] = 0 # Set to Immediate
                self.radio.dac_tiles[0].blocks[0].MixerSettings['EventSource'] = 2 # Set to Tile (necessary for DMA)
                self.radio.dac_tiles[0].blocks[0].MixerSettings['FineMixerScale'] = 1
                self.freq = 245.0
                
                self.set_i_ampl()
                self.set_q_ampl()
                self.set_phase_difference()
        
        @property 
        def freq(self): # MHz
            return self.radio.dac_tiles[0].blocks[0].MixerSettings['Freq']
        
        @freq.setter
        def freq(self,freq): # MHz
            with self.lock:
                self.radio.dac_tiles[0].blocks[0].MixerSettings['Freq'] = freq
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)
        
        def get_modulation_config(self):
            #return the current modulation configurations in the order of:
            #mod_frequency, mod_depth, IQ_phase, I_ampl, Q_ampl, ref_phase_offset
            with self.lock:
                mod_configs = self.reg.copy()
                return np.array([mod_configs[0]*8*self.mod_sample_rate/0xFFFF_FFFF,
                                        mod_configs[1],
                                        mod_configs[2]/0x00100000*90-90,
                                        mod_configs[3]/0x0000FFFF,
                                        mod_configs[4]/0x0000FFFF,
                                        mod_configs[5]
                                        ])


        def set_i_ampl(self,i_ampl = 0x0000FFFF):
            #set i_ampl (16 bits)
            if i_ampl>0x0000FFFF:
                i_ampl = 0x0000FFFF
            elif i_ampl<0:
                i_ampl = 0
            with self.lock:
                self.reg[3] = i_ampl
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)
        
        def set_q_ampl(self,q_ampl = 0x0000FFFF):
            #set q_ampl (16 bits)
            if q_ampl>0x0000FFFF:
                q_ampl = 0x0000FFFF
            elif q_ampl<0:
                q_ampl = 0
            with self.lock:
                self.reg[4] = q_ampl 
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)
            
        def set_phase_difference(self,ph_diff = 0):  # default for 90 degrees
            #set the phase difference to 90 deg
            with self.lock:
                self.reg[2] = 0x00100000  + int(ph_diff/90*0x00100000)
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)
            
        def set_PDH_phase(self,phase):
            #in machine units (20 bits)
            phase = int((np.unwrap(phase,np.pi) / 360+0.5) * 0x00100000)
            with self.lock:
                self.reg[5]= phase
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)

        def set_mod_frequency(self,frequency, sampling_rate = None):
            if sampling_rate is None:
                sampling_rate = self.mod_sample_rate    
            frequency_code = int(frequency * 0xFFFF_FFFF / sampling_rate / 8) # divided by 8 because the PDH generator runs 8 times faster
            with self.lock:
                self.reg[0] = frequency_code
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)

        def set_mod_depth(self,depth=82):
            # 8 bits
            if depth > 255:
                depth = 255
            elif depth < 0:
                depth = 0
            with self.lock:
                self.reg[1] = depth
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)

        def set_VOP(self,vop=20000):
            if vop > 40000:
                return 0
            elif vop > 32000:
                return 1
            elif vop < -32000 and vop > -40000:
                vop = - vop
            with self.lock:
                self.radio.dac_tiles[0].blocks[0].SetDACVOP(vop)
                self.radio.dac_tiles[0].blocks[0].UpdateEvent(1)
            return 0

        
        def dma_init(self,buffer_length = 1048576):
                self.send_buffer = allocate(shape=(buffer_length,), dtype=np.uint64)

        def dma_clear(self):
            with self.lock:
                self.send_buffer.freebuffer()
                del self.send_buffer

        def dma_transfer(self,length):
            self.dmasender.transfer(self.send_buffer, nbytes =length)



    esbl = ESBL()



    def handle_client(client_socket):
        try:
            buffer = ""
            while True:
                data = client_socket.recv(1024).decode("ascii")
                if not data:
                    # Connection closed
                    break
                buffer += data
                while ";" in buffer:
                    message, buffer = buffer.split(";", 1)
                    # Handle instructions
                    if "FC" in message:
                        _,message = message.split("FC")
                        esbl.freq = float(message)/1e6
                        client_socket.sendall("Carrier frequency set".encode("ascii"))
                    elif "ASC" in message:
                        # Asynchronous frequency scan
                        _,message = message.split("ASC")
                        startfreq,endfreq,stepnum = message.split(",")
                        esbl.send_buffer[:int(stepnum)] = ramp_generator(int(startfreq),int(endfreq),int(stepnum))
                        esbl.dma_transfer(int(stepnum)*8)
                        client_socket.sendall("DMA started".encode("ascii"))
                    elif "SSC" in message:
                        # Synchronous frequency scan
                        _,message = message.split("SSC")
                        startfreq,endfreq,stepnum = message.split(",")
                        esbl.send_buffer[:stepnum] = ramp_generator(int(startfreq),int(endfreq),int(stepnum))
                        # TODO: Need a physical trigger line
                    elif "FM" in message:
                        _,message = message.split("FM")
                        esbl.set_mod_frequency(int(message))
                        client_socket.sendall("Modulation frequency set".encode("ascii"))
                    elif "AM" in message:
                        _,message = message.split("AM")
                        check = esbl.set_VOP(int(32000*float(message)))
                        if check == 1:
                            client_socket.sendall(f"Warning: you are asking for a VOP greater than typical value;if you insist please add a minus sign before the value;".encode("ascii"))
                        client_socket.sendall("VOP set".encode("ascii"))
                    elif "PM" in message:
                        _,message = message.split("PM")
                        esbl.set_PDH_phase(int(message))
                        client_socket.sendall("Reference phase offset set".encode("ascii"))
                    elif "MD" in message:
                        _,message = message.split("MD")
                        esbl.set_mod_depth(int(message))
                        client_socket.sendall("Amplitude depth set".encode("ascii"))
                    elif "SA" in message:
                        _,message = message.split("SA")
                        esbl.set_i_ampl(int(float(message)*0x0000FFFF))
                        client_socket.sendall("I amplitude set".encode("ascii"))
                    elif "CA" in message:
                        _,message = message.split("CA")
                        esbl.set_q_ampl(int(float(message)*0x0000FFFF))
                        client_socket.sendall("Q amplitude set".encode("ascii"))
                    elif "SP" in message:
                        _,message = message.split("SP")
                        esbl.set_phase_difference(float(message))
                        client_socket.sendall("IQ phase difference set".encode("ascii"))
                    elif "SHUTDOWN" in message:
                        client_socket.sendall("Shutdown now; wait at least for 1 minute before turning the RFSoC off".encode("ascii"))
                        call('echo {} | sudo poweroff'.format('xilinx'), shell=True)
                    elif "REBOOT" in message:
                        client_socket.sendall("Reboot now".encode("ascii"))
                        call('echo {} | sudo reboot'.format('xilinx'), shell=True)
                    elif "END" in message:
                        client_socket.sendall("Terminating this program ...".encode("ascii"))
                        server_stopEvent.set()
                    elif "Q?" in message:
                        infos = "Carrier Frequency: "+str(esbl.freq)+" MHz\n"
                        modulation_configs = esbl.get_modulation_config()
                        infos += "Modulation Frequency: "+str(modulation_configs[0])+" Hz\n"
                        infos += "Modulation Depth: "+str(modulation_configs[1])+" or equivalently "+str(modulation_configs[1]/255*3.14)+" rad\n"
                        infos += "IQ Phase Difference: "+str(modulation_configs[2])+" degrees\n"
                        infos += "I Amplitude: "+str(modulation_configs[3]*100)+" %\n"
                        infos += "Q Amplitude: "+str(modulation_configs[4]*100)+" %\n"
                        infos += "Reference Phase Offset: "+str(modulation_configs[5])+" degrees;"
                        client_socket.sendall(infos.encode("ascii"))
                    elif "CLDMA" in message:
                        esbl.dma_clear()
                        client_socket.sendall("DMA buffer deleted\n".encode("ascii"))
                    elif "STDMA" in message:
                        esbl.dma_init()
                        client_socket.sendall("DMA buffer reinitialized\n".encode("ascii"))
                    elif "CLLOG" in message:
                        with open("parser_error.txt", "w") as f:
                            f.write("")
                        client_socket.sendall("On board error log cleaned\n".encode("ascii"))
                    elif "RDLOG" in message:
                        with open("parser_error.txt", "r") as f:
                            content = f.read()
                        if not content:
                            content = "No existing error log"
                        else:
                            content = "On board error log:\n"+content
                        client_socket.sendall(content.encode("ascii"))
                    elif "HELP" in message:
                        help = "The available instructions are (notice the semicolons at the end of each command):\n\
        'FC xx;': Set the carrier frequency to xx Hz\n\
        'FM xx;': Set the modulation frequency to xx Hz\n\
        'PM xx;': Set the reference phase offset to xx degrees\n\
        'SA xx;': Set the I amplitude to xx %\n\
        'CA xx;': Set the Q amplitude to xx %\n\
        'SP xx;': Set the IQ phase difference to 90+xx degrees\n\
        'MD xx;': Set the modulation depth to xx; xx is a value between 0 and 255 mapping to the range of 0 to Pi\n\
        'AM xx;': Set the output current/amplitude. The default value is 0.625 and the recommend maximum is 1, but it can go upto 1.25\n\
        'ASC xx,yy,zz;': Asynchronous (Immediate) frequency scan from xx Hz to yy Hz with total zz steps; the step update rate is on average 0.34 us\n\
        'SSC xx,yy,zz;' (not finished): Synchronous (Triggered) frequency scan from xx Hz to yy Hz with total zz steps\n\
        'Q?;': Print the current modulation configurations\n\
        'CLDMA;': Delete the DMA buffer for frequency scans\n\
        'STDMA;': Reinitialize the DMA buffer for frequency scans; only needed if 'CLDMA' is applied\n\
        'CLLOG;': Clean the on board error log; the log file is named as 'parser_error.txt' located in the same directory as this program\n\
        'RDLOG;': Print the error log file on the board\n\
        'END;': End the on board program; you will need to ssh into the FPGA to restart it\n\
        'REBOOT;': Reboot the FPGA\n\
        'SHUTDOWN;': Shutdown the FPGA\n\
        'HELP;': Print this message\n\
        \nIf you encountered errors and received no response, please check the parser_error.txt file in the linux system."
                        client_socket.sendall(help.encode("ascii"))
                    else:
                        client_socket.sendall(("Unknown instruction: "+message+"\nSend 'HELP' for instruction list;").encode("ascii"))
        except ConnectionResetError:
            pass
        except Exception as e:
            with open("parser_error.txt", "a") as f:
                f.write("Instruction: "+str(data)+"\nError: "+str(e))
            client_socket.sendall(("Instruction: "+str(data)+"\nError: "+str(e)+";").encode("ascii"))
        finally:
            client_socket.close()



    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((host, port))
    server.listen(5)
    server.settimeout(1)

    try:
        while not server_stopEvent.is_set():
            try:
                client_socket, _ = server.accept()
                client_thread = threading.Thread(target=handle_client, args=(client_socket,))
                client_thread.daemon = True
                client_thread.start()
            except socket.timeout:
                continue
    finally:
        esbl.dma_clear()
        server.close()
        client_thread.join()



if __name__ == '__main__':
    start_server()