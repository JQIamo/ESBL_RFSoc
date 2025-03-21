from labscript import TriggerableDevice,set_passed_properties

class ESBL_RFSoC(TriggerableDevice):

    @set_passed_properties(
        property_names={
            'connection_table_properties': [
                'TCPIP_port',
                'TCPIP_address',
            ]
        }
    )
    def __init__(self, name,parent_device,TCPIP_address,TCPIP_port,**kwargs):
        TriggerableDevice.__init__(self, name=name, parent_device=parent_device, connection=0, **kwargs)
        self.BLACS_connection = name
        self.programmed_ramp_list = []

    def rampto(self,t, destination_freq, stepsize=0):
        self.programmed_ramp_list.append(destination_freq)
        self.programmed_ramp_list.append(stepsize)
        self.trigger_device.trigger(t, 1e-7)


    def generate_code(self, hdf5_file):
        group = self.init_device_group(hdf5_file)
        if self.programmed_ramp_list != []:
            group.create_dataset('esbl_programmed_ramp_list',data=self.programmed_ramp_list)
            self.programmed_ramp_list = []
