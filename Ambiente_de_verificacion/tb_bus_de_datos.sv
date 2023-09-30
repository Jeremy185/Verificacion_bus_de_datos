
//include "driver_monitor.sv"

class driver #(parameter width = 16, parameter depth = 8);
    //trans_bus_mbx agente_driver;
    int espera;                     //Variable que hace el retardo
    int id;                         //Valor del id
    function new(int terminal);
        this.id = terminal;
    endfunction 

    task run ();
        $display("[%g] El driver %d fue inicializado",$time, id );
    endtask

endclass


module tb_bus_de_datos();
    driver #(.width(16), .depth(8)) driver_inst;

    initial begin
        driver_inst = new (1);
        #10
        driver_inst.run();
    end
endmodule
