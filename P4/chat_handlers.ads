with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Lower_Layer_UDP;
with Maps_Protector_G;
with Chat_Messages;
with debug;
with Pantalla;

package Chat_Handlers is     

	 package ASU  renames Ada.Strings.Unbounded;
	 package TIO renames Ada.Text_IO;
	 package C_IO renames Gnat.Calendar.Time_IO;
	 package LLU renames Lower_Layer_UDP;
	 package CM renames Chat_messages;
	 package AC renames Ada.Calendar;
	 use type ASU.Unbounded_String;
	 use type CM.Message_Type;
	 use type LLU.End_Point_Type;
    
         type Seq_N_T is mod Integer'Last;
         
         function Image_Hora (T: Ada.Calendar.Time) return String;
         
         Maximo_Nodos: Integer := 10; 
         Maximo_SMS: Integer := 50;	
         
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

	 package Neighbors is new Maps_Protector_G (NP_Neighbors);
	 package Latest_Msgs is new Maps_Protector_G (NP_Latest_Msgs);
	 

	 
	 procedure Handler (From    : in     LLU.End_Point_Type;
                            To      : in     LLU.End_Point_Type;
                            P_Buffer: access LLU.Buffer_Type);
	 
	 Vecinos : Neighbors.Prot_Map;
	 Mensajes: Latest_Msgs.Prot_Map;
	 Mi_Nick: ASU.Unbounded_String;

	function Direccion_IP (EP: LLU.End_Point_Type) return String;
	
	 
end Chat_Handlers;
