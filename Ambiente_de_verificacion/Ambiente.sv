`include "driver_monitor.sv"

class ambiente #(parameter width = 16,  parameter depth = 8, parameter drivers = 4 );

    //Declaracion de los componentes del ambiente
    driver_monitor #(.width(width), .depth(depth), .drivers(drivers)) driver_monitor_inst [drivers];

    //Declaracion de la interface que conecta con el DUT
    virtual FIFOS #(.width(16), .drivers(8), .bits(1)) _FIFOS;

    //Declaracion de los mailboxes 
    trans_bus_mbx agente_monitor[drivers];  
    trans_bus_mbx agente_driver[drivers];

    function new();

        //Instanciacion de los mailboxes
        for (int i = 0; i < drivers; i++)begin
            agente_monitor[i] = new();
            agente_driver[i] = new();
        end
        
        //instanciacion de los componentes del ambiente
        for (int i = 0; i < drivers; i++)begin
            driver_monitor_inst[i] = new(i + 1);   //Los construyo y les digo cual es su terminal
        
        end

        //Conexion de las interfaces y mailboxes en el ambiente
        for (int i = 1; i <= drivers; i++) begin
            //Mailboxes
            driver_monitor_inst[i].inst_driver.agente_driver    = agente_driver[i];
            driver_monitor_inst[i].inst_monitor.agente_monitor   = agente_monitor[i];
            
            //Interfaz
            driver_monitor_inst[i].inst_driver.fifo_in.rst      = _FIFOS.rst  //corregir esto.
            driver_monitor_inst[i].inst_driver.fifo_in.pnding   = _FIFOS.pnding[i];
            driver_monitor_inst[i].inst_monitor.fifo_out.push   = _FIFOS.push[i];
            driver_monitor_inst[i].inst_monitor.fifo_out.pop    = _FIFOS.pop[i];
            driver_monitor_inst[i].inst_driver.fifo_in.D_pop    = _FIFOS.D_pop[i];
            driver_monitor_inst[i].inst_monitor.fifo_out.D_push = _FIFOS.D_push[i];
        end
    endfunction

    virtual task run();
        $display("[%g]  El ambiente fue inicializado",$time);

        for (int i = 0; i < drivers; i++)begin //Se debe usar un for porque hay que hacer que cada uno haga run
            fork
                driver_monitor_inst[i].run();
            join_none
        end
    endtask 
endclass