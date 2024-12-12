# Setting up useful variables

#VIVADO = vivado -nojournal -mode batch
VIVADO = vivado
RFSOC_SSH_ADDRESS = xilinx@192.168.2.99


.PHONY: clean build flash write explain
.SILENT: explain



explain:
	#the default behavior is to explain how to use make
	echo "These commands are available:"
	echo "   make build: synthesizes the project file"
	echo "   make deploy: saves bit and hwh in RFSoC /home/xilinx folder"
	echo "   make clean: deletes the build folder and all Vivado logs and"
	echo "         journals"

clean:
	#rm -rf build
	rm *.log
	rm *.jou


download:
	./scripts/download_board_files.sh 

build:
	vivado -source ./scripts/setup_project.tcl

deploy:
	scp ./ESBL_RFSoC/ESBL_RFSoC.gen/sources_1/bd/main/hw_handoff/main.hwh ${RFSOC_SSH_ADDRESS}:/home/xilinx
	scp ./ESBL_RFSoC/ESBL_RFSoC.runs/impl_1/main_wrapper.bit ${RFSOC_SSH_ADDRESS}:/home/xilinx/main.bit
