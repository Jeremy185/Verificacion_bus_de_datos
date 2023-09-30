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
        for (int i = 1; i<= drivers; i++)begin
            agente_monitor[i] = new();
            agente_driver[i] = new();
        end

        //instanciacion de los componentes del ambiente
        for (int i = 1; i <= drivers; i++)begin
            driver_monitor_inst[i] = new(i);   //Los construyo y les digo cual es su terminal
        
        end

        //Conexion de las interfaces y mailboxes en el ambiente
        for (int i = 1; i<= drivers; i++) begin
            driver_monitor_inst[i].agente_driver = agente_driver[i];
            driver_monitor_inst[i].agente_monitor = agente_monitor[i];
            driver_monitor_inst[i].fifo_in.rts = _FIFOS.rst[]  //corregir esto.
        end

        //Conexion especifica de las fifos con la entrada del DUT
        for (int i = 1)


    endfunction

    virtual task run();
        $display("[%g]  El ambiente fue inicializado",$time);
        fork
            driver_monitor.run();
        join_none
    endtask 
    

    


endclass