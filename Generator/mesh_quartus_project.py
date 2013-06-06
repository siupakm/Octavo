
import string
import random

import misc

install_base = misc.base_install_path()

def create_project_file(all_parameters, path):
    """Create a minimal .qpf file."""
    qpf_template = string.Template(
"""
PROJECT_REVISION = "${PROJECT_NAME}"
""")
    qpf = qpf_template.substitute(all_parameters)
    project_name = all_parameters["PROJECT_NAME"]
    misc.write_file(path, project_name + ".qpf", qpf)


def create_SIMD_lane_partition(all_parameters, layer_number, lane_number, path_color, path_id, is_last_layer = False):
    """Creates one design partition entry for a lane in the last layer."""
    dp_template = string.Template(
"""        # start DESIGN_PARTITION(DataPath:Lanes_${LAYER}_${LANE}
        # -------------------------------------------------------
        set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id "DataPath:Lanes_${LAYER}_${LANE}" 
        set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "DataPath:Lanes_${LAYER}_${LANE}" 
        set_global_assignment -name PARTITION_COLOR ${PATH_COLOR} -section_id "DataPath:Lanes_${LAYER}_${LANE}" 
        set_instance_assignment -name PARTITION_HIERARCHY lanes_${PATH_ID} -to "${CPU_NAME}:DUT|Octavo:Octavo|${LAYER_TYPE}|DataPath:Lanes[${LANE}]" -section_id "DataPath:Lanes_${LAYER}_${LANE}"
        # end DESIGN_PARTITION(DataPath:Lanes_${LAYER}_${LANE})
        # -----------------------------------------------------
""")
    if (is_last_layer == False):
        layer_type = "SIMD:SIMD_Layers.Layers[" + str(layer_number) + "]"
    else:
        layer_type = "SIMD:SIMD_Layer_last.Layer_last"
    all_parameters.update({"LAYER"      : layer_number,
                           "LAYER_TYPE" : layer_type,
                           "LANE"       : lane_number,
                           "PATH_COLOR" : path_color,
                           "PATH_ID"    : path_id})
    dp = dp_template.substitute(all_parameters)
    return dp

def create_SIMD_passthru_lane_partition(all_parameters, layer_number, path_color, path_id, is_last_layer = False):
    """Creates one design partition entry for the passthru lane in the last layer."""
    dp_template = string.Template(
"""        # start DESIGN_PARTITION(DataPath:Lane_Passthru_${LAYER}
        # -------------------------------------------------------
        set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id "DataPath:Lane_Passthru_${LAYER}" 
        set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "DataPath:Lane_Passthru_${LAYER}" 
        set_global_assignment -name PARTITION_COLOR ${PATH_COLOR} -section_id "DataPath:Lane_Passthru_${LAYER}" 
        set_instance_assignment -name PARTITION_HIERARCHY lanes_${PATH_ID} -to "${CPU_NAME}:DUT|Octavo:Octavo|${LAYER_TYPE}|DataPath:Lane_Passthru" -section_id "DataPath:Lane_Passthru_${LAYER}"
        # end DESIGN_PARTITION(DataPath:Lane_Passthru_${LAYER})
        # -----------------------------------------------------
""")
    if (is_last_layer == False):
        layer_type = "SIMD:SIMD_Layers.Layers[" + str(layer_number) + "]"
    else:
        layer_type = "SIMD:SIMD_Layer_last.Layer_last"
    all_parameters.update({"LAYER"      : layer_number,
                           "LAYER_TYPE" : layer_type,
                           "PATH_COLOR" : path_color,
                           "PATH_ID"    : path_id})
    dp = dp_template.substitute(all_parameters)
    return dp

def random_20bit_hex():
    rnd = random.getrandbits(20)
    return hex(rnd)[2:-1] # chop '0x' and 'L', leaving bare number

def random_color():
    return abs(int(random.getrandbits(24)))

def create_SIMD_partitions_all(all_parameters, layer_count, lanes_per_layer):
    partitions = []
    layers = range(0, layer_count)
    lanes = range(0, lanes_per_layer-1)
    for layer in layers:
        if(layer == layer_count-1):
            is_last_layer = True
        else:
            is_last_layer = False
        partition = create_SIMD_passthru_lane_partition(all_parameters, layer, random_color(), random_20bit_hex(), is_last_layer)
        partitions.append(partition)
        for lane in lanes:
            partition = create_SIMD_lane_partition(all_parameters, layer, lane, random_color(), random_20bit_hex(), is_last_layer)
            partitions.append(partition)
    return "\n".join(partitions)

def create_Scalar_partition(all_parameters):
    color = random_color()
    partition_id = random_20bit_hex()
    dp_template = string.Template(
"""	       # start DESIGN_PARTITION(Scalar:Scalar)
	# -------------------------------------
		set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id "Scalar:Scalar"
		set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "Scalar:Scalar"
		set_global_assignment -name PARTITION_COLOR ${COLOR} -section_id "Scalar:Scalar"
		set_instance_assignment -name PARTITION_HIERARCHY scala_${ID} -to "${CPU_NAME}:DUT|Octavo:Octavo|Scalar:Scalar" -section_id "Scalar:Scalar"
	# end DESIGN_PARTITION(Scalar:Scalar)
	# -----------------------------------
""")
    all_parameters.update({"COLOR"  : color,
                           "ID"     : partition_id})
    dp = dp_template.substitute(all_parameters)
    return dp

