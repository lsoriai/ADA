with Ada.Text_IO;
with Ada.Strings.Unbounded;
with chat_messages;

package body Handlers is
	package TIO renames Ada.Text_IO;
   	package ASU renames Ada.Strings.Unbounded;
   	package CM renames chat_messages;


	procedure Client_Handler (From: in LLU.End_Point_Type;
                                  To: in LLU.End_Point_Type;
                                  P_Buffer: access LLU.Buffer_Type) is 
                             
	Comentario: ASU.Unbounded_String;
	Nick: ASU.Unbounded_String;
	Tipo: CM.Message_Type;
      
		begin
	   
			Tipo := CM.Message_Type'Input(P_Buffer);
			Nick := ASU.Unbounded_String'Input(P_Buffer);
			Comentario := ASU.Unbounded_String'Input(P_Buffer);
			TIO.Put_Line("");
		      	TIO.Put_Line(ASU.To_String(Nick) & ": " & ASU.To_String (Comentario));
		      	TIO.Put(">>");

		end Client_Handler;

end Handlers;

