# Editted from FunctionRunner by Oliver Tu, 06/2023                 #
#####################################################################
#                                                                   #
# /labscript_devices/ESBL_RFSoC/blacs_workers.py                       #
#                                                                   #
# Copyright 2019, Monash University and contributors                #
#                                                                   #
# This file is part of labscript_devices, in the labscript suite    #
# (see http://labscriptsuite.org), and is licensed under the        #
# Simplified BSD License. See the license.txt file in the root of   #
# the project for the full license.                                 #
#                                                                   #
#####################################################################
import os
import numpy as np
import labscript_utils.h5_lock
# import h5py
from blacs.tab_base_classes import Worker
import socket

class ESBL_RFSoCWorker(Worker):

    def init(self):
        global h5py; import h5py 
        self.last_frequency = None

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

    def transition_to_buffered(self, device_name, h5_file, initial_values, fresh):
        with h5py.File(h5_file, 'r') as hdf5_file:
            group = hdf5_file['/devices/'+device_name]
            if 'esbl_programmed_ramp_list' in group:
                ramp_list = group['TABLE_DATA%i'%self.channel][:]
                if ramp_list[2] == None:
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
                else:
                    startfreq = ramp_list[2]

                response = self.send_and_receive("ASC "+str(int(startfreq))+","+str(int(ramp_list[0]))+","+str(int(ramp_list[1])))
                self.last_frequency = ramp_list[0]
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
