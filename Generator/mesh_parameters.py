#! /usr/bin/python

"""
Generates a dict of all Verilog parameters for a specific Mesh instance.
Many parameters are calculated from others.
"""

import string

import parameters_misc
import misc
import cpu_parameters

def generate_common_values(parameters = {}):
    common_values = { 
        ## Degenerate case: 1x1 mesh same as a single Octavo core, with dummy pipeline buffers around it.
        "MESH_LINE_NODE_COUNT" : 1,
        "MESH_LINE_EDGE_PIPE_DEPTH" : 0,
        "MESH_LINE_NODE_PIPE_DEPTH" : 0,

        "MESH_PAGE_LINE_COUNT" : 1,
        "MESH_PAGE_EDGE_PIPE_DEPTH" : 0,
        "MESH_PAGE_NODE_PIPE_DEPTH" : 0,
    }
    parameters_misc.override(common_values, parameters) 
    return common_values

def generate_partition_options(parameters = {}):
    partition_options = {
        "PARTITION_MESH_NODES" : False,
        "PARTITION_MESH_PIPES" : False}
    parameters_misc.override(partition_options, parameters)
    return partition_options

def generate_mesh_name(all_parameters):
    """You can do fancy naming here by refering to parameter names in the template: e.g. ${WORD_WIDTH}"""
    name_template = string.Template("${CPU_NAME}x${WORD_WIDTH}_A${A_IO_READ_PORT_COUNT}i${A_IO_WRITE_PORT_COUNT}o_B${B_IO_READ_PORT_COUNT}i${B_IO_WRITE_PORT_COUNT}o_SIMD${SIMD_LAYER_COUNT}x${SIMD_LANES_PER_LAYER}x${SIMD_WORD_WIDTH}_Mesh${MESH_LINE_NODE_COUNT}x${MESH_PAGE_LINE_COUNT}")
    name = name_template.substitute(all_parameters)
    return {"MESH_NAME":name}


def all_parameters(parameters = {}):
    all_parameters = {}

    ## The cpu and mesh parameters don't depend on eachother for now
    cpu = cpu_parameters.all_parameters(parameters)
    all_parameters.update(cpu)

    common_values = generate_common_values(parameters)
    all_parameters.update(common_values)

    partitions = generate_partition_options(parameters)
    all_parameters.update(partitions)

    mesh_name = generate_mesh_name(all_parameters)
    all_parameters.update(mesh_name)
    return all_parameters

if __name__ == "__main__":
    import pprint
    pprint.pprint(all_parameters()) 
    ## pprint.pprint(all_parameters(parameters = {"PORTS_COUNT":5, "WORD_WIDTH":23})) 


