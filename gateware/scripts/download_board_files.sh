#!/bin/bash
wget https://github.com/RealDigitalOrg/RFSoC4x2-BSP/archive/refs/tags/v2020.2.zip
unzip v2020.2.zip
rm v2020.2.zip

wget https://www.realdigital.org/downloads/e23850bddecdda56892abcc2c83e15f5.zip
unzip e23850bddecdda56892abcc2c83e15f5.zip -d constraints
rm e23850bddecdda56892abcc2c83e15f5.zip

wget https://www.xilinx.com/content/dam/xilinx/support/packagefiles/zuppackages/xczu48drffve1156pkg.txt

# cd cd RFSoC4x2-BSP-2020.2
