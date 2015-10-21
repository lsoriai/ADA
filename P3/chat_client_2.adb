-- Leire Soria Indiano
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;
with Handlers;

procedure chat_client_2 is
   	package LLU renames Lower_Layer_UDP;
   	package ASU renames Ada.Strings.Unbounded;
   	package ACL renames Ada.Command_Line;
  	package CM renames Chat_Messages;
  	package TIO renames ADA.Text_IO;
	use type CM.Message_Type;
	use type ASU.Unbounded_String;

   	Server_EP: LLU.End_Point_Type;
   	Client_EP_Receive: LLU.End_Point_Type;
   	Client_EP_Handler: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Expired: Boolean := False;
	Usage_Error: exception;
	Nick_Error: exception;
	Tipo: CM.Message_Type;
	Nick: ASU.Unbounded_String;
	Acogido: Boolean;
	Comentario: ASU.Unbounded_String;
		
begin
	if ACL.Argument_Count /= 3 then
		raise Usage_Error;
	end if;
	
	if ACL.Argument(3) = "servidor" then
		raise Nick_Error;
	else
		Server_EP := LLU.Build(LLU.To_IP(ACL.Argument(1)), Natural'Value(ACL.Argument(2)));
	   	LLU.Bind_Any (Client_EP_Receive);
	   	LLU.Bind_Any (Client_EP_Handler, Handlers.Client_Handler'Access);
   		Tipo := CM.Init;
   		Nick := ASU.To_Unbounded_String(ACL.Argument(3));
   		LLU.Reset(Buffer);
   		CM.Message_Type'Output (Buffer'Access, Tipo);
		LLU.End_Point_Type'Output (Buffer'Access, Client_EP_Receive);
		LLU.End_Point_Type'Output (Buffer'Access, Client_EP_Handler);
		ASU.Unbounded_String'Output (Buffer'Access, Nick);
		LLU.Send(Server_EP, Buffer'Access);
  		LLU.Reset(Buffer);
  		LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);
			if Expired then
	      			TIO.Put_Line ("No es posible comunicarse con el servidor");
	   		else 
	   			Tipo := CM.Message_Type'Input(Buffer'Access);
	   			Acogido := Boolean'Input(Buffer'Access);
	   			if Acogido = True then
	   				TIO.Put_Line ("Mini-Chat v2.0: Bienvenido " & ASU.To_String(Nick) & " !");
	   				Tipo := CM.Writer;
	   				loop 
	   					TIO.Put(">>");
		   				Comentario := ASU.To_Unbounded_String(TIO.Get_Line);
		   				if Comentario /= ".salir" then
		   					LLU.Reset(Buffer);
			   				CM.Message_Type'Output (Buffer'Access, Tipo);
							LLU.End_Point_Type'Output (Buffer'Access, Client_EP_Handler);
							ASU.Unbounded_String'Output (Buffer'Access, Comentario);
							LLU.Send(Server_EP, Buffer'Access);
						else
							Tipo := CM.Logout;
							LLU.Reset(Buffer);
							CM.Message_Type'Output (Buffer'Access, Tipo);
							LLU.End_Point_Type'Output (Buffer'Access, Client_EP_Handler);
							LLU.Send(Server_EP, Buffer'Access);
						end if;
						exit when Comentario = ".salir";
					end loop;
					
	   			else
	   				TIO.Put_Line ("Mini-Chat v2.0: Cliente rechazado porque el nickname " &
	   				              ASU.To_String(Nick) & " ya existe en este servidor.");
	   			end if;
	   		end if;
	end if;
	LLU.Finalize;

	exception
	
		when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos invalidos");
		
		when Nick_Error =>
		TIO.Put_Line ("Nick incorrecto. No se permite poner servidor como nick");	
		
		when Ex:others => 
		TIO.Put_Line("EXcepción imprevista: " &
		Ada.Exceptions.Exception_Name(Ex) & " /en: " &
		Ada.Exceptions.Exception_Message(Ex));
		
	LLU.Finalize;

end chat_client_2;
