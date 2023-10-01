
//Definicion de las posibles transacciones para el bus 
typedef enum {envio, broadcast, reset} tipo_trans; 


//Transaccione que entran y salen del DUT  (Creo que hay que meter esto en un array)

class trans_bus #(parameter width = 16, parameter max_drivers = 4);
    int                 max_retardo;    //Retardo maximo por transaccion.
    rand int            retardo;        //Duracion de envio de cada dato
    bit [width - 1:0]   paquete;        //Dato a enviar
    rand tipo_trans     tipo;           //envio, broadcast, reset
    int                 tiempo;         //Representa el tiempo en el que se ejecuto una transaccion
    rand int            driver;         //valor del driver que va a hacer a hacer la transaccion
    int                 destino;        //Con este id ya podre mandar desde el agente directamente al destino
    
    //El paquete se divide en dos pedazos
    rand bit [7:0] ID;
    rand bit [7:0] ID_unknown;
    rand bit [7:0] payload;  //payload

    //assign paquete = {ID,payload};  //Uniendo el broadcast con el paquete. Se puede

    constraint id    {ID < max_drivers + 1; ID > 0;}; //Limites del broadcast
    constraint id_unk{ID_unknown > max_drivers;}; //Pone por fuera de los limites el ID
  	constraint delay {retardo < max_retardo + 1; retardo > -1;}; //Debe ser menor a un retardo maximo
  	constraint fifos {driver < max_drivers + 1; driver > 0;}; //Aqui se se necesta el numero de un driver aleatorio
                                                       //Usar el driver especifico
    

    function new (int retardo = 0, int max_retardo = 0, bit [7:0] id = 8'b1, bit [7:0] payload = '0,  tipo_trans tipo = envio, int tmp = 0, int driver = 1, bit [7:0] id_unk = '0);  
        this.max_retardo = max_retardo;
        this.retardo     = retardo;  
        this.ID          = id;       
        this.payload     = payload;  
        this.tipo        = tipo;     
        this.tiempo      = tmp;
        this.paquete     = {id, payload};
        this.driver      = driver;
        this.ID_unknown  = id_unk;
        this.destino     = $bits(ID);  //Se le pone un atributo de destino a cada fifo de salida
    endfunction

   	//function set_pkg();
      //  this.paquete = {this.ID, this.payload};
    //endfunction
    
    function clean();
        this.max_retardo = 0;
        this.retardo     = 0;
        this.ID          ='0;
        this.payload     ='0;
        this.tipo        = envio;
        this.paquete     ='0;
        this.tiempo      = 0;
        this.driver      = 0;
        this.ID_unknown  ='0;
        this.destino     = 0;
    endfunction
    
    function void print_in(string tag = "");
      $display("[%g] %s Retardo=%g Tipo=%s ID=%b Payload=%b tiempo= %g FIFO_in = %d",$time,tag,this.retardo,this.tipo,this.ID, this.payload,this.tiempo, this.driver);
    endfunction

    function void print_out(string tag = "");
      $display("[%g] %s Retardo=%g Tipo=%s ID=%b Payload= %b tiempo = %g FIFO_out = %d",$time,tag,this.retardo,this.tipo,this.ID, this.payload, this.tiempo, this.destino);
    endfunction
endclass


//Interface FIFOS para conectar el sistema completo
interface FIFOS #(parameter width = 16, parameter drivers = 8, parameter bits = 1)(
    input clk
    );
    logic rst;
    logic pndng  [bits - 1:0][drivers - 1:0];
    logic push   [bits - 1:0][drivers - 1:0];             //push a la fifo
    logic pop    [bits - 1:0][drivers - 1:0];             //pop a la fifo
    logic [width - 1:0]D_pop [bits - 1:0][drivers - 1:0]; //Pkg de entrada
    logic [width - 1:0]D_push[bits - 1:0][drivers - 1:0]; //Pkg de salida
endinterface
    
//Interface de una sola fifo para conectar una sola a todo el sistema completo
interface FIFO #(parameter width = 16)(
    input clk
    );

    logic rst;
    logic pndng;
    logic push;                   //push a la fifo
    logic pop;                    //pop a la fifo
    logic [width - 1:0]D_pop ;    //Pkg de entrada
    logic [width - 1:0]D_push;    //Pkg de salida

endinterface

    
//Objeto de transaccion usado en el scoreboard



//Definicion de estructura de datos para generar comandos al scoreboard

//Definicion de estructura para generar comandos hacia el agente
typedef enum {envio_aleatorio, broadcast_aleatorio, reset_half_sent, all_for_one, all_broadcast, one_for_one, unknown_ID} instrucciones_agente;



//Mailboxes

typedef mailbox #(trans_bus) trans_bus_mbx;   //Comunica al driver con el agente y con el checker
