`timescale 1ns / 1ps
//`include "driver.sv"

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/25/2023 08:45:21 AM
// Design Name: 
// Module Name: interface_transactions
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//Definicion de los tipos de transacciones
//Transaccion: transacciones que salen y entran del bus de datos
typedef enum {envio, scoreboard, reset} tipo_trans; 


//Transaccione que entran y salen del DUT
class trans_bus #(parameter width = 16, depth = 8);
    int                 max_retardo;
    rand int            retardo;        //Duracion de envio de cada dato
    bit   [width - 1:0] paquete;        //Dato a enviar
    rand int            transacciones;  //Cantidad de transacciones
    int                 max_trans;      //Cantidad de transacciones maximas
    int                 min_trans;      //Cantidad de transacciones minimas 
    rand tipo_trans     tipo;           //envio, scoreboard, reset
    
    constraint transac {min_trans <= transacciones; transacciones <= max_trans;}; //Cantidad de transacciones entre 100 y 200
    constraint delay {retardo <= max_retardo;};    //Debe ser menor a un retardo maximo
    
    
    function new (int retardo, int max_retardo, bit [width - 1:0] paquete, int transacciones, int max_trans, int min_trans, tipo_trans tipo);  
        this.max_retardo = max_retardo;
        this.retardo = retardo;
        this.paquete = paquete;
        this.transacciones = transacciones;
        this.max_trans = max_trans;
        this.min_trans = min_trans;
        this.tipo      = tipo;
    endfunction
    
    function clean();
        this.max_retardo = 0;
        this.retardo = 0;
        this.paquete = 0;
        this.transacciones = 0;
        this.max_trans = 0;
        this.min_trans = 0;
    endfunction
    
    function void print(string tag = "");
        $display("[%g] %s Retardo=%g Tipo=%s Paquete=%g transacciones=0x%h",$time,tag,this.retardo,this.tipo,this.paquet,this.transacciones);
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
typedef mailbox #()trans_bus_mbx;   //Comunica al driver con el agente y con el checker
typedef mailbox #()agente_driver_mbx;  //Comunica al agente con el driver
typedef mailbox #(instrucciones_agente)test_agente_mbx; //Comunica al test con el agente 


    
    

