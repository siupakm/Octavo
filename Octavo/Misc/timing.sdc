
##
## DEVICE  "EP4SE230F29C2"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************

# 550 MHz, max rated speed for M9K Block RAMs on C2 speed grade Stratix IV
create_clock -name {clock} -period 1.818 -waveform { 0.000 0.909 } [get_ports {clock}]
# 275 MHz half-rate clock use in Multiplier. There is no point in making this any faster than clock/2
create_generated_clock -divide_by 2 -source [get_ports clock] -name half_clock [get_ports half_clock]

#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

# This seems to work better than what TimeQuest generates.
derive_clock_uncertainty

#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************

# Set max delay for data transfers between clock domains.
# This allows TimeQuest to properly analyse them, since half_clock latches on both edges.
# See clock definitions above for delay value to use
set_max_delay -rise_from [get_clocks clock] -to [get_clocks half_clock] 1.818
set_max_delay -from [get_clocks half_clock] -rise_to [get_clocks clock] 1.818 

#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

