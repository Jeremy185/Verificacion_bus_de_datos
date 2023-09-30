
//Driver/monitor

class monitor #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    trans_bus_mbx agente_monitor;
    virtual FIFO #(.width(width)) fifo_out;

    bit [width-1:0] cola_out[$]; //Declaracion del queue del monitor que solo almacenas paquetes recibidos
                                //Corregir
    int   id;   //El id propio de cada terminal en logic para poderlo comparar con los ID de los paquetes


    function new(int terminal);
        this.id = terminal;
        cola_out.delete();
    endfunction

    task run();
        $display("[%g] La FIFO de salida %d fue inicializada",$time, id );
        
        forever begin
            trans_bus #(.width(width), .max_drivers(drivers)) transaccion;
            $display("[%g] La FIFO de salida %d espera por una transacción",$time, id);
            espera = 0;  //No creo que el retardo sea relevante en este caso
            
            @(posedge fifo_out.clk);
            agente_monitor.get(transaccion);
            transaccion.print_out("FIFO: Transaccion recibida");
            $display("Transacciones pendientes en el mailbox agente_monitor %d = %g",id,agente_monitor.num());

            while(fifo_out.push == 0)begin
                @(posedge fifo_out.clk);
            end

            case(transaccion.tipo)
                envio: begin
                    cola_out.push_back(fifo_out.D_push); //Aqui cuando detecta una señal de pull entonces envia el dato.
                    $display("FIFO out %d recibio el dato ")
                    //transaccion.print_out("Driver: Transaccion ejecutada");
                end
            endcase


        end
    endtask
endclass




class driver #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    trans_bus_mbx agente_driver;
    virtual FIFO #(.width(width)) fifo_in;  //declaracion del queue del driver    
    trans_bus cola_in[$];
    
    
    int espera;                     //Variable que hace el retardo
    int id;                         //Valor del id
    function new(int terminal);
        this.id = terminal;         //Da el valor correspondiente a la terminal
        cola_in.delete();           //Inicializa la cola
    endfunction 

    task run();
        $display("[%g] La FIFO de entrada %d fue inicializada",$time, id );
        @(posedge fifo_in.clk);
        fifo_in.rst = 1;
        @(posedge fifo_in.clk);

        forever begin 
            trans_bus #(.width(width), .max_drivers(drivers)) transaccion;
            fifo_in.pnding = 0;  //Pongo la señal de pending que va a la entrada del dut en 0
            fifo_in.D_pop  ='0;  //Pongo todos los bits del paquete en 0 bits 
            fifo_in.rst    = 0;  //Pongo el reset en 0.


            $display("[%g]El driver %d espera por transaccion", $time, id);
            espera = 0;

            @(posedge fifo_in.clk);
            agente_driver.get(transaccion); //obtengo la transaccion del mailbox
            transaccion.print("Driver: Transaccion recibida");
            $display("Transacciones pendientes en el mailbox agente_driver %d = %g",id,agente_driver.num());
            
            while(espera < transaccion.retardo)begin //Hago un retardo
                @(posedge fifo_in.clk);
                espera = espera + 1;
            end

            cola_in.push_back(transaccion); //Meto el dato dentro del queue
            @(posedge fifo_in.clk);

            case(transaccion.tipo)
                envio: begin
                    fifo_in.D_pop = cola_in.pop_front;
                    @(posedge fifo_in.clk);
                    fifo_in.pnding = 1;             //Ya el dut puede tomar el dato
                    @(posedge fifo_in.clk);
                end
            endcase
            @(posedge fifo_in.clk);
        end

    endtask

endclass

class driver_monitor #(parameter width = 16, parameter depth = 8, parameter drivers = 4);
    
    //mailboxes
    trans_bus_mbx agente_driver;
    trans_bus_mbx agente_monitor;

    //Interfaces
    virtual FIFO #(.width(width)) fifo_out;
    virtual FIFO #(.width(width)) fifo_in; 

    //Componentes
    monitor #(.width(width), .depth(depth), .drivers(drivers)) inst_monitor;
    driver #(.width(width), .depth(depth), .drivers(drivers)) inst_driver;
    int id;

    function new(int terminal);
        this.id = terminal;
        //instanciacion del driver y el monitor
        inst_driver = new(terminal);
        inst_monitor = new(terminal);

        //Conexion de los mailboxes
        inst_monitor.agente_monitor = agente_monitor;
        inst_driver.agente_driver = agente_driver;

        //Conecto las interfaces
        inst_monitor.fifo_out = fifo_out;
        inst_driver.fifo_in = fifo_in;
    endfunction 


    virtual task run();  //Aqui corro en paralelo el driver y el monitor (en el ambiente se corre en paralelo solo los drivers_monitores)
        $display("[%g] El driver_monitor fue inicializado [%d]", $time, id)
        fork
            inst_monitor.run();
            inst_driver.run();
        join_none
    endtask
    
endclass