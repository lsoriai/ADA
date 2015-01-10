--Leire Soria Indiano

with Ada.Strings.Unbounded;
package List is
	package ASU renames Ada.Strings.Unbounded;
	type Cell;
	type Cell_A is access Cell;
	type Cell is 
	record
		Name : ASU.Unbounded_String;
		Count: Natural := 0;
		Next : Cell_A;
	end record;
	
	procedure Inicializar (Lista: out Cell_A);
	procedure Aniadir (Lista: in out Cell_A; Palabra: ASU.Unbounded_String);
	procedure Buscar_Palabra (Lista : in out Cell_A;  Palabra: in out ASU.Unbounded_String);
	procedure Escribir_Palabras (Lista: Cell_A);
	procedure Borrar_Lista (Lista: in out Cell_A);
end List;

