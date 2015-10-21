with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
With Ada.Strings.Unbounded;

package body Maps_g is

	package TIO renames Ada.Text_IO;
	package ASU  renames Ada.Strings.Unbounded;

	procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);

	procedure Get (M       : Map;
                       Key     : in  Key_Type;
                       Value   : out Value_Type;
                       Success : out Boolean) is
         P_Aux : Cell_A;
		begin
			P_Aux := M.P_First;
			Success := False;
			while not Success and P_Aux /= null Loop
				if P_Aux.Key = Key then
					Value := P_Aux.Value;
					Success := True;
				end if;
			P_Aux := P_Aux.Next;
			end loop;
		end Get;


	procedure Put (M          : in out Map;
                  Key        : Key_Type;
                  Value      : Value_Type;
                  Success    : out Boolean) is
	P_Aux : Cell_A;
	Found : Boolean;
		begin
			-- Si ya existe Key, cambiamos su Value
			P_Aux := M.P_First;
			Found := False;
			Success := False;
			while not Found and P_Aux /= null loop
				if P_Aux.Key = Key then
					P_Aux.Value := Value;
					Found := True;
					Success := True;
				end if;
				P_Aux := P_Aux.Next;
			end loop;
			
			-- Si no hemos encontrado Key añadimos al principio
			if not Found and M.Length <= Max_Length then
				P_Aux := new Cell;
				P_Aux.Key := key;
				P_Aux.Value := Value;
				P_Aux.Next := M.P_First;
				P_Aux.Prev := null;
				if P_Aux.Next /= null then
					P_Aux.Next.Prev := P_Aux;
				end if;
				Success := True;
				M.Length := M.Length + 1;
				M.P_First := P_Aux;
			end if;
		end Put;



	procedure Delete (M      : in out Map;
                          Key     : in  Key_Type;
                          Success : out Boolean) is
		P_Aux : Cell_A := M.P_First;
		begin
		Success := False;
		while not Success and P_Aux /= null loop
		 	if P_Aux.Key = Key then
				if P_Aux.Prev = null then
					M.P_First := P_Aux.Next;
				else 
					P_Aux.Prev.Next := P_Aux.Next;
				end if;
				
				if P_Aux.Next /= null then
					P_Aux.Next.Prev := P_Aux.Prev;
				end if;
				Free(P_Aux);
				Success := True;
				M.Length := M.Length - 1;
		 	else
				TIO.Put_Line("Success falso");
				P_Aux := P_Aux.Next;
			end if;
	      end loop;
   	end Delete;


	function Map_Length (M : Map) return Natural is
		begin
			return M.Length;
		end Map_Length;

	procedure Print_Map (M : Map) is
		P_Aux : Cell_A;
	begin
		P_Aux := M.P_First;
	        Ada.Text_IO.Put_Line ("Map");
	        Ada.Text_IO.Put_Line ("===");
		while P_Aux /= null loop
			Ada.Text_IO.Put_Line (Key_To_String(P_Aux.Key) & " " &
				                 VAlue_To_String(P_Aux.Value));
			P_Aux := P_Aux.Next;
		end loop;
	end Print_Map;
	
	function Get_Keys (M : Map) return Keys_Array_Type is
		Key_Array : Keys_Array_Type;
		P_Aux : Cell_A := M.P_First;
		begin
			for Pos in 1..Max_Length loop
				if P_Aux /= null then
					Key_Array(Pos) := P_Aux.Key;
					P_Aux := P_Aux.Next;
				else
					Key_Array(Pos) := Null_Key;
				end if;
			end loop;
			
			return Key_Array;
		end Get_Keys;
		
	function Get_Values (M : Map) return Values_Array_Type is
		Value_Array : Values_Array_Type;
		P_Aux : Cell_A := M.P_First;
		begin
			for Pos in 1..Max_Length loop
				if P_Aux /= null then
					Value_Array(Pos) := P_Aux.Value;
					P_Aux := P_Aux.Next;
				else
					Value_Array(Pos) := Null_Value;
				end if;
			end loop;
			
			return Value_Array;
		end Get_Values;


end Maps_g;
