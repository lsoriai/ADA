-- Leire Soria Indiano
with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Command_Line;
with Chat_Messages;

procedure chat_client is
   	package LLU renames Lower_Layer_UDP;
   	package ASU renames Ada.Strings.Unbounded;
   	package ACL renames Ada.Command_Line;
  	package CM renames Chat_Messages;
  	package TIO renames ADA.Text_IO;
	use type CM.Message_Type;
	use type ASU.Unbounded_String;

	procedure Enviar_Init (Mensaje: in CM.Mensaje; Buf: in out LLU.Buffer_Type; Server_EP: LLU.End_Point_Type) is
		begin
			CM.Message_Type'Output (Buf'Access, Mensaje.Tipo);
			LLU.End_Point_Type'Output (Buf'Access, Mensaje.EP);
			ASU.Unbounded_String'Output (Buf'Access, Mensaje.Comentario);
			LLU.Send(Server_EP, Buf'Access);
		end Enviar_Init;
		
	procedure Enviar_Datos (Mensaje: in out CM.Mensaje; Buf: in out LLU.Buffer_Type; 
				Server_EP: LLU.End_Point_Type; Client_EP: LLU.End_Point_Type) is
		begin
			loop	
				LLU.Reset(Buf);
	  			TIO.Put ("Mensaje: ");
	  			Mensaje.Comentario := ASU.To_Unbounded_String(TIO.Get_Line);
	  			Mensaje.Tipo := CM.Writer;
	  			Mensaje.EP := Client_EP;
	  			if ASU.To_String(Mensaje.Comentario) /= ".salir" then
	  				CM.Message_Type'Output (Buf'Access, Mensaje.Tipo);
					LLU.End_Point_Type'Output (Buf'Access, Mensaje.EP);
					ASU.Unbounded_String'Output (Buf'Access, Mensaje.Comentario);
				end if;
				LLU.Send(Server_EP, Buf'Access);
				exit when Mensaje.Comentario = ".salir";
			end loop;
		end Enviar_Datos;

	procedure Recibir_Datos (Expired: in out Boolean; Buf: in out LLU.Buffer_Type; 
				 Client_EP: LLU.End_Point_Type; Mensaje: CM.MEnsaje) is

		Comentario: ASU.Unbounded_String;
		Persona: ASU.Unbounded_String;	
		Tipo: CM.Message_Type;

		begin	
			loop	
				LLU.Reset(Buf);
				LLU.Receive(Client_EP, Buf'Access, 1000.0, Expired);
				if Expired then
	      				Ada.Text_IO.Put_Line ("Plazo expirado");
	   			else
	   				
					Tipo:= CM.Message_Type'Input (Buf'Access);
					Persona := ASU.Unbounded_String'Input(Buf'Access);
					Comentario := ASU.Unbounded_String'Input(Buf'Access);
					Ada.Text_IO.Put(ASU.To_String(Persona) & ": ");
					Ada.Text_IO.Put_Line(ASU.To_String(Comentario));
					
				end if;
			end loop;
		end Recibir_Datos;

   	Server_EP: LLU.End_Point_Type;
   	Client_EP: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(1024);
	Expired: Boolean := False;
	Usage_Error: exception;
	Mensaje: CM.Mensaje;
		
begin
	if ACL.Argument_Count /= 3 then
		raise Usage_Error;
	end if;

	Server_EP := LLU.Build(LLU.To_IP(ACL.Argument(1)), Natural'Value(ACL.Argument(2)));
   	LLU.Bind_Any (Client_EP);
   	
   	Mensaje.Comentario := ASU.To_Unbounded_String(ACL.Argument(3));
  	Mensaje.Tipo := CM.Init;
	Mensaje.EP := CLient_EP;

  	Enviar_Init(Mensaje, Buffer, Server_EP);
  
  	if (ACL.Argument(3)) /= "lector" then
		Enviar_Datos(Mensaje, Buffer, Server_EP, Client_EP);
		LLU.Finalize;
  	else
		Recibir_Datos(Expired, Buffer, Client_EP, Mensaje);
		LLU.Finalize;
  	end if;

	exception
		when Ex:others => 
		TIO.Put_Line("EXcepción imprevista: " &
		Ada.Exceptions.Exception_Name(Ex) & "en: " &
		Ada.Exceptions.Exception_Message(Ex));
		
		when Usage_Error =>
		Ada.Text_IO.Put_Line ("Argumentos invalidos");
	LLU.Finalize;

end chat_client;
