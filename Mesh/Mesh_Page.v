// A Mesh_Page, connecting a number of Mesh_Lines transversally.
// This code assumes a Line has two B ports (B0, B1) at each end, and pairs of A ports (A0, A1) along the edge, one pair per Mesh node.
// The number of read and write ports, and their widths, must match.
// Based on Mesh_Node_Line.v
// Ports B0,B1 go right-to-left,left-to-right respectively, and ports A0,A1 follow the same convention but rotated clockwise 90deg: bottom-to-top,top-to-bottom.
// Note the directions have no actual spatial meaning. They only exist relative to eachother and denote direction of data communications between nodes.

module Mesh_Page
#(
    parameter       ALU_WORD_WIDTH                  = 0,
    parameter       SIMD_ALU_WORD_WIDTH             = 0,

    parameter       INSTR_WIDTH                     = 0,
    parameter       OPCODE_WIDTH                    = 0,
    parameter       D_OPERAND_WIDTH                 = 0,
    parameter       A_OPERAND_WIDTH                 = 0,
    parameter       B_OPERAND_WIDTH                 = 0,

    parameter       A_WORD_WIDTH                    = 0,
    parameter       A_ADDR_WIDTH                    = 0,
    parameter       A_DEPTH                         = 0,
    parameter       A_RAMSTYLE                      = "",
    parameter       A_INIT_FILE                     = "",
    parameter       A_IO_READ_PORT_COUNT            = 0,
    parameter       A_IO_READ_PORT_BASE_ADDR        = 0,
    parameter       A_IO_READ_PORT_ADDR_WIDTH       = 0,
    parameter       A_IO_WRITE_PORT_COUNT           = 0,
    parameter       A_IO_WRITE_PORT_BASE_ADDR       = 0,
    parameter       A_IO_WRITE_PORT_ADDR_WIDTH      = 0,

    parameter       SIMD_A_WORD_WIDTH               = 0,
    parameter       SIMD_A_ADDR_WIDTH               = 0,
    parameter       SIMD_A_DEPTH                    = 0,
    parameter       SIMD_A_RAMSTYLE                 = "",
    parameter       SIMD_A_INIT_FILE                = "",
    parameter       SIMD_A_IO_READ_PORT_COUNT       = 0,
    parameter       SIMD_A_IO_READ_PORT_BASE_ADDR   = 0,
    parameter       SIMD_A_IO_READ_PORT_ADDR_WIDTH  = 0,
    parameter       SIMD_A_IO_WRITE_PORT_COUNT      = 0,
    parameter       SIMD_A_IO_WRITE_PORT_BASE_ADDR  = 0,
    parameter       SIMD_A_IO_WRITE_PORT_ADDR_WIDTH = 0,

    parameter       B_WORD_WIDTH                    = 0,
    parameter       B_ADDR_WIDTH                    = 0,
    parameter       B_DEPTH                         = 0,
    parameter       B_RAMSTYLE                      = "",
    parameter       B_INIT_FILE                     = "",
    parameter       B_IO_READ_PORT_COUNT            = 0,
    parameter       B_IO_READ_PORT_BASE_ADDR        = 0,
    parameter       B_IO_READ_PORT_ADDR_WIDTH       = 0,
    parameter       B_IO_WRITE_PORT_COUNT           = 0,
    parameter       B_IO_WRITE_PORT_BASE_ADDR       = 0,
    parameter       B_IO_WRITE_PORT_ADDR_WIDTH      = 0,

    parameter       SIMD_B_WORD_WIDTH               = 0,
    parameter       SIMD_B_ADDR_WIDTH               = 0,
    parameter       SIMD_B_DEPTH                    = 0,
    parameter       SIMD_B_RAMSTYLE                 = "",
    parameter       SIMD_B_INIT_FILE                = "",
    parameter       SIMD_B_IO_READ_PORT_COUNT       = 0,
    parameter       SIMD_B_IO_READ_PORT_BASE_ADDR   = 0,
    parameter       SIMD_B_IO_READ_PORT_ADDR_WIDTH  = 0,
    parameter       SIMD_B_IO_WRITE_PORT_COUNT      = 0,
    parameter       SIMD_B_IO_WRITE_PORT_BASE_ADDR  = 0,
    parameter       SIMD_B_IO_WRITE_PORT_ADDR_WIDTH = 0,

    parameter       I_WORD_WIDTH                    = 0,
    parameter       I_ADDR_WIDTH                    = 0,
    parameter       I_DEPTH                         = 0,
    parameter       I_RAMSTYLE                      = "",
    parameter       I_INIT_FILE                     = "",

    parameter       PC_RAMSTYLE                     = "",
    parameter       PC_INIT_FILE                    = "",
    parameter       THREAD_COUNT                    = 0, 
    parameter       THREAD_ADDR_WIDTH               = 0, 

    parameter       PC_PIPELINE_DEPTH               = 0,
    parameter       I_TAP_PIPELINE_DEPTH            = 0,
    parameter       TAP_AB_PIPELINE_DEPTH           = 0,
    parameter       I_PASSTHRU_PIPELINE_DEPTH       = 0,
    parameter       AB_READ_PIPELINE_DEPTH          = 0,

    parameter       SIMD_I_PASSTHRU_PIPELINE_DEPTH  = 0,
    parameter       SIMD_TAP_AB_PIPELINE_DEPTH      = 0,

    parameter       AB_ALU_PIPELINE_DEPTH           = 0,
    parameter       LOGIC_OPCODE_WIDTH              = 0,

    parameter       ADDSUB_CARRY_SELECT             = 0,
    parameter       MULT_DOUBLE_PIPE                = 0,
    parameter       MULT_HETEROGENEOUS              = 0,    
    parameter       MULT_USE_DSP                    = 0,

    parameter       SIMD_ADDSUB_CARRY_SELECT        = 0,
    parameter       SIMD_MULT_DOUBLE_PIPE           = 0,
    parameter       SIMD_MULT_HETEROGENEOUS         = 0,    
    parameter       SIMD_MULT_USE_DSP               = 0,

    parameter       SIMD_LAYER_COUNT                = 0,
    parameter       SIMD_LANES_PER_LAYER            = 0,

    parameter       MESH_LINE_NODE_COUNT            = 0,
    parameter       MESH_LINE_EDGE_PIPE_DEPTH       = 0,
    parameter       MESH_LINE_NODE_PIPE_DEPTH       = 0,

    parameter       MESH_PAGE_LINE_COUNT            = 0,
    parameter       MESH_PAGE_EDGE_PIPE_DEPTH       = 0,
    parameter       MESH_PAGE_NODE_PIPE_DEPTH       = 0
)
(
    input   wire                                                                                                                                                                       clock,
    input   wire                                                                                                                                                                       half_clock,

    // Memory write enables for external control by accelerators
    input   wire    [(MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT)-1:0]                                                                                                                I_wren_other,
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * (MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT))-1:0]                                                            A_wren_other,
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * (MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT))-1:0]                                                            B_wren_other,

    // ALU AddSub carry-in/out for external control by accelerators
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * (MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT))-1:0]                                                            ALU_c_in,
    output  wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * (MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT))-1:0]                                                            ALU_c_out,

    // Only along the top/bottom edges of a Page
    output  wire    [(((               A_IO_READ_PORT_COUNT)  + (                    SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_LINE_NODE_COUNT)-1:0]  A_rden,
    input   wire    [(((A_WORD_WIDTH * A_IO_READ_PORT_COUNT)  + (SIMD_A_WORD_WIDTH * SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_LINE_NODE_COUNT)-1:0]  A_in,
    output  wire    [(((               A_IO_WRITE_PORT_COUNT) + (                    SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_LINE_NODE_COUNT)-1:0]  A_wren,
    output  wire    [(((A_WORD_WIDTH * A_IO_WRITE_PORT_COUNT) + (SIMD_A_WORD_WIDTH * SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_LINE_NODE_COUNT)-1:0]  A_out,

    // Only at the ends of the Lines
    output  wire    [(((               B_IO_READ_PORT_COUNT)  + (                    SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_PAGE_LINE_COUNT)-1:0]  B_rden,
    input   wire    [(((B_WORD_WIDTH * B_IO_READ_PORT_COUNT)  + (SIMD_B_WORD_WIDTH * SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_PAGE_LINE_COUNT)-1:0]  B_in,
    output  wire    [(((               B_IO_WRITE_PORT_COUNT) + (                    SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_PAGE_LINE_COUNT)-1:0]  B_wren,
    output  wire    [(((B_WORD_WIDTH * B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_PAGE_LINE_COUNT)-1:0]  B_out

);
    // Widths of ports, for later brevity
    localparam  PAGE_NODE_COUNT    = MESH_LINE_NODE_COUNT * MESH_PAGE_LINE_COUNT;
    localparam  SIMD_LANE_COUNT    = SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER;

    localparam  I_wren_other_WIDTH = PAGE_NODE_COUNT;                        
    localparam  A_wren_other_WIDTH = (SIMD_LANE_COUNT + 1) * PAGE_NODE_COUNT;
    localparam  B_wren_other_WIDTH = (SIMD_LANE_COUNT + 1) * PAGE_NODE_COUNT;
    localparam  ALU_c_in_WIDTH     = (SIMD_LANE_COUNT + 1) * PAGE_NODE_COUNT;
    localparam  ALU_c_out_WIDTH    = (SIMD_LANE_COUNT + 1) * PAGE_NODE_COUNT;

    localparam  A_rden_WIDTH       = ((               A_IO_READ_PORT_COUNT)  + (                    SIMD_A_IO_READ_PORT_COUNT  * SIMD_LANE_COUNT)) * MESH_LINE_NODE_COUNT;
    localparam  A_in_WIDTH         = ((A_WORD_WIDTH * A_IO_READ_PORT_COUNT)  + (SIMD_A_WORD_WIDTH * SIMD_A_IO_READ_PORT_COUNT  * SIMD_LANE_COUNT)) * MESH_LINE_NODE_COUNT;
    localparam  A_wren_WIDTH       = ((               A_IO_WRITE_PORT_COUNT) + (                    SIMD_A_IO_WRITE_PORT_COUNT * SIMD_LANE_COUNT)) * MESH_LINE_NODE_COUNT;
    localparam  A_out_WIDTH        = ((A_WORD_WIDTH * A_IO_WRITE_PORT_COUNT) + (SIMD_A_WORD_WIDTH * SIMD_A_IO_WRITE_PORT_COUNT * SIMD_LANE_COUNT)) * MESH_LINE_NODE_COUNT;

    localparam  B_rden_WIDTH       = ((               B_IO_READ_PORT_COUNT)  + (                    SIMD_B_IO_READ_PORT_COUNT  * SIMD_LANE_COUNT)) * MESH_PAGE_LINE_COUNT;
    localparam  B_in_WIDTH         = ((B_WORD_WIDTH * B_IO_READ_PORT_COUNT)  + (SIMD_B_WORD_WIDTH * SIMD_B_IO_READ_PORT_COUNT  * SIMD_LANE_COUNT)) * MESH_PAGE_LINE_COUNT;
    localparam  B_wren_WIDTH       = ((               B_IO_WRITE_PORT_COUNT) + (                    SIMD_B_IO_WRITE_PORT_COUNT * SIMD_LANE_COUNT)) * MESH_PAGE_LINE_COUNT;
    localparam  B_out_WIDTH        = ((B_WORD_WIDTH * B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_WRITE_PORT_COUNT * SIMD_LANE_COUNT)) * MESH_PAGE_LINE_COUNT;

    // The "Mesh_Node_Line_" wires populate the ports of the Mesh_Node_Line instances (see below).
    wire    [I_wren_other_WIDTH-1:0]                    Mesh_Node_Line_I_wren_other; 
    wire    [A_wren_other_WIDTH-1:0]                    Mesh_Node_Line_A_wren_other;
    wire    [B_wren_other_WIDTH-1:0]                    Mesh_Node_Line_B_wren_other;
    wire    [ALU_c_in_WIDTH    -1:0]                    Mesh_Node_Line_ALU_c_in;
    wire    [ALU_c_out_WIDTH   -1:0]                    Mesh_Node_Line_ALU_c_out;

    wire    [(A_rden_WIDTH * MESH_PAGE_LINE_COUNT)-1:0] Mesh_Node_Line_A_rden;
    wire    [(A_in_WIDTH   * MESH_PAGE_LINE_COUNT)-1:0] Mesh_Node_Line_A_in;
    wire    [(A_out_WIDTH  * MESH_PAGE_LINE_COUNT)-1:0] Mesh_Node_Line_A_out;
    wire    [(A_wren_WIDTH * MESH_PAGE_LINE_COUNT)-1:0] Mesh_Node_Line_A_wren;

    wire    [B_rden_WIDTH-1:0]                          Mesh_Node_Line_B_rden;
    wire    [B_in_WIDTH  -1:0]                          Mesh_Node_Line_B_in;
    wire    [B_out_WIDTH -1:0]                          Mesh_Node_Line_B_out;
    wire    [B_wren_WIDTH-1:0]                          Mesh_Node_Line_B_wren;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // First, we connect all the wires left as vectors and later connected higher-up in the hierarchy.

    // Propagate special-purpose signals up the hierarchy.
    assign Mesh_Node_Line_I_wren_other = I_wren_other;
    assign Mesh_Node_Line_A_wren_other = A_wren_other;
    assign Mesh_Node_Line_B_wren_other = B_wren_other;
    assign Mesh_Node_Line_ALU_c_in     = ALU_c_in;
    assign ALU_c_out                   = Mesh_Node_Line_ALU_c_out;
    
    // Connect B ports directly to the edges. Already pipelined in Mesh_Node_Line.
    assign B_rden               = Mesh_Node_Line_B_rden;
    assign Mesh_Node_Line_B_in  = B_in;
    assign B_out                = Mesh_Node_Line_B_out;
    assign B_wren               = Mesh_Node_Line_B_wren;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Now, let's wire the A ports through pipeline stages. 
    // Code like this shows the Verilog-2001 limitations of modules that cannot pass/accept arrays through ports, and of the lack of structures.
    // The top-level ports, Mesh_Node_Line_* ports, and the *_pipe_* ports all have regular structures, but you have to manually calculate the indices into each vector, and no two are alike.
    // The scalar and SIMD calculations are split since the width of SIMD ports may not equal that of scalar ports.

    // One extra pipe stage needed for inputs to Line
    localparam  PIPE_ARRAY_SIZE = (MESH_PAGE_LINE_COUNT + 1);
    // Shown in loop nesting order: first connect A ports across lines along one node index, then repeat for all other node indices.
    genvar node;
    genvar line;
    genvar lane;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Port A0 goes LSB to MSB (bottom to top), and thus wired straight-through.
    
    localparam Node_A_in_scalar_WIDTH   = (A_WORD_WIDTH * A_IO_READ_PORT_COUNT);
    localparam Node_A_out_scalar_WIDTH  = (A_WORD_WIDTH * A_IO_WRITE_PORT_COUNT);

    localparam Node_A_in_SIMD_WIDTH   = (SIMD_A_WORD_WIDTH * SIMD_A_IO_READ_PORT_COUNT);
    localparam Node_A_out_SIMD_WIDTH  = (SIMD_A_WORD_WIDTH * SIMD_A_IO_WRITE_PORT_COUNT);

    localparam Node_A_in_WIDTH  = (Node_A_in_scalar_WIDTH   + (Node_A_in_SIMD_WIDTH  * SIMD_LANE_COUNT));
    localparam Node_A_out_WIDTH = (Node_A_out_scalar_WIDTH  + (Node_A_out_SIMD_WIDTH * SIMD_LANE_COUNT));

    function integer A0_pipe_index (input integer line, input integer node); A0_pipe_index = ((A_WORD_WIDTH * MESH_LINE_NODE_COUNT * line) + (A_WORD_WIDTH * node)); endfunction

    wire [(A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] A0_pipe_in;
    wire [(A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] A0_pipe_out;

    Mesh_Pipe_Array
    #(
        .LSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
        .MID_PIPE_DEPTH     (MESH_PAGE_NODE_PIPE_DEPTH),
        .MSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
        .WIDTH              (A_WORD_WIDTH * MESH_LINE_NODE_COUNT),
        .PIPE_ARRAY_SIZE    (PIPE_ARRAY_SIZE) 
    )
    A0_pipe
    (
        .clock              (clock),
        .in                 (A0_pipe_in),
        .out                (A0_pipe_out)
    );
    
    generate
        for (node=0; node < MESH_LINE_NODE_COUNT; node=node+1) begin : A0_pipe_node
            assign A0_pipe_in[A0_pipe_index(0, node) +: A_WORD_WIDTH] = A_in[(Node_A_in_WIDTH * node) +: A_WORD_WIDTH];
            for (line=0; line < (PIPE_ARRAY_SIZE-1); line=line+1) begin : A0_pipe_wiring
                assign Mesh_Node_Line_A_in[((A_in_WIDTH * line) + (Node_A_in_WIDTH * node)) +: A_WORD_WIDTH] = A0_pipe_out[A0_pipe_index(line, node) +: A_WORD_WIDTH];
                assign A0_pipe_in[A0_pipe_index(line+1, node) +: A_WORD_WIDTH] = Mesh_Node_Line_A_out[((A_out_WIDTH * line) + (Node_A_out_WIDTH * node)) +: A_WORD_WIDTH];
            end
            assign A_out[(Node_A_out_WIDTH * node) +: A_WORD_WIDTH] = A0_pipe_out[A0_pipe_index(PIPE_ARRAY_SIZE-1, node) +: A_WORD_WIDTH];
        end

        // Connect the wren/rden wires only at the ends                                                                                                                                                     
        localparam last_rden = A_rden_WIDTH * (MESH_PAGE_LINE_COUNT-1);                                                                                                                                     
        localparam last_wren = A_wren_WIDTH * (MESH_PAGE_LINE_COUNT-1);                                                                                                                                     
                                                                                                                                                                                                            
        assign A_rden[0 +: 1] = Mesh_Node_Line_A_rden[0 +: 1];
        assign A_wren[0 +: 1] = Mesh_Node_Line_A_wren[0 +: 1]; 
        assign A_rden[1 +: 1] = Mesh_Node_Line_A_rden[last_rden +: 1];
        assign A_wren[1 +: 1] = Mesh_Node_Line_A_wren[last_wren +: 1];
    endgenerate

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // And again the same for each SIMD lanes' port A0.
    
    function integer SIMD_A0_pipe_index (input integer line, input integer node); 
        SIMD_A0_pipe_index = (SIMD_A_WORD_WIDTH * MESH_LINE_NODE_COUNT * line) + (SIMD_A_WORD_WIDTH * node); 
    endfunction

    function integer SIMD_A_in_index (input integer node, input integer lane);
        SIMD_A_in_index = (Node_A_in_WIDTH * node) + Node_A_in_scalar_WIDTH + (Node_A_in_SIMD_WIDTH * lane);
    endfunction

    function integer SIMD_A_out_index (input integer node, input integer lane);
        SIMD_A_out_index = (Node_A_out_WIDTH * node) + Node_A_out_scalar_WIDTH + (Node_A_out_SIMD_WIDTH * lane);
    endfunction

    function integer SIMD_Mesh_Node_A_in_index (input integer line, input integer node, input integer lane);
        SIMD_Mesh_Node_A_in_index = (A_in_WIDTH * line) + SIMD_A_in_index(node, lane);
    endfunction

    function integer SIMD_Mesh_Node_A_out_index (input integer line, input integer node, input integer lane);
        SIMD_Mesh_Node_A_out_index = (A_out_WIDTH * line) + SIMD_A_out_index(node, lane);
    endfunction

    generate
        for (lane=0; lane < SIMD_LANE_COUNT; lane=lane+1) begin : SIMD_A0_pipe_lane
            wire [(SIMD_A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] SIMD_A0_pipe_in;
            wire [(SIMD_A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] SIMD_A0_pipe_out;

            Mesh_Pipe_Array
            #(
                .LSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
                .MID_PIPE_DEPTH     (MESH_PAGE_NODE_PIPE_DEPTH),
                .MSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
                .WIDTH              (SIMD_A_WORD_WIDTH * MESH_LINE_NODE_COUNT),
                .PIPE_ARRAY_SIZE    (PIPE_ARRAY_SIZE) 
            )
            SIMD_A0_pipe
            (
                .clock              (clock),
                .in                 (SIMD_A0_pipe_in),
                .out                (SIMD_A0_pipe_out)
            );
            
            for (node=0; node < MESH_LINE_NODE_COUNT; node=node+1) begin : SIMD_A0_pipe_node
                assign SIMD_A0_pipe_in[SIMD_A0_pipe_index(0, node) +: SIMD_A_WORD_WIDTH] = A_in[SIMD_A_in_index(node, lane) +: SIMD_A_WORD_WIDTH];
                for (line=0; line < (PIPE_ARRAY_SIZE-1); line=line+1) begin : SIMD_A0_pipe_wiring
                    assign Mesh_Node_Line_A_in[SIMD_Mesh_Node_A_in_index(line, node, lane) +: SIMD_A_WORD_WIDTH] = SIMD_A0_pipe_out[SIMD_A0_pipe_index(line, node) +: SIMD_A_WORD_WIDTH];
                    assign SIMD_A0_pipe_in[SIMD_A0_pipe_index(line+1, node) +: SIMD_A_WORD_WIDTH] = Mesh_Node_Line_A_out[SIMD_Mesh_Node_A_out_index(line, node, lane) +: SIMD_A_WORD_WIDTH];
                end
                assign A_out[SIMD_A_out_index(node, lane) +: SIMD_A_WORD_WIDTH] = SIMD_A0_pipe_out[SIMD_A0_pipe_index(PIPE_ARRAY_SIZE-1, node) +: SIMD_A_WORD_WIDTH];
            end

            // Connect the wren/rden wires only at the ends                                                                                                                                                 
            localparam last_rden = A_rden_WIDTH * (MESH_PAGE_LINE_COUNT-1);                                                                                                                                 
            localparam last_wren = A_wren_WIDTH * (MESH_PAGE_LINE_COUNT-1);                                                                                                                                 
            localparam lane_offset = (lane * SIMD_A_IO_READ_PORT_COUNT) + A_IO_READ_PORT_COUNT;                                                                                                             
                                                                                                                                                                                                            
            assign A_rden[ lane_offset      +: 1] = Mesh_Node_Line_A_rden[ lane_offset              +: 1];
            assign A_wren[ lane_offset      +: 1] = Mesh_Node_Line_A_wren[ lane_offset              +: 1];
            assign A_rden[(lane_offset + 1) +: 1] = Mesh_Node_Line_A_rden[(lane_offset + last_rden) +: 1];
            assign A_wren[(lane_offset + 1) +: 1] = Mesh_Node_Line_A_wren[(lane_offset + last_wren) +: 1];
        end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Port A1 goes MSB to LSB (top to bottom), so we wire in in a "whipstitch" fashion to reverse the direction of data flow.
    
    function integer A1_pipe_index (input integer line, input integer node); A1_pipe_index = ((A_WORD_WIDTH * MESH_LINE_NODE_COUNT * line) + (A_WORD_WIDTH * node)); endfunction

    wire [(A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] A1_pipe_in;
    wire [(A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] A1_pipe_out;

    Mesh_Pipe_Array
    #(
        .LSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
        .MID_PIPE_DEPTH     (MESH_PAGE_NODE_PIPE_DEPTH),
        .MSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
        .WIDTH              (A_WORD_WIDTH * MESH_LINE_NODE_COUNT),
        .PIPE_ARRAY_SIZE    (PIPE_ARRAY_SIZE) 
    )
    A1_pipe
    (
        .clock              (clock),
        .in                 (A1_pipe_in),
        .out                (A1_pipe_out)
    );
    
    generate
        for (node=0; node < MESH_LINE_NODE_COUNT; node=node+1) begin : A1_pipe_node
            assign A1_pipe_in[A1_pipe_index(PIPE_ARRAY_SIZE-1, node) +: A_WORD_WIDTH] = A_in[((Node_A_in_WIDTH * node) + A_WORD_WIDTH) +: A_WORD_WIDTH];
            for (line=PIPE_ARRAY_SIZE-1; line > 0; line=line-1) begin: A1_pipe_wiring
                assign Mesh_Node_Line_A_in[((A_in_WIDTH * (line-1)) + (Node_A_in_WIDTH * node) + A_WORD_WIDTH) +: A_WORD_WIDTH] = A1_pipe_out[A1_pipe_index(line, node) +: A_WORD_WIDTH];
                assign A1_pipe_in[A1_pipe_index(line-1, node) +: A_WORD_WIDTH] = Mesh_Node_Line_A_out[((A_out_WIDTH * (line-1)) + (Node_A_out_WIDTH * node) + A_WORD_WIDTH) +: A_WORD_WIDTH];
            end
            assign A_out[((Node_A_out_WIDTH * node) + A_WORD_WIDTH) +: A_WORD_WIDTH] = A1_pipe_out[A1_pipe_index(0, node) +: A_WORD_WIDTH];
        end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // And again the same for each SIMD lanes' port A1.

    function integer SIMD_A1_pipe_index (input integer line, input integer node); 
        SIMD_A1_pipe_index = (SIMD_A_WORD_WIDTH * MESH_LINE_NODE_COUNT * line) + (SIMD_A_WORD_WIDTH * node); 
    endfunction

    generate
        for (lane=0; lane < SIMD_LANE_COUNT; lane=lane+1) begin : SIMD_A1_pipe_lane
            wire [(SIMD_A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] SIMD_A1_pipe_in;
            wire [(SIMD_A_WORD_WIDTH * PIPE_ARRAY_SIZE * MESH_LINE_NODE_COUNT)-1:0] SIMD_A1_pipe_out;

            Mesh_Pipe_Array
            #(
                .LSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
                .MID_PIPE_DEPTH     (MESH_PAGE_NODE_PIPE_DEPTH),
                .MSB_PIPE_DEPTH     (MESH_PAGE_EDGE_PIPE_DEPTH),
                .WIDTH              (SIMD_A_WORD_WIDTH * MESH_LINE_NODE_COUNT),
                .PIPE_ARRAY_SIZE    (PIPE_ARRAY_SIZE) 
            )
            SIMD_A1_pipe
            (
                .clock              (clock),
                .in                 (SIMD_A1_pipe_in),
                .out                (SIMD_A1_pipe_out)
            );
            
            for (node=0; node < MESH_LINE_NODE_COUNT; node=node+1) begin : SIMD_A1_pipe_node
                // See index functions for SIMD ports A0. We add SIMD_A_WORD_WIDTH here to index into A1 instead.
                assign SIMD_A1_pipe_in[SIMD_A1_pipe_index(PIPE_ARRAY_SIZE-1, node) +: SIMD_A_WORD_WIDTH] = A_in[(SIMD_A_in_index(node, lane) + SIMD_A_WORD_WIDTH) +: SIMD_A_WORD_WIDTH];
                for (line=PIPE_ARRAY_SIZE-1; line > 0; line=line-1) begin : SIMD_A1_pipe_lane
                    assign Mesh_Node_Line_A_in[(SIMD_Mesh_Node_A_in_index(line-1, node, lane) + SIMD_A_WORD_WIDTH) +: SIMD_A_WORD_WIDTH] = SIMD_A1_pipe_out[SIMD_A1_pipe_index(line, node) +: SIMD_A_WORD_WIDTH];
                    assign SIMD_A1_pipe_in[SIMD_A1_pipe_index(line-1, node) +: SIMD_A_WORD_WIDTH] = Mesh_Node_Line_A_out[(SIMD_Mesh_Node_A_out_index(line-1, node, lane) + SIMD_A_WORD_WIDTH) +: SIMD_A_WORD_WIDTH];
                end
                assign A_out[(SIMD_A_out_index(node, lane) + SIMD_A_WORD_WIDTH) +: SIMD_A_WORD_WIDTH] = SIMD_A1_pipe_out[SIMD_A1_pipe_index(0, node) +: SIMD_A_WORD_WIDTH];
            end
        end
    endgenerate


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // And here's the array of Mesh_Node_Lines.
    Mesh_Node_Line
    #(
        .ALU_WORD_WIDTH                     (ALU_WORD_WIDTH),                 
        .SIMD_ALU_WORD_WIDTH                (SIMD_ALU_WORD_WIDTH),                 
        
        .INSTR_WIDTH                        (INSTR_WIDTH),                       
        .OPCODE_WIDTH                       (OPCODE_WIDTH),                     
        .D_OPERAND_WIDTH                    (D_OPERAND_WIDTH),
        .A_OPERAND_WIDTH                    (A_OPERAND_WIDTH),
        .B_OPERAND_WIDTH                    (B_OPERAND_WIDTH),
        
        .A_WORD_WIDTH                       (A_WORD_WIDTH),
        .A_ADDR_WIDTH                       (A_ADDR_WIDTH),
        .A_DEPTH                            (A_DEPTH),
        .A_RAMSTYLE                         (A_RAMSTYLE),
        .A_INIT_FILE                        (A_INIT_FILE),
        .A_IO_READ_PORT_COUNT               (A_IO_READ_PORT_COUNT),
        .A_IO_READ_PORT_BASE_ADDR           (A_IO_READ_PORT_BASE_ADDR),
        .A_IO_READ_PORT_ADDR_WIDTH          (A_IO_READ_PORT_ADDR_WIDTH),
        .A_IO_WRITE_PORT_COUNT              (A_IO_WRITE_PORT_COUNT),
        .A_IO_WRITE_PORT_BASE_ADDR          (A_IO_WRITE_PORT_BASE_ADDR),
        .A_IO_WRITE_PORT_ADDR_WIDTH         (A_IO_WRITE_PORT_ADDR_WIDTH),
        
        .SIMD_A_WORD_WIDTH                  (SIMD_A_WORD_WIDTH),
        .SIMD_A_ADDR_WIDTH                  (SIMD_A_ADDR_WIDTH),
        .SIMD_A_DEPTH                       (SIMD_A_DEPTH),
        .SIMD_A_RAMSTYLE                    (SIMD_A_RAMSTYLE),
        .SIMD_A_INIT_FILE                   (SIMD_A_INIT_FILE),
        .SIMD_A_IO_READ_PORT_COUNT          (SIMD_A_IO_READ_PORT_COUNT),
        .SIMD_A_IO_READ_PORT_BASE_ADDR      (SIMD_A_IO_READ_PORT_BASE_ADDR),
        .SIMD_A_IO_READ_PORT_ADDR_WIDTH     (SIMD_A_IO_READ_PORT_ADDR_WIDTH),
        .SIMD_A_IO_WRITE_PORT_COUNT         (SIMD_A_IO_WRITE_PORT_COUNT),
        .SIMD_A_IO_WRITE_PORT_BASE_ADDR     (SIMD_A_IO_WRITE_PORT_BASE_ADDR),
        .SIMD_A_IO_WRITE_PORT_ADDR_WIDTH    (SIMD_A_IO_WRITE_PORT_ADDR_WIDTH),
        
        .B_WORD_WIDTH                       (B_WORD_WIDTH),
        .B_ADDR_WIDTH                       (B_ADDR_WIDTH),
        .B_DEPTH                            (B_DEPTH),
        .B_RAMSTYLE                         (B_RAMSTYLE),
        .B_INIT_FILE                        (B_INIT_FILE),
        .B_IO_READ_PORT_COUNT               (B_IO_READ_PORT_COUNT),
        .B_IO_READ_PORT_BASE_ADDR           (B_IO_READ_PORT_BASE_ADDR),
        .B_IO_READ_PORT_ADDR_WIDTH          (B_IO_READ_PORT_ADDR_WIDTH),
        .B_IO_WRITE_PORT_COUNT              (B_IO_WRITE_PORT_COUNT),
        .B_IO_WRITE_PORT_BASE_ADDR          (B_IO_WRITE_PORT_BASE_ADDR),
        .B_IO_WRITE_PORT_ADDR_WIDTH         (B_IO_WRITE_PORT_ADDR_WIDTH),
        
        .SIMD_B_WORD_WIDTH                  (SIMD_B_WORD_WIDTH),
        .SIMD_B_ADDR_WIDTH                  (SIMD_B_ADDR_WIDTH),
        .SIMD_B_DEPTH                       (SIMD_B_DEPTH),
        .SIMD_B_RAMSTYLE                    (SIMD_B_RAMSTYLE),
        .SIMD_B_INIT_FILE                   (SIMD_B_INIT_FILE),
        .SIMD_B_IO_READ_PORT_COUNT          (SIMD_B_IO_READ_PORT_COUNT),
        .SIMD_B_IO_READ_PORT_BASE_ADDR      (SIMD_B_IO_READ_PORT_BASE_ADDR),
        .SIMD_B_IO_READ_PORT_ADDR_WIDTH     (SIMD_B_IO_READ_PORT_ADDR_WIDTH),
        .SIMD_B_IO_WRITE_PORT_COUNT         (SIMD_B_IO_WRITE_PORT_COUNT),
        .SIMD_B_IO_WRITE_PORT_BASE_ADDR     (SIMD_B_IO_WRITE_PORT_BASE_ADDR),
        .SIMD_B_IO_WRITE_PORT_ADDR_WIDTH    (SIMD_B_IO_WRITE_PORT_ADDR_WIDTH),
        
        .I_WORD_WIDTH                       (I_WORD_WIDTH),
        .I_ADDR_WIDTH                       (I_ADDR_WIDTH),
        .I_DEPTH                            (I_DEPTH),
        .I_RAMSTYLE                         (I_RAMSTYLE),
        .I_INIT_FILE                        (I_INIT_FILE),
        
        .PC_RAMSTYLE                        (PC_RAMSTYLE),
        .PC_INIT_FILE                       (PC_INIT_FILE),
        .THREAD_COUNT                       (THREAD_COUNT),
        .THREAD_ADDR_WIDTH                  (THREAD_ADDR_WIDTH),
        
        .PC_PIPELINE_DEPTH                  (PC_PIPELINE_DEPTH),
        .I_TAP_PIPELINE_DEPTH               (I_TAP_PIPELINE_DEPTH),
        .TAP_AB_PIPELINE_DEPTH              (TAP_AB_PIPELINE_DEPTH),
        .I_PASSTHRU_PIPELINE_DEPTH          (I_PASSTHRU_PIPELINE_DEPTH),
        .AB_READ_PIPELINE_DEPTH             (AB_READ_PIPELINE_DEPTH),

        .SIMD_I_PASSTHRU_PIPELINE_DEPTH     (SIMD_I_PASSTHRU_PIPELINE_DEPTH),
        .SIMD_TAP_AB_PIPELINE_DEPTH         (SIMD_TAP_AB_PIPELINE_DEPTH),

        .AB_ALU_PIPELINE_DEPTH              (AB_ALU_PIPELINE_DEPTH),
        .LOGIC_OPCODE_WIDTH                 (LOGIC_OPCODE_WIDTH),

        .ADDSUB_CARRY_SELECT                (ADDSUB_CARRY_SELECT),
        .MULT_DOUBLE_PIPE                   (MULT_DOUBLE_PIPE),
        .MULT_HETEROGENEOUS                 (MULT_HETEROGENEOUS),
        .MULT_USE_DSP                       (MULT_USE_DSP),

        .SIMD_ADDSUB_CARRY_SELECT           (SIMD_ADDSUB_CARRY_SELECT),
        .SIMD_MULT_DOUBLE_PIPE              (SIMD_MULT_DOUBLE_PIPE),
        .SIMD_MULT_HETEROGENEOUS            (SIMD_MULT_HETEROGENEOUS),
        .SIMD_MULT_USE_DSP                  (SIMD_MULT_USE_DSP),

        .SIMD_LAYER_COUNT                   (SIMD_LAYER_COUNT),
        .SIMD_LANES_PER_LAYER               (SIMD_LANES_PER_LAYER),

        .MESH_LINE_NODE_COUNT               (MESH_LINE_NODE_COUNT),
        .MESH_LINE_EDGE_PIPE_DEPTH          (MESH_LINE_EDGE_PIPE_DEPTH),
        .MESH_LINE_NODE_PIPE_DEPTH          (MESH_LINE_NODE_PIPE_DEPTH)
    )
    Mesh_Node_Line_Array                    [MESH_PAGE_LINE_COUNT-1:0]
    (
        .clock                              (clock),
        .half_clock                         (half_clock),

        .I_wren_other                       (Mesh_Node_Line_I_wren_other),        
        .A_wren_other                       (Mesh_Node_Line_A_wren_other),        
        .B_wren_other                       (Mesh_Node_Line_B_wren_other),        

        .ALU_c_in                           (Mesh_Node_Line_ALU_c_in),
        .ALU_c_out                          (Mesh_Node_Line_ALU_c_out),

        .A_rden                             (Mesh_Node_Line_A_rden),
        .A_in                               (Mesh_Node_Line_A_in),
        .A_out                              (Mesh_Node_Line_A_out),
        .A_wren                             (Mesh_Node_Line_A_wren),
        
        .B_rden                             (Mesh_Node_Line_B_rden),
        .B_in                               (Mesh_Node_Line_B_in),
        .B_out                              (Mesh_Node_Line_B_out),
        .B_wren                             (Mesh_Node_Line_B_wren)
    );
endmodule
