with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Lower_Layer_UDP;
with Maps_Protector_G;
with Chat_Messages;
with Debug;
with Pantalla;
with Ordered_Maps_G;
with Ordered_Maps_Protector_G;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

package Chat_Handlers is     

	 package ASU  renames Ada.Strings.Unbounded;
	 package TIO renames Ada.Text_IO;
	 package C_IO renames Gnat.Calendar.Time_IO;
	 package LLU renames Lower_Layer_UDP;
	 package CM renames Chat_Messages;
	 package AC renames Ada.Calendar;
	 use type ASU.Unbounded_String;
	 use type CM.Message_Type;
	 use type LLU.End_Point_Type;
	 
         Maximo_Nodos: Integer := 10;
    	 Maximo_SMS: Integer := 50;	
         
         type Seq_N_T is mod Integer'Last;
         
         type Mess_Id_T is record
		EP: LLU.End_Point_Type;
		Seq: Seq_N_T;
	 end record;
			
	 type Destination_T is record
		EP: LLU.End_Point_Type := null;
		Retries : Natural := 0;
	 end record;
			
	 type Destinations_T is array (1..10) of Destination_T;

	 type Value_T is record
		EP_H_Creat: LLU.End_Point_Type;
		Seq_N: Seq_N_T;
		P_Buffer: CM.Buffer_A_T;
	 end record;

        function Image_Hora (T: Ada.Calendar.Time) return String;
        function Direccion_IP (EP: LLU.End_Point_Type) return String;
	function Menor (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;
	function Mayor (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;
	function Igual (M1: Mess_Id_T; M2: Mess_Id_T) return Boolean;
	function Image_Mess (M: Mess_Id_T) return String; 
	function Array_Destinos (D: Destinations_T) return String;
	function Value_Image (V: Value_T) return String;
	procedure Handler (From    : in     LLU.End_Point_Type;
                      	   To      : in     LLU.End_Point_Type;
                      	   P_Buffer: access LLU.Buffer_Type);
	 
	

  	 package NP_Neighbors is new Maps_G (Key_Type   => LLU.End_Point_Type,
                                       	     Value_Type => Ada.Calendar.Time,
                                             Null_Key => null,
                                             Null_Value => Ada.Calendar.Time_Of(2003,5,5),
                                             Max_Length => Maximo_Nodos,
                                             "="        => LLU."=",
                                             Key_To_String  => LLU.Image,
                                             Value_To_String  => Image_Hora);
                               
	 package NP_Latest_Msgs is new Maps_G (Key_Type   => LLU.End_Point_Type,
                                               Value_Type => Seq_N_T,
                                               Null_Key => null,
                                               Null_Value => 99999,
                                               Max_Length => Maximo_SMS,
                                               "="        => LLU."=",
                                               Key_To_String  => LLU.Image,
                                               Value_To_String  => Seq_N_T'Image);
                                           
    	package NP_Sender_Dests is new ordered_maps_g (Key_Type => Mess_Id_T,
    						       Value_Type => Destinations_T,
    						       "=" => Igual,
    						       "<" => Menor,
    						       ">" => Mayor,
  					               Key_To_String => Image_Mess,
    						       Value_To_String => Array_Destinos);

	package NP_Sender_Buffering is new Ordered_maps_g (Key_Type => AC.Time,
							   Value_Type => Value_T,
 							   "=" => AC."=",
    						           "<" => AC."<",
    						           ">" => AC.">",
							   Key_To_String => Image_Hora,
							   Value_To_String => Value_Image);


	procedure Retransmision (Tiempo: in AC.Time);

	procedure Preparar_Retransmitir (EP_H_Creat: LLU.End_Point_Type;
					 Seq_N: Seq_N_T;
				 	 Buffer_Datos: CM.Buffer_A_T;
					 EP_H_Rsnd1: LLU.End_Point_Type);

	procedure Enviar_ACK (EP_H_Creat: LLU.End_Point_Type;
			      Seq_N: Seq_N_T;
			      EP_H_Acker: LLU.End_Point_Type;
			      EP_H_Rsnd: LLU.End_Point_Type);

	procedure Recibir_ACK (EP_H_Acker: LLU.End_Point_Type;
			       EP_H_Creat: LLU.End_Point_Type;
			       Seq_N: Seq_N_T);
	package Neighbors is new Maps_Protector_G (NP_Neighbors);
	package Latest_Msgs is new Maps_Protector_G (NP_Latest_Msgs);
	package Sender_Dests is new Ordered_Maps_Protector_G (NP_Sender_Dests);
	package Sender_Buffering is new Ordered_Maps_Protector_G (NP_Sender_Buffering);

	Vecinos : Neighbors.Prot_Map;
	Mensajes: Latest_Msgs.Prot_Map;
	Destinos: Sender_Dests.Prot_Map;
	Buffer: Sender_Buffering.Prot_Map;
	Mi_Nick: ASU.Unbounded_String;
	Plazo_Retransmision: Duration;
	Debug_Status: Boolean:= True;

	 
end Chat_Handlers;
