`timescale 1ns / 1ps
//`include "driver.sv"


//Definicion de las posibles transacciones para el bus 
typedef enum {envio, broadcast, reset} tipo_trans; 


//Transaccione que entran y salen del DUT  (Creo que hay que meter esto en un array)
class trans_bus #(parameter width = 16, drivers = 8);
    int                 max_retardo;    //Retardo maximo por transaccion.
    rand int            retardo;        //Duracion de envio de cada dato
    logic [width - 1:0] paquete;        //Dato a enviar
    rand tipo_trans     tipo;           //envio, broadcast, reset
    int                 tiempo          //Representa el tiempo en el que se ejecuto una transaccion
    rand int            driver;         //valor del driver a hacer la transaccion
    
    //El paquete se divide en dos pedazos
    rand logic [7:0] ID;
    rand logic [7:0] ID_unknown;
    rand logic [7:0] payload;  //payload

    assign paquete = {ID,payload};  //Uniendo el broadcast con el paquete. Se puede ??

    constraint id    {ID <= 8'd8; ID > 8'd0;}; //Limites del broadcast
    constraint id_unk{id_unk > 8'd8;}; //Pone por fuera de los limites el ID
    constraint delay {retardo <= max_retardo; retardo >= 0}; //Debe ser menor a un retardo maximo
    constraint fifos {driver <= drivers; driver > 0;}; //Aqui se se necesta el numero de un driver aleatorio
                                                       //Usar el driver especifico
    

    function new (int retardo, int max_retardo, logic [7:0] id, logic [7:0] payload, logic [width - 1:0] paquete,  tipo_trans tipo, int tmp, int driver, logic [7:0] id_unk);  
        this.max_retardo = max_retardo;
        this.retardo     = retardo;
        this.ID          = id;
        this.payload     = payload;
        this.tipo        = tipo;
        this.tiempo      = tmp;
        this.paquete     = paquete;
        this.driver      = driver;
        this.ID_unknown  = id_unk;
    endfunction
    
    function clean();
        this.max_retardo = 0;
        this.retardo     = 0;
        this.ID          = 0;
        this.payload     = 0;
        this.tipo        = 0;
        this.paquete     = 0;
        this.tiempo      = 0;
        this.driver      = 0;
        this.ID_unknown  = 0;
    endfunction
    
    function void print(string tag = "");
        $display("[%g] %s Retardo=%g Tipo=%s Paquete=%g tiempo= %g",$time,tag,this.retardo,this.tipo,this.paquete,this.tiempo);
    endfunction
endclass

//Interface FIFOS
interface fifos #(parameter width = 16, depth = 8, drivers = 8, bits = 1, pkg = 16)(
    input clk
    );
    logic rst;
    logic pndng  [bits - 1:0][drivers - 1:0];
    logic push   [bits - 1:0][drivers - 1:0]; //push a la fifo
    logic pop    [bits - 1:0][drivers - 1:0]; //pop a la fifo
    logic [pkg - 1:0]D_pop [bits - 1:0][drivers - 1:0]; //Pkg de entrada
    logic [pkg - 1:0]D_push[bits - 1:0][drivers - 1:0]; //Pkg de salida
endinterface
    
    
    
//Objeto de transaccion usado en el scoreboard



//Definicion de estructura de datos para generar comandos al scoreboard
typedef enum {retardo_promedio,reporte} solicitud_sb;

//Definicion de estructura para generar comandos hacia el agente
typedef enum {envio_aleatorio, broadcast_aleatorio, reset_half_sent, all_for_one, all_broadcast, one_for_one, unknown_ID} instrucciones_agente;



//Mailboxes

typedef mailbox #(trans_bus) trans_bus_mbx;   //Comunica al driver con el agente y con el checker
typedef mailbox #()agente_driver_mbx;  //Comunica al agente con el driver
typedef mailbox #(instrucciones_agente)test_agente_mbx; //Comunica al test con el agente 
