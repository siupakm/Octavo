#! /usr/bin/python

import os
import sys

import misc
import parameters_misc
import mesh_parameters 
import mesh_definition
import mesh_test_harness
import mesh_test_bench

def mesh(parameters = {}):
    all_parameters = mesh_parameters.all_parameters(parameters)
    definition     = mesh_definition.definition(all_parameters)
    name           = all_parameters["MESH_NAME"]
    mesh_dir        = os.path.join(os.getcwd(), name)
    misc.write_file(mesh_dir, name + ".v", definition)
    parameters_misc.write_parameter_file(mesh_dir, 
                                         name, 
                                         all_parameters)
    os.chdir(mesh_dir)
    mesh_test_harness.main(all_parameters)
    mesh_test_bench.main(all_parameters)
    return name

if __name__ == "__main__":
    parameters = parameters_misc.parse_cmdline(sys.argv[1:])
    instance = mesh(parameters)
    print instance

