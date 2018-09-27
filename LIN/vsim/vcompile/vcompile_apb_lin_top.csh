#!/bin/tcsh
source ${PULP_PATH}/./vsim/vcompile/setup.csh

##############################################################################
# Settings
##############################################################################

set IP=apb_lin_top

##############################################################################
# Check settings
##############################################################################

# check if environment variables are defined
if (! $?MSIM_LIBS_PATH ) then
  echo "${Red} MSIM_LIBS_PATH is not defined ${NC}"
  exit 1
endif

if (! $?IPS_PATH ) then
  echo "${Red} IPS_PATH is not defined ${NC}"
  exit 1
endif

set LIB_NAME="${IP}_lib"
set LIB_PATH="${MSIM_LIBS_PATH}/${LIB_NAME}"
set IP_PATH="${IPS_PATH}/apb/apb_lin_top"
set RTL_PATH="${RTL_PATH}"

##############################################################################
# Preparing library
##############################################################################

echo "${Green}--> Compiling ${IP}... ${NC}"

rm -rf $LIB_PATH

vlib $LIB_PATH
vmap $LIB_NAME $LIB_PATH

##############################################################################
# Compiling RTL
##############################################################################

echo "${Green}Compiling component: ${Brown} apb_lin_top ${NC}"
echo "${Red}"
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/apb_lin_top.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/apb_mem_converter.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/top.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/memory.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/memory2.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/register_file.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/app_layer_slave1.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/brk_seq_det.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/checksum.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/collision_table.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/data_memory.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/event_trig_frame.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/headder_creation.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/lin_top_module.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/lin_top_module_tb.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Master_controller.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/master_top.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/parity_comp.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/PID_detector.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/rx_checksum.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/schedule_table.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/schedule_table_ROM.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Slave_controller.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Slave_RAM.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Slave_ROM.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Slave_rx.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/slave_sub_rx.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/Slave_Top.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/clock_divider.v || goto error
vlog -quiet -sv -suppress 2583 -work ${LIB_PATH}     ${IP_PATH}/top2.v || goto error



echo "${Cyan}--> ${IP} compilation complete! ${NC}"
exit 0

##############################################################################
# Error handler
##############################################################################

error:
echo "${NC}"
exit 1
