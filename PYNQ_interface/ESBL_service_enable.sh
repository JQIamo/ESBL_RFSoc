#!/bin/bash
sudo cp ESBL_startup.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ESBL_startup.service
