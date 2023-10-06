`include "Ambiente.sv"

class test#(parameter width = 16, parameter depth = 8, parameter drivers = 4, parameter bc ={8{1'b1}});

    //Mailboxes
    test_agente_mbx test_agente; //Envia la instruccion al agente
    test_agente_mbx test_checker; //Envia la instruccion al checker

    parameter num_transacciones = 50;
    parameter max_retardo = 10;
    instrucciones_agente instruccion;

    //Definicion del ambiente de la prueba
  	ambiente #(.width(width),  .depth(depth), .drivers(drivers), .broadcast(bc), .n_transacs(num_transacciones), .max_retardo(max_retardo)) ambiente_inst;

    //Definicion de la interfaz
    virtual FIFOS #(.width(width), .drivers(drivers), .bits(1)) _FIFOS;


    //Definicion de las condiciones iniciales del test
    function new;
        //instanciacion de los mailboxes
        test_agente = new();
        test_checker = new();
      	ambiente_inst = new();
      
      
        //Definicion y conexion del ambiente
        ambiente_inst.test_agente = test_agente;
        ambiente_inst.agente_inst.test_agente = test_agente;

        ambiente_inst.test_checker = test_checker;
        ambiente_inst.checker_inst.test_checker = test_checker;

        //Definino el retardo maximo y el numero de transacciones desde aqui
        ambiente_inst.agente_inst.num_transacciones = num_transacciones;
        ambiente_inst.agente_inst.max_retardo = max_retardo;


    endfunction

    task run;
        $display("[%g] El test fue inicializado", $time);

        fork
            ambiente_inst.run();
        join_none
		
        instruccion = envio_aleatorio;
       	test_agente.put(instruccion);
        test_checker.put(instruccion);
        $display("[%g] Test: Enviada primera instruccion al agente de envio aleatorio con num_transacciones %g", $time, num_transacciones);
      
      	//instruccion = all_for_one;
        //test_agente.put(instruccion);
        //test_checker.put(instruccion);
        //$display("[%g] Test: Enviada primera instruccion al agente de envio aleatorio con num_transacciones %g", $time, num_transacciones);
      
     

    endtask



endclass