//
// Copyright 2014 Ettus Research LLC
//

module noc_block_file_io #(
  parameter NOC_ID                     = 64'h0000_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE          = 11,
  parameter SRC_DEFAULT_SWAP_SAMPLES   = 2, // sc16
  parameter SRC_DEFAULT_ENDIANNESS     = 2, // .
  parameter SRC_FILE_LENGTH            = 65536, // Bytes
  parameter SRC_FILENAME               = "",
  parameter SINK_DEFAULT_SWAP_SAMPLES  = 2, // sc16
  parameter SINK_ENDIANNESS            = 2, // .
  parameter SINK_FILENAME              = "")
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .rb_data(64'd0),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .debug(debug));

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////
  localparam BASE = 128;

  file_source #(
    .SR_NEXT_DST(BASE),
    .SR_PKT_LENGTH(BASE+1),
    .SR_RATE(BASE+2),
    .SR_SEND_TIME(BASE+3),
    .SR_SWAP_SAMPLES(BASE+4),
    .SR_ENDIANNESS(BASE+5),
    .DEFAULT_SWAP_SAMPLES(SRC_DEFAULT_SWAP_SAMPLES),
    .DEFAULT_ENDIANNESS(SRC_DEFAULT_ENDIANNESS),
    .FILE_LENGTH(SRC_FILE_LENGTH),
    .FILENAME(SRC_FILENAME))
  file_source (
    .clk(ce_clk), .reset(ce_rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready));

  file_sink #(
    .SR_SWAP_SAMPLES(BASE+6),
    .SR_ENDIANNESS(BASE+7),
    .DEFAULT_SWAP_SAMPLES(SINK_DEFAULT_SWAP_SAMPLES),
    .DEFAULT_ENDIANNESS(SINK_ENDIANNESS),
    .FILENAME(SINK_FILENAME))
  file_sink (
    .clk_i(ce_clk),
    .rst_i(ce_rst),
    .set_stb_i(set_stb),
    .set_addr_i(set_addr),
    .set_data_i(set_data),
    .i_tdata(str_sink_tdata),
    .i_tlast(str_sink_tlast),
    .i_tvalid(str_sink_tvalid),
    .i_tready(str_sink_tready));

endmodule
