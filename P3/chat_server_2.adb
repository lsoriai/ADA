--Leire Soria Indiano
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Calendar;
with Ada.Command_Line;
with chat_messages;
with Users;

procedure chat_server_2 is
   	package LLU renames Lower_Layer_UDP;
   	package ASU renames Ada.Strings.Unbounded;
   	package ACL renames Ada.Command_Line;
	package TIO renames Ada.Text_IO;
	package CM renames chat_messages;
	package AC renames Ada.Calendar;
	
	use type CM.Message_Type;
	use type LLU.End_Point_Type;
	use type ASU.Unbounded_String;
	
   	Server_EP: LLU.End_Point_Type;
   	Buffer: aliased LLU.Buffer_Type(1024);
  	Comentario: ASU.Unbounded_String;
  	Expired: Boolean := False;
   	Usage_Error: exception;
   	Cliente_Error: exception;
	Lista_Clientes: Users.Clientes;
	i: Natural := 0;
	Nick: ASU.Unbounded_String;
	Tope: Natural;
	Client_EP_Handler: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Tipo: CM.Message_Type;
	Repetido: Boolean := False;
	Acogido: Boolean;
	Num_Clientes_T: Natural := 0;
		

begin

	if ACL.Argument_Count /= 2 then
		raise Usage_Error;
	end if;
	
	if Natural'Value(ACL.Argument(2)) < 2 then
		raise Cliente_Error;
	end if;
	
	Server_EP := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Natural'Value(ACL.Argument(1)));
   	LLU.Bind (Server_EP);
   	Tope := Natural'Value(ACL.Argument(2));
   	
   	if ACL.Argument_Count /= 2 then
		raise Usage_Error;
	end if;
	
	if Tope < 2 or Tope > 50 then
		raise Cliente_Error;
	end if;
	
	loop
		LLU.Reset(Buffer);
 		LLU.Receive (Server_EP, Buffer'Access, 1000.0, Expired);
 		if Expired then
         		Ada.Text_IO.Put_Line ("Plazo expirado, vuelvo a intentarlo");
     		else
			Tipo := CM.Message_Type'Input (Buffer'Access);
         		if Tipo = CM.Init then
				Client_EP_Receive := LLU.End_Point_Type'Input (Buffer'Access);
				Client_EP_Handler := LLU.End_Point_Type'Input (Buffer'Access);
		 		Nick := ASU.Unbounded_String'Input (Buffer'Access);
				Users.Buscar_Cliente (Lista_Clientes, Nick, Tope, Num_Clientes_T, Repetido);
				if Repetido = True then
					Tipo := CM.Welcome;
					Acogido := False;
					LLU.Reset(Buffer);
					CM.Message_Type'Output(Buffer'Access, Tipo);
					Boolean'Output(Buffer'Access, Acogido);
					LLU.Send(Client_EP_Receive, Buffer'Access);
					TIO.Put_Line("Recibido mensaje inicial de " &
						      ASU.To_String(Nick) & ": RECHAZADO.");
				else
					Tipo := CM.Welcome;
					Acogido := True;
					--TIO.Put_Line("Antes de añadir");
					--Users.Mostrar_Lista(Lista_Clientes, Tope);
					Users.Aniadir_Cliente(Lista_Clientes, Nick, Tope, Client_EP_Handler,
							      Num_Clientes_T);
				   	--TIO.Put_Line("Después de añadir");
				  	--Users.Mostrar_Lista(Lista_Clientes, Tope);
					LLU.Reset(Buffer);
					CM.Message_Type'Output(Buffer'Access, Tipo);
					Boolean'Output(Buffer'Access, Acogido);
					LLU.Send(Client_EP_Receive, Buffer'Access);
					TIO.Put_Line("Recibido mensaje inicial de " &
						     ASU.To_String(Nick) & ": ACEPTADO");
				end if;
			elsif Tipo = CM.Writer then
				
				Client_EP_Handler := LLU.End_Point_Type'Input (Buffer'Access);
				Comentario := ASU.Unbounded_String'Input (Buffer'Access);
				Users.Buscar_Nick (Client_EP_Handler, Lista_Clientes, Nick, Tope, Num_Clientes_T);
				Users.Actualizar (Lista_Clientes, Nick, Tope, Num_Clientes_T);
				LLU.Reset(Buffer);
				TIO.Put_Line("Recibido mensaje de " & ASU.To_String(Nick) & ": "
					     & Asu.To_String(Comentario));
				Users.Enviar_Clientes (Lista_Clientes, Nick, Comentario, 
						       Buffer'Access, Tope, Num_Clientes_T);
			elsif Tipo = CM.Logout then
				Client_EP_Handler := LLU.End_Point_Type'Input (Buffer'Access);
				LLU.Reset(Buffer);
				Users.Buscar_Nick (Client_EP_Handler, Lista_Clientes, Nick, Tope, Num_Clientes_T);
				TIO.Put_Line("Recibido mensaje de salida de " & ASU.To_String(Nick));
				Users.Enviar_Salida (Lista_Clientes, Nick, Buffer'Access, Num_Clientes_T, Client_EP_Handler, Num_Clientes_T);
				Users.Borrar_Cliente(Lista_Clientes, Client_EP_Handler, Tope, Num_Clientes_T);
				Num_Clientes_T := Num_Clientes_T - 1;
				
			end if;
		end if;
	end loop;

  
exception
	
	when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos no validos" &
				      "<Nombre_Maquina> <Puerto> <Nick>");
		
	when Cliente_Error =>
		Ada.Text_IO.Put_Line ("Numero de clientes incorrectos. Obligatoriamente mayor que 2 y menor de 50");
		
	when Ex:others => 
		TIO.Put_Line("EXcepción imprevista: " &
		Ada.Exceptions.Exception_Name(Ex) & "/en: " &
		Ada.Exceptions.Exception_Message(Ex));
		
	LLU.Finalize;
end chat_server_2;
