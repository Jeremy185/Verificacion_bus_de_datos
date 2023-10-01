`include "Ambiente.sv"

module tb_bus_de_datos;
    reg clk;
    parameter width = 16;
    parameter depth = 8;
    parameter drivers = 4;
    parameter bits = 1;

    ambiente #(.width(width), .depth(depth), .drivers(drivers)) prueba;
    FIFOS #(.width(16), .drivers(8), .bits(1)) _FIFOS (.clk(clk));
    always #5 clk =~ clk;

    module bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drivers), .pckg_sz(width), .broadcast({8{1'b1}}))(
        .clk        (_FIFO.clk),
        .reset      (_FIFO.rst),
        .pndng      (_FIFO.pndng),
        .push       (_FIFO.push),
        .pop        (_FIFO.pop),
        .D_pop      (_FIFO.D_pop),
        .D_push     (_FIFO.D_push)
    );

    initial begin
        clk = 0;
        ambiente = new();
        ambiente._FIFOS = _FIFOS;

        fork
            ambiente.run();
        join_none
    end 

endmodule
