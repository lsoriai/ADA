--LEIRE SORIA INDIANO
		
with Ada.Text_IO;
with Lower_Layer_UDP;
with Pantalla;
with Debug;

package body Manejador is

	package TIO renames Ada.Text_IO;
	
	procedure Ctrl_C_Handler is
	begin
		TIO.New_Line;
		Debug.Put_Line("Has Pulsado CTRL_C... terminamos", Pantalla.Azul_Claro);
		raise Program_Error;
	end Ctrl_C_Handler;
end Manejador;
