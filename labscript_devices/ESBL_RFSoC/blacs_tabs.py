from blacs.device_base_class import DeviceTab
from blacs.tab_base_classes import MODE_MANUAL, define_state
import os
import socket
from qtutils.qt.QtCore import *
from qtutils.qt.QtGui import *
from qtutils.qt.QtWidgets import  QMessageBox
from qtutils import UiLoader

class ESBL_RFSoCTab(DeviceTab):
    def initialise_GUI(self):        
        self.default_TCPIP_port = 6750
        self.default_TCPIP_address = '192.168.2.99'
        self.default_stepsize = 1e4

        layout = self.get_tab_layout()
        ui_filepath = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'ESBL_RFSoC.ui')
        self.ui = UiLoader().load(ui_filepath)
        self.ui.FCLineEdit.textEdited.connect(self.rampFC)
        self.ui.FreqjumpPushButton.released.connect(self.setFC)
        self.ui.acquirePushButton.released.connect(self.acquireConfig)
        self.ui.freqStepPushButton.released.connect(self.setFreqStep)
        self.ui.configPushButton.released.connect(self.sendConfig)
        self.ui.rampPushButton.released.connect(self.sendAsyncRamp)
        self.ui.VOPPushButton.released.connect(self.setVOP)
        self.ui.DMAClsPushButton.released.connect(self.clearDMA)
        self.ui.DMAInitPushButton.released.connect(self.initDMA)
        self.ui.logGetPushButton.released.connect(self.getLog)
        self.ui.logClsPushButton.released.connect(self.clearLog)
        self.ui.endPushButton.released.connect(self.terminate)
        self.ui.helpPushButton.released.connect(self.help)
        self.ui.shutdownPushButton.released.connect(self.shutdown)
        self.ui.rebootPushButton.released.connect(self.reboot)
        self.ui.intClkPushButton.released.connect(self.setIntClk)
        self.ui.extClkPushButton.released.connect(self.setExtClk)
        self.ui.softwareTrigPushButton.released.connect(self.softwareTrig)
        self.ui.shutdownPushButton.setStyleSheet("background-color : rgb(255, 71, 26);border: 2px solid") 
        self.ui.rebootPushButton.setStyleSheet("background-color : rgb(255, 71, 26);border: 2px solid") 
        self.ui.endPushButton.setStyleSheet("background-color : rgb(255, 71, 26);border: 2px solid") 
        self.ui.helpPushButton.setStyleSheet("background-color : rgb(255, 153, 51);border: 2px solid") 

        layout.addWidget(self.ui)
        
        connection_object = self.settings['connection_table'].find_by_name(self.device_name)
        connection_table_properties = connection_object.properties
        
        try:
            self.TCPIP_port = connection_table_properties.get('TCPIP_port', None)
        except:
            self.TCPIP_port = self.default_TCPIP_port
        try:
            self.TCPIP_address = connection_table_properties.get('TCPIP_address', None)
        except:
            self.TCPIP_address = self.default_TCPIP_address
        
        self.acquireConfig()

    def initialise_workers(self):
        # Create and set the primary worker
        self.create_worker("main_worker",
                            'labscript_devices.ESBL_RFSoC.blacs_workers.ESBL_RFSoCWorker',
                            {'TCPIP_port':self.TCPIP_port,
                            'TCPIP_address': self.TCPIP_address})
        
        self.primary_worker = "main_worker"

        # Set the capabilities of this device
        self.supports_remote_value_check(False)
        self.supports_smart_programming(False) 

    @define_state(MODE_MANUAL, queue_state_indefinitely=True, delete_stale_states=True)
    def pass_current_freq(self,freq):
        self.current_freq = freq
        yield(self.queue_work(self.primary_worker, 'set_last_frequency',freq))

    @define_state(MODE_MANUAL, queue_state_indefinitely=True, delete_stale_states=True)
    def pass_freq_step(self,freqstep):
        self.default_stepsize = freqstep
        yield(self.queue_work(self.primary_worker, 'set_default_freqstep',freqstep))

    def send_and_receive(self,message):
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.settimeout(1)
            client.connect((self.TCPIP_address, self.TCPIP_port))
            client.sendall((str(message)+";").encode())
            response = client.recv(4096).decode("ascii")
            client.close()
        except Exception as e:
            response = "E "+str(e)
        return response

    def rampFC(self):
        try:
            message = int(self.ui.FCLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Carrier Frequency is not an integer.")
            return 
        received = self.send_and_receive("ASC "+str(self.current_freq)+","+str(message)+","+str(self.default_stepsize))
        self.pass_current_freq(message)
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(received)

    def setFC(self):
        try:
            message = int(self.ui.FreqjumpLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Carrier Frequency is not an integer.")
            return 
        received = self.send_and_receive("FC "+str(message))
        self.pass_current_freq(message)
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(received)
    
    def acquireConfig(self):
        received = self.send_and_receive("Q?;")
        if received[:2] == "E ":
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText(received)
            return
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(received)
        _,received = received.split(":")
        fc,received = received.split("MHz")
        fc = int(float(fc)*1e6)
        self.ui.FCLineEdit.setText(str(fc))
        _,received = received.split(":")
        fm,received = received.split("Hz")
        fm = int(fm)
        self.ui.FMLineEdit.setText(str(fm))
        _,received = received.split(":")
        depth,received = received.split("or")
        depth = int(depth)
        self.ui.MDLineEdit.setText(str(depth))
        _,received = received.split(":")
        sp,received = received.split("degrees")
        sp=float(sp)
        self.ui.SPLineEdit.setText(str(sp))
        _,received = received.split(":")
        sa,received = received.split("%")
        sa=float(sa)
        self.ui.SALineEdit.setText(str(sa))
        _,received = received.split(":")
        ca,received = received.split("%")
        ca=float(ca)
        self.ui.CALineEdit.setText(str(ca))
        _,received = received.split(":")
        pd,received = received.split("degrees")
        pd=float(pd)
        self.ui.PDLineEdit.setText(str(pd))
        self.pass_current_freq(fc)
        self.ui.freqStepLineEdit.setText(str(self.default_stepsize))

    def setFreqStep(self):
        try:
            message = int(self.ui.freqStepLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Frequency Ramp Step is not an integer.")
            return 
        self.pass_freq_step(message)
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText('Defulat Frequency Ramp Step set to '+str(message))

    def sendConfig(self):
        try:
            fm = self.ui.FMLineEdit.text().replace(" ","")
            if fm=="":
                fm=None
            else:
                fm = int(fm)
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Modulation Frequency is not an integer.")
            return 
        try:
            depth = self.ui.MDLineEdit.text().replace(" ","")
            if depth=="":
                depth=None
            else:
                depth = int(depth)
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Modulation Depth is not an integer.")
            return 
        try:
            sp = self.ui.SPLineEdit.text().replace(" ","")
            if sp=="":
                sp=None
            else:
                sp = float(sp)
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Modulation Phase is not a float.")
            return 
        try:
            sa = self.ui.SALineEdit.text().replace(" ","")
            if sa=="":
                sa=None
            else:
                sa = float(sa)/100
        except:
            self.ui.textBrowser.setStyleSheet('color: red') 
            self.ui.textBrowser.setText("Error: Modulation Amplitude is not a float.")
            return 
        try:
            ca = self.ui.CALineEdit.text().replace(" ","")
            if ca=="":
                ca=None
            else:
                ca = float(ca)/100
        except:
            self.ui.textBrowser.setStyleSheet('color: red') 
            self.ui.textBrowser.setText("Error: Carrier Amplitude is not a float.")
            return 
        try:
            pd = self.ui.PDLineEdit.text().replace(" ","")
            if pd=="":
                pd=None
            else:
                pd = float(pd)
        except:
            self.ui.textBrowser.setStyleSheet('color: red') 
            self.ui.textBrowser.setText("Error: Phase Difference is not a float.")
            return
        response = ""

        if fm:
            response += self.send_and_receive("FM "+str(fm))
            response += "\n"
        if depth:
            response += self.send_and_receive("MD "+str(depth))
            response += "\n"
        if sp:
            response += self.send_and_receive("SP "+str(sp))
            response += "\n"
        if sa:
            response += self.send_and_receive("SA "+str(sa))
            response += "\n"
        if ca:
            response += self.send_and_receive("CA "+str(ca))
            response += "\n"
        if pd:
            response += self.send_and_receive("PD "+str(pd))

        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)


    def sendAsyncRamp(self):
        try:
            startfreq = int(self.ui.rampStartLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Start Frequency is not an integer.")
            return 
        try:
            endfreq = int(self.ui.rampEndLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: End Frequency is not an integer.")
            return 
        try:
            stepnum = int(self.ui.rampNumLineEdit.text())
            if stepnum < 1:
                raise ValueError
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: Ramp Step Number is not a positive integer.")
            return 
        response = self.send_and_receive("ASC "+str(startfreq)+","+str(endfreq)+","+str(stepnum))
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)
        self.pass_current_freq(endfreq)

    def setVOP(self):
        try:
            vop = int(self.ui.VOPLineEdit.text())
        except:
            self.ui.textBrowser.setStyleSheet('color: red')
            self.ui.textBrowser.setText("Error: VOP is not an integer.")
            return 
        response = self.send_and_receive("VOP "+str(vop))
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def clearDMA(self):
        response = self.send_and_receive("CLDMA")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def initDMA(self):
        response = self.send_and_receive("STDMA")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def getLog(self):
        response = self.send_and_receive("RDLOG")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def clearLog(self):
        response = self.send_and_receive("CLLOG")
        self.ui.textBrowser.setStyleSheet('color: black')

    def help(self):
        response = self.send_and_receive("HELP")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def terminate(self):
        msg = QMessageBox()
        msg.setText("Be careful! This command will terminate the on board program.")
        msg.setIcon(QMessageBox.Warning)
        msg.setStandardButtons(QMessageBox.Cancel|QMessageBox.Ok)
        msg.setDefaultButton(QMessageBox.Cancel)
        msg.setInformativeText("You will need to access the board through ssh to restart it.")
        def terminate_check(i):
            if i.text() == "Ok" or i.text() == "OK":
                response = self.send_and_receive("END")
                self.ui.textBrowser.setStyleSheet('color: black')
                self.ui.textBrowser.setText(response)
        msg.buttonClicked.connect(terminate_check)
        msg.exec()
                
    def shutdown(self):
        msg = QMessageBox()
        msg.setText("Be careful! This command will terminate the on board program.")
        msg.setIcon(QMessageBox.Warning)
        msg.setStandardButtons(QMessageBox.Cancel|QMessageBox.Ok)
        msg.setDefaultButton(QMessageBox.Cancel)
        msg.setInformativeText("You will need to access the hardware and software of the RFSoC to restart it.")
        def shutdown_check(i):
            if i.text() == "Ok" or i.text() == "OK":
                response = self.send_and_receive("SHUTDOWN")
                self.ui.textBrowser.setStyleSheet('color: black')
                self.ui.textBrowser.setText(response)
        msg.buttonClicked.connect(shutdown_check)
        msg.exec()

    def reboot(self):
        msg = QMessageBox()
        msg.setText("Be careful! This command will terminate the on board program.")
        msg.setIcon(QMessageBox.Warning)
        msg.setStandardButtons(QMessageBox.Cancel|QMessageBox.Ok)
        msg.setDefaultButton(QMessageBox.Cancel)
        msg.setInformativeText("You may lose your laser lock by rebooting the RFSoC board.")
        def reboot_check(i):
            if i.text() == "Ok" or i.text() == "OK":
                response = self.send_and_receive("REBOOT")
                self.ui.textBrowser.setStyleSheet('color: black')
                self.ui.textBrowser.setText(response)
        msg.buttonClicked.connect(reboot_check)
        msg.exec()

    def setIntClk(self):
        response = self.send_and_receive("INTCLK")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)
    
    def setExtClk(self):
        response = self.send_and_receive("EXTCLK")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)

    def softwareTrig(self):
        response = self.send_and_receive("STR")
        self.ui.textBrowser.setStyleSheet('color: black')
        self.ui.textBrowser.setText(response)