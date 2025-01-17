from labscript import Device,set_passed_properties

class ESBL_RFSoC(Device):

    @set_passed_properties(
        property_names={
            'connection_table_properties': [
                'TCPIP_port',
                'TCPIP_address',
            ]
        }
    )
    def __init__(self, name,TCPIP_port,TCPIP_address,**kwargs):
        Device.__init__(self, name=name, parent_device=None, connection=None, **kwargs)
        self.BLACS_connection = name
        self.programmed_ramp_list = []

    def rampto(self, destination_freq, stepsize=0):
        self.programmed_ramp_list.append(destination_freq)
        self.programmed_ramp_list.append(stepsize)


    def generate_code(self, hdf5_file):
        group = self.init_device_group(hdf5_file)
        if self.programmed_ramp_list != []:
            group.create_dataset('esbl_programmed_ramp_list',data=self.programmed_ramp_list)
            self.programmed_ramp_list = []
