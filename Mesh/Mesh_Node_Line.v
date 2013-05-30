// A Mesh_Node_Array interconnected with Mesh_Pipes_Array(s) 
// For now, just do a linear nearest-neighbour line

module Mesh_Node_Line
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

    parameter       MESH_NODE_COUNT                 = 0,
    parameter       MESH_EDGE_PIPE_DEPTH            = 0,
    parameter       MESH_NODE_PIPE_DEPTH            = 0
)
(
    input   wire                                                                                                                                                                       clock,
    input   wire                                                                                                                                                                       half_clock,

    // Memory write enables for external control by accelerators
    input   wire    [MESH_NODE_COUNT-1:0]                                                                                                                                              I_wren_other,
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)-1:0]                                                                                          A_wren_other,
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)-1:0]                                                                                          B_wren_other,

    // ALU AddSub carry-in/out for external control by accelerators
    input   wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)-1:0]                                                                                          ALU_c_in,
    output  wire    [(((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)-1:0]                                                                                          ALU_c_out,

    // Interconnected at the Page level, leave as vector for now.
    output  wire    [(((               A_IO_READ_PORT_COUNT)  + (                    SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)-1:0]  A_rden,
    input   wire    [(((A_WORD_WIDTH * A_IO_READ_PORT_COUNT)  + (SIMD_A_WORD_WIDTH * SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)-1:0]  A_in,
    output  wire    [(((               A_IO_WRITE_PORT_COUNT) + (                    SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)-1:0]  A_wren,
    output  wire    [(((A_WORD_WIDTH * A_IO_WRITE_PORT_COUNT) + (SIMD_A_WORD_WIDTH * SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)-1:0]  A_out,

    // Only at the ends of the Line
    output  wire    [ ((               B_IO_READ_PORT_COUNT)  + (                    SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER)))                   -1:0]  B_rden,
    input   wire    [ ((B_WORD_WIDTH * B_IO_READ_PORT_COUNT)  + (SIMD_B_WORD_WIDTH * SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER)))                   -1:0]  B_in,
    output  wire    [ ((               B_IO_WRITE_PORT_COUNT) + (                    SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER)))                   -1:0]  B_wren,
    output  wire    [ ((B_WORD_WIDTH * B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER)))                   -1:0]  B_out

);
    // Widths of ports, for later brevity
    localparam  MESH_NODE_COUNT                                                                                                                                                 I_wren_other_WIDTH; 
    localparam  (((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)                                                                                             A_wren_other_WIDTH;
    localparam  (((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)                                                                                             B_wren_other_WIDTH;
    localparam  (((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)                                                                                             ALU_c_in_WIDTH;
    localparam  (((SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER) + 1) * MESH_NODE_COUNT)                                                                                             ALU_c_out_WIDTH;

    localparam  (((               A_IO_READ_PORT_COUNT)  + (                    SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)     A_rden_WIDTH;
    localparam  (((A_WORD_WIDTH * A_IO_READ_PORT_COUNT)  + (SIMD_A_WORD_WIDTH * SIMD_A_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)     A_in_WIDTH;
    localparam  (((               A_IO_WRITE_PORT_COUNT) + (                    SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)     A_out_WIDTH;
    localparam  ( (A_WORD_WIDTH * A_IO_WRITE_PORT_COUNT) + (SIMD_A_WORD_WIDTH * SIMD_A_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))) * MESH_NODE_COUNT)     A_wren_WIDTH;

    localparam    (               B_IO_READ_PORT_COUNT)  + (                    SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))                         B_rden_WIDTH;
    localparam    (B_WORD_WIDTH * B_IO_READ_PORT_COUNT)  + (SIMD_B_WORD_WIDTH * SIMD_B_IO_READ_PORT_COUNT  * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))                         B_in_WIDTH;
    localparam    (               B_IO_WRITE_PORT_COUNT) + (                    SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))                         B_out_WIDTH;
    localparam    (B_WORD_WIDTH * B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_WRITE_PORT_COUNT * (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER))                         B_wren_WIDTH;

    localparam  (SIMD_LAYER_COUNT * SIMD_LANES_PER_LAYER)                                                                                                                       SIMD_LANE_COUNT;

    // The "Mesh_Node_" wires populate the ports of the Octavo instances (see below).
    wire    [I_wren_other_WIDTH-1:0]    Mesh_Node_I_wren_other; 
    wire    [A_wren_other_WIDTH-1:0]    Mesh_Node_A_wren_other;
    wire    [B_wren_other_WIDTH-1:0]    Mesh_Node_B_wren_other;
    wire    [ALU_c_in_WIDTH-1:0]        Mesh_Node_ALU_c_in;
    wire    [ALU_c_out_WIDTH-1:0]       Mesh_Node_ALU_c_out;

    wire    [A_rden_WIDTH-1:0]          Mesh_Node_A_rden;
    wire    [A_in_WIDTH-1:0]            Mesh_Node_A_in;
    wire    [A_out_WIDTH-1:0]           Mesh_Node_A_out;
    wire    [A_wren_WIDTH-1:0]          Mesh_Node_A_wren;

    wire    [(B_rden_WIDTH * MESH_NODE_COUNT)-1:0]  Mesh_Node_B_rden;
    wire    [(B_in_WIDTH   * MESH_NODE_COUNT)-1:0]  Mesh_Node_B_in;
    wire    [(B_out_WIDTH  * MESH_NODE_COUNT)-1:0]  Mesh_Node_B_out;
    wire    [(B_wren_WIDTH * MESH_NODE_COUNT)-1:0]  Mesh_Node_B_wren;

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // First, we connect all the wires left as vectors.

    // Propagate special-purpose signals up the hierarchy.
    assign Mesh_Node_I_wren_other = I_wren_other;
    assign Mesh_Node_A_wren_other = A_wren_other;
    assign Mesh_Node_B_wren_other = B_wren_other;
    assign Mesh_Node_ALU_c_in     = ALU_c_in;
    assign ALU_c_out              = Mesh_Node_ALU_c_out;
    
    // Connect A ports directly broadside, like ships' cannons. Any pipelining comes later, when grouping Lines into a Page.
    assign A_rden                 = Mesh_Node_A_rden;
    assign Mesh_Node_A_in         = A_in;
    assign A_out                  = Mesh_Node_A_out;
    assign A_wren                 = Mesh_Node_A_wren;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Second, we unpack the remaining Mesh_Node_Line and Mesh_Node array vectors into wire arrays

    // The "Line_" wires unpack the Mesh_Node_Line instance ports.
    wire                            Line_B_rden         [MESH_NODE_COUNT-1:0][B_IO_READ_PORT_COUNT-1:0];
    wire    [B_WORD_WIDTH-1:0]      Line_B_in           [MESH_NODE_COUNT-1:0][B_IO_READ_PORT_COUNT-1:0];
    wire    [B_WORD_WIDTH-1:0]      Line_B_out          [MESH_NODE_COUNT-1:0][B_IO_WRITE_PORT_COUNT-1:0];
    wire                            Line_B_wren         [MESH_NODE_COUNT-1:0][B_IO_WRITE_PORT_COUNT-1:0];

    generate
        if (SIMD_LANE_COUNT > 0) begin
            wire                            Line_SIMD_B_rden    [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_READ_PORT_COUNT-1:0];
            wire    [SIMD_B_WORD_WIDTH-1:0] Line_SIMD_B_in      [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_READ_PORT_COUNT-1:0];
            wire    [SIMD_B_WORD_WIDTH-1:0] Line_SIMD_B_out     [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_WRITE_PORT_COUNT-1:0];
            wire                            Line_SIMD_B_wren    [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_WRITE_PORT_COUNT-1:0];
        end
    endgenerate

    // The "Node_" wires unpack the Mesh_Node_Array instance ports.
    wire                            Node_B_rden         [MESH_NODE_COUNT-1:0][B_IO_READ_PORT_COUNT-1:0];
    wire    [B_WORD_WIDTH-1:0]      Node_B_in           [MESH_NODE_COUNT-1:0][B_IO_READ_PORT_COUNT-1:0];
    wire    [B_WORD_WIDTH-1:0]      Node_B_out          [MESH_NODE_COUNT-1:0][B_IO_WRITE_PORT_COUNT-1:0];
    wire                            Node_B_wren         [MESH_NODE_COUNT-1:0][B_IO_WRITE_PORT_COUNT-1:0];

    generate
        if (SIMD_LANE_COUNT > 0) begin
            wire                            Node_SIMD_B_rden    [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_READ_PORT_COUNT-1:0];
            wire    [SIMD_B_WORD_WIDTH-1:0] Node_SIMD_B_in      [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_READ_PORT_COUNT-1:0];
            wire    [SIMD_B_WORD_WIDTH-1:0] Node_SIMD_B_out     [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_WRITE_PORT_COUNT-1:0];
            wire                            Node_SIMD_B_wren    [MESH_NODE_COUNT-1:0][SIMD_LANE_COUNT-1:0][SIMD_B_IO_WRITE_PORT_COUNT-1:0];
        end
    endgenerate

    // Unpack Mesh_Node_Array vector into array
    integer i, j, k;
    for(i=0; i < MESH_NODE_COUNT; i=i+1) begin
        for(k=0; k < B_IO_READ_PORT_COUNT; k=k+1) begin
            assign Node_B_rden[i][k] = Mesh_Node_B_rden[((B_rden_WIDTH * i) + (1            * k)) +: 1           ];
            assign Node_B_in  [i][k] = Mesh_Node_B_in  [((B_in_WIDTH   * i) + (B_WORD_WIDTH * k)) +: B_WORD_WIDTH];
            assign Node_B_out [i][k] = Mesh_Node_B_out [((B_out_WIDTH  * i) + (B_WORD_WIDTH * k)) +: B_WORD_WIDTH];
            assign Node_B_wren[i][k] = Mesh_Node_B_wren[((B_wren_WIDTH * i) + (1            * k)) +: 1           ];
        end
    end

    if (SIMD_LANE_COUNT > 0) begin
        for(i=0; i < MESH_NODE_COUNT; i=i+1) begin
            for(j=0; j < SIMD_LANE_COUNT; j=j+1) begin
                for(k=0; k < SIMD_B_IO_READ_PORT_COUNT; k=k+1) begin
                    assign Node_B_rden[i][j][k] = Mesh_Node_B_rden[((B_rden_WIDTH * i) + (B_IO_READ_PORT_COUNT)  + (SIMD_B_IO_READ_PORT_COUNT * j) + (1            * k)) +: 1           ];
                    assign Node_B_in  [i][j][k] = Mesh_Node_B_in  [((B_in_WIDTH   * i) + (B_WORD_WIDTH * B_IO_READ_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_READ_PORT_COUNT) + (SIMD_B_WORD_WIDTH * k)) +: SIMD_B_WORD_WIDTH];
                    assign Node_B_out [i][j][k] = Mesh_Node_B_out [((B_in_WIDTH   * i) + (B_WORD_WIDTH * B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * SIMD_B_IO_WRITE_PORT_COUNT) + (SIMD_B_WORD_WIDTH * k)) +: SIMD_B_WORD_WIDTH];
                    assign Node_B_wren[i][j][k] = Mesh_Node_B_wren[((B_wren_WIDTH * i) + (B_IO_READ_PORT_COUNT)  + (SIMD_B_IO_READ_PORT_COUNT * j) + (1            * k)) +: 1           ];
                end
            end
        end
    end









    // Connect B ports to nearest linear neighbours, via pipelining, bow to stern.
    generate
        genvar node;

        Mesh_Pipe_Array
        #(
            .LSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .MID_PIPE_DEPTH     (MESH_NODE_PIPE_DEPTH),
            .MSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .WIDTH              (B_out_WIDTH),
            .PIPE_ARRAY_SIZE    (MESH_NODE_COUNT) 
        )
        B_out_pipe
        (
            .clock              (clock),
            .in                 (B_in),
            .out                (Pipe_B_out[MESH_NODE_COUNT-1])

        );

        for(node=1; node < MESH_NODE_COUNT-1; node = node + 1) begin

        Mesh_Pipe_Array
        #(
            .LSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .MID_PIPE_DEPTH     (MESH_NODE_PIPE_DEPTH),
            .MSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .WIDTH              (B_out_WIDTH),
            .PIPE_ARRAY_SIZE    (MESH_NODE_COUNT) 
        )
        B_out_pipe
        (
            .clock              (clock),
            .in                 (),
            .out                (Mesh_Node_B_out_pipe)

        );

        Mesh_Pipe_Array
        #(
            .LSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .MID_PIPE_DEPTH     (MESH_NODE_PIPE_DEPTH),
            .MSB_PIPE_DEPTH     (MESH_EDGE_PIPE_DEPTH),
            .WIDTH              (B_out_WIDTH),
            .PIPE_ARRAY_SIZE    (MESH_NODE_COUNT) 
        )
        B_out_pipe
        (
            .clock              (clock),
            .in                 (B_in),
            .out                (Pipe_B_out[MESH_NODE_COUNT-1])

        );

        Octavo
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
            .SIMD_LANES_PER_LAYER               (SIMD_LANES_PER_LAYER)
        )
        Mesh_Node_Array                         [MESH_NODE_COUNT-1:0]
        (
            .clock                              (clock),
            .half_clock                         (half_clock),

            .I_wren_other                       (Mesh_Node_I_wren_other),        
            .A_wren_other                       (Mesh_Node_A_wren_other),        
            .B_wren_other                       (Mesh_Node_B_wren_other),        

            .ALU_c_in                           (Mesh_Node_ALU_c_in),
            .ALU_c_out                          (Mesh_Node_ALU_c_out),

            .A_io_rden                          (Mesh_Node_A_rden),
            .A_io_in                            (Mesh_Node_A_in),
            .A_io_out                           (Mesh_Node_A_out),
            .A_io_wren                          (Mesh_Node_A_wren),
            
            .B_io_rden                          (Mesh_Node_B_rden),
            .B_io_in                            (Mesh_Node_B_in),
            .B_io_out                           (Mesh_Node_B_out),
            .B_io_wren                          (Mesh_Node_B_wren)
        );
    endgenerate
endmodule
