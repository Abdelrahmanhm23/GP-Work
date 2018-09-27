#!/bin/bash
rm /home/waleed/pulpino/pulpino/sw/build/apps/my_apps/lin/modelsim.ini
echo "modelsim deleted"
make lin
make vcompile
make lin.vsim