def create_settings_file(all_parameters, path, install_base = install_base):
    """Create a .qsf file with all the necessary initial settings."""
    qsf_template = string.Template(
"""
# Project-Wide Assignments
# ========================
set_global_assignment -name LAST_QUARTUS_VERSION 12.1
set_global_assignment -name FLOW_DISABLE_ASSEMBLER ON
set_global_assignment -name SMART_RECOMPILE ON
set_global_assignment -name NUM_PARALLEL_PROCESSORS ${QUARTUS_NUM_PARALLEL_PROCESSORS}
set_global_assignment -name SDC_FILE ${install_base}/Octavo/Misc/timing.sdc
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/Misc/params.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/Misc/delay_line.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/ALU/AddSub/AddSub_Carry_Select.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/ALU/AddSub/AddSub_Ripple_Carry.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/ALU/Multiplier/Mult.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/ALU/Bitwise/Bitwise.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/ALU/ALU.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/DataPath/DataPath.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/ControlPath/Controller/Controller.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/ControlPath/Instr_Decoder/Instr_Decoder.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/ControlPath/ControlPath.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/Memory/Memory.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/Octavo.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/SIMD.v
set_global_assignment -name VERILOG_FILE ${install_base}/Octavo/Scalar.v
set_global_assignment -name VERILOG_FILE ${install_base}/Harness/output_register.v
set_global_assignment -name VERILOG_FILE ${install_base}/Harness/shift_register.v
set_global_assignment -name VERILOG_FILE ${install_base}/Harness/registered_reducer.v
set_global_assignment -name VERILOG_FILE ../${CPU_NAME}.v
set_global_assignment -name VERILOG_FILE ${PROJECT_NAME}.v
set_global_assignment -name FLOW_ENABLE_RTL_VIEWER OFF

# Classic Timing Assignments
# ==========================
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS OFF
set_global_assignment -name TIMEQUEST_DO_REPORT_TIMING ON

# Analysis & Synthesis Assignments
# ================================
set_global_assignment -name FAMILY "${FAMILY}"
set_global_assignment -name TOP_LEVEL_ENTITY ${PROJECT_NAME}
set_global_assignment -name DEVICE_FILTER_SPEED_GRADE FASTEST
set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
set_global_assignment -name ADV_NETLIST_OPT_SYNTH_WYSIWYG_REMAP ON
set_global_assignment -name AUTO_SHIFT_REGISTER_RECOGNITION OFF
set_global_assignment -name REMOVE_REDUNDANT_LOGIC_CELLS ON
set_global_assignment -name MUX_RESTRUCTURE ON
set_global_assignment -name ALLOW_ANY_ROM_SIZE_FOR_RECOGNITION ON
set_global_assignment -name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON
set_global_assignment -name ALLOW_ANY_SHIFT_REGISTER_SIZE_FOR_RECOGNITION OFF
set_global_assignment -name AUTO_RAM_RECOGNITION ON
set_global_assignment -name AUTO_RAM_TO_LCELL_CONVERSION OFF
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
set_global_assignment -name USE_LOGICLOCK_CONSTRAINTS_IN_BALANCING ON
set_global_assignment -name SAVE_DISK_SPACE OFF
set_global_assignment -name REMOVE_DUPLICATE_REGISTERS ON

# Fitter Assignments
# ==================
set_global_assignment -name DEVICE ${DEVICE}
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name OPTIMIZE_IOC_REGISTER_PLACEMENT_FOR_TIMING OFF
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
set_global_assignment -name PHYSICAL_SYNTHESIS_EFFORT EXTRA
set_global_assignment -name ROUTER_LCELL_INSERTION_AND_LOGIC_DUPLICATION ON
set_global_assignment -name ROUTER_TIMING_OPTIMIZATION_LEVEL MAXIMUM
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA OFF
set_global_assignment -name AUTO_PACKED_REGISTERS_STRATIXII AUTO
set_global_assignment -name ROUTER_CLOCKING_TOPOLOGY_ANALYSIS OFF
set_global_assignment -name PHYSICAL_SYNTHESIS_MAP_LOGIC_TO_MEMORY_FOR_AREA OFF
set_global_assignment -name BLOCK_RAM_TO_MLAB_CELL_CONVERSION OFF
set_global_assignment -name SEED 1
set_global_assignment -name PLACEMENT_EFFORT_MULTIPLIER 4
set_global_assignment -name ROUTER_EFFORT_MULTIPLIER 4
set_global_assignment -name AUTO_DELAY_CHAINS OFF
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS"

# Design Assistant Assignments
# ============================
set_global_assignment -name ENABLE_DA_RULE "C101, C102, C103, C104, C105, C106, R101, R102, R103, R104, R105, T101, T102, A101, A102, A103, A104, A105, A106, A107, A108, A109, A110, S101, S102, S103, S104, D101, D102, D103, M101, M102, M103, M104, M105"
set_global_assignment -name ENABLE_DRC_SETTINGS ON

# Power Estimation Assignments
# ============================
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"

# Incremental Compilation Assignments
# ===================================
set_global_assignment -name RAPID_RECOMPILE_MODE OFF

# Netlist Viewer Assignments
# ==========================
set_global_assignment -name RTLV_GROUP_COMB_LOGIC_IN_CLOUD_TMV OFF

# -----------------------------------
# start ENTITY(${PROJECT_NAME})

#	# start LOGICLOCK_REGION(${MESH_NAME}:DUT)
#	# ------------------------------------
#
#		# LogicLock Region Assignments
#		# ============================
#		set_global_assignment -name LL_ENABLED ON -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_RESERVED ON -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_SECURITY_ROUTING_INTERFACE OFF -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_IGNORE_IO_BANK_SECURITY_CONSTRAINT OFF -section_id "${MESH_NAME}:DUT"
#		set_instance_assignment -name LL_MEMBER_OF "${MESH_NAME}:DUT" -to "${MESH_NAME}:DUT" -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_PR_REGION OFF -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_HEIGHT 14 -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_WIDTH 16 -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_ORIGIN X66_Y46 -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_STATE FLOATING -section_id "${MESH_NAME}:DUT"
#		set_global_assignment -name LL_AUTO_SIZE ON -section_id "${MESH_NAME}:DUT"
#
#	# end LOGICLOCK_REGION(${MESH_NAME}:DUT)
#	# ----------------------------------
#
#	# start LOGICLOCK_REGION(Root Region)
#	# -----------------------------------
#
#		# LogicLock Region Assignments
#		# ============================
#		set_global_assignment -name LL_ROOT_REGION ON -section_id "Root Region"
#		set_global_assignment -name LL_MEMBER_STATE LOCKED -section_id "Root Region"
#
#	# end LOGICLOCK_REGION(Root Region)
#	# ---------------------------------

	# start DESIGN_PARTITION(Top)
	# ---------------------------

		# Incremental Compilation Assignments
		# ===================================
		set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
		set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
		set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
		set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# end DESIGN_PARTITION(Top)
	# -------------------------

	# start DESIGN_PARTITION(${MESH_NAME}:DUT)
	# ------------------------------------

		# Incremental Compilation Assignments
		# ===================================
		set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id "${MESH_NAME}:DUT"
		set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id "${MESH_NAME}:DUT"
		set_global_assignment -name PARTITION_COLOR 39423 -section_id "${MESH_NAME}:DUT"
		set_instance_assignment -name PARTITION_HIERARCHY dut_2ae21 -to "${MESH_NAME}:DUT" -section_id "${MESH_NAME}:DUT"

	# end DESIGN_PARTITION(${MESH_NAME}:DUT)
	# ----------------------------------


${SCALAR_PARTITION}
${SIMD_PARTITIONS}

# end ENTITY(${PROJECT_NAME})
# ---------------------------------
""")
    all_parameters["install_base"] = install_base
    
    #if all_parameters["PARTITION_SCALAR"] == True:
    #    scalar_module_partition = create_Scalar_partition(all_parameters)
    #else:
    scalar_module_partition = ""

    # Matches conditional generation in Octavo.v
    #SIMD_layer_count     = all_parameters["SIMD_LAYER_COUNT"]
    #SIMD_lanes_per_layer = all_parameters["SIMD_LANES_PER_LAYER"]
    #SIMD_lanes           = all_parameters["SIMD_LANE_COUNT"]
    #if all_parameters["PARTITION_SIMD_LANES"] == True and SIMD_lanes > 0:
    #    simd_partitions = create_SIMD_partitions_all(all_parameters, SIMD_layer_count, SIMD_lanes_per_layer)
    #else:
    simd_partitions = ""

    all_parameters.update({"SCALAR_PARTITION":scalar_module_partition})
    all_parameters.update({"SIMD_PARTITIONS":simd_partitions})
    qsf = qsf_template.substitute(all_parameters)
    project_name = all_parameters["PROJECT_NAME"]
    misc.write_file(path, project_name + ".qsf", qsf)

#def create_stub_mem_init_files(all_parameters, path):
#    misc.write_file(path, all_parameters["A_INIT_FILE"].strip('"'),  "")
#    misc.write_file(path, all_parameters["B_INIT_FILE"].strip('"'),  "")
#    misc.write_file(path, all_parameters["I_INIT_FILE"].strip('"'),  "")
#    misc.write_file(path, all_parameters["PC_INIT_FILE"].strip('"'), "")

def project(all_parameters, path):
    create_project_file(all_parameters, path)
    create_settings_file(all_parameters, path)
#    create_stub_mem_init_files(all_parameters, path)

