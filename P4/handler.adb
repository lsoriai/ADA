with Ada.Text_IO;
With Ada.Strings.Unbounded;
with Maps_G;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Lower_Layer_UDP;
with Maps_Protector_G;

pakcage body Chat_Handlers is
	 package ASU  renames Ada.Strings.Unbounded;
	 package ATIO renames Ada.Text_IO;
	 package C_IO renames Gnat.Calendar.Time_IO;
	 package LLU renames Lower_Layer_UDP;
	 use type ASU.Unbounded_STring;

	 function Image_Hora (T: Ada.Calendar.Time) return String is
   		begin
     			return C_IO.Image(T, "%T.%i");
   		end Image_Hora;
   	
   	--function Direccion_IP (EP: LLU.End_Point_Type) return ASU.Unbounded_String is
   		--Imagen_EP: ASU.Unbounded_String;
   		--Frase: ASU.Unbounded_String;
		--Posicion : Natural;
		--IP : ASU.Unbounded_String;
   		--begin
   		--	Imagen_EP := ASU.To_Unbounded_String(LLU.Image(EP));
   		--	Frase := Imagen_EP;
   		--	Posicion := ASU.Index(Frase, "IP: ");
   		--	Frase := ASU.Tail(Frase, ASU.Length(Frase) - Posicion);
   		--	return IP;
   		--end Direccion_IP;
   
end Chat_Handlers;
