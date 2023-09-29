class ambiente #(parameter width = 16,  parameter depth = 8, parameter drivers = 4 );

    //Declaracion de los componentes del ambiente
    driver_monitor #() driver_monitor_inst[];

    //Declaracion de la interface que conecta con el DUT
    virtual FIFOS #(.width(16), .drivers(8), .bits(1));


    //Declaracion de los mailboxes 
    trans_bus_mbx agente_monitor[4];  
    trans_bus_mbx agente_driver[4];

    


endclass