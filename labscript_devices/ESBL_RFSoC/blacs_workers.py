from blacs.tab_base_classes import Worker
import socket

class ESBL_RFSoCWorker(Worker):

    def init(self):
        global h5py; import h5py 
        self.last_frequency = None
        self.defualt_freqstep = 1e4

    def program_manual(self, values):
        return {}

    def send_and_receive(self,message):
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.settimeout(1)
        client.connect((self.TCPIP_address, self.TCPIP_port))
        client.sendall((str(message)+";").encode())
        response = client.recv(4096).decode("ascii")
        client.close()
        return response

    def set_last_frequency(self,freq):
        self.last_frequency = freq

    def set_default_freqstep(self,freqstep):
        self.defualt_freqstep = freqstep

    def transition_to_buffered(self, device_name, h5_file, initial_values, fresh):
        with h5py.File(h5_file, 'r') as hdf5_file:
            group = hdf5_file['/devices/'+device_name]
            if 'esbl_programmed_ramp_list' in group:
                ramp_list = group['TABLE_DATA%i'%self.channel][:]
                if self.last_frequency == None:
                    response = self.send_and_receive("Q?")
                    if response[:2] == "E ":
                        raise Exception(response)
                    else:
                        _,response = response.split(":")
                        fc,_ = response.split("MHz")
                        startfreq = int(float(fc)*1e6)
                else:
                    startfreq = self.last_frequency

                msg = "SSC "+str(int(startfreq))+","
                for i in range(len(ramp_list)//2):
                    msg += str(int(ramp_list[2*i]))+","
                    freqstep = int(ramp_list[2*i+1])
                    if freqstep == 0:
                        freqstep = self.defualt_freqstep
                    msg += str(freqstep)+","
                msg = msg[:-1]
                response = self.send_and_receive(msg)
                self.last_frequency = ramp_list[-2]
                print(response)
        return {}

    def transition_to_manual(self):
        return True

    def shutdown(self):
        return

    def abort_buffered(self):
        return self.transition_to_manual()

    def abort_transition_to_buffered(self):
        return True
