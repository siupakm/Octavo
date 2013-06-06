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
    name_template = string.Template("${CPU_NAME}_Mesh${MESH_LINE_NODE_COUNT}x${MESH_PAGE_LINE_COUNT}")
    name = name_template.substitute(all_parameters)
    return {"MESH_NAME":name}


def all_parameters(parameters = {}):
    all_parameters = {}

    # A rectangular mesh needs exactly 2 each of A and B ports
    assert "PORTS_COUNT" not in parameters.keys(), "You can't change the PORTS_COUNT of a Mesh. It's always 2. Leave it alone."
    parameters.update({"PORTS_COUNT" : 2})
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


