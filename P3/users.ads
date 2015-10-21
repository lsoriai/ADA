 with Ada.Strings.Unbounded;
 with Lower_Layer_UDP;
 with Ada.Calendar;
 with Chat_messages;
 
 package Users is
 
 	package ASU renames Ada.Strings.Unbounded;
 	package LLU renames Lower_Layer_UDP;
 	package AC renames Ada.Calendar;
	package CM renames Chat_messages;
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	use type Ada.Calendar.Time;
 	
 	type Clientes is private;
 	
 	procedure Buscar_Cliente (Lista: Clientes;
 				  Nick: ASU.Unbounded_String;
 				  Tope: Natural;
 				  Cliente: Natural;
 				  Repetido: in out Boolean);
 	
 	
 	procedure Aniadir_Cliente (Lista: in out Clientes;
 				   Nick: ASU.Unbounded_String;
 				   Tope: Natural;
 				   Client_EP_Handler: LLU.End_Point_Type;
 				   Cliente: in out Natural);
 				   
 	procedure Buscar_Nick (Client_EP_Handler: LLU.End_Point_Type;
			       Lista: Clientes;
			       Nick: in out ASU.Unbounded_String;
			       Tope: Natural;
			       Cliente: Natural);
			       
	procedure Actualizar (Lista: in out Clientes;
			      Nick: ASU.Unbounded_String;
			      Tope: Natural;
			      Cliente: Natural);
			      
	procedure Enviar_Clientes (Lista: Clientes;
				  Nick: ASU.Unbounded_String;
				  Comentario: ASU.Unbounded_String;
				  P_Buffer: access LLU.Buffer_Type;
				  Tope: Natural;
				  Cliente: Natural);
			
	procedure Borrar_Cliente (Lista: in out Clientes;
				  Client_EP_Handler: LLU.End_Point_Type;
				  Tope: Natural;
				  Cliente: Natural);
				  
	procedure Enviar_Salida (Lista: Clientes;
				Nick: ASU.Unbounded_String;
		  		P_Buffer: access LLU.Buffer_Type;
				Tope: Natural;
				EP_Handler: LLU.End_Point_Type;
				Cliente: Natural);
 
 	private
 	
	type Datos_Cliente;
 	
 	type Clientes is access Datos_Cliente;
 	 
 	type Datos_Cliente is record
 		Nick: ASU.Unbounded_String := ASU.Null_Unbounded_String;
 		EP_Handler: LLU.End_Point_Type := null;
 		Tiempo: AC.Time := AC.Clock;
 		Next: Clientes;
 	end record;
 
 end Users;
