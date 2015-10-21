--Leire Soria Indiano

with Ada.Calendar;

package Timed_Handlers is

	type Timed_Handler_A is access procedure (Time: Ada.Calendar.Time);

	procedure Set_Timed_Handler (T : Ada.Calendar.Time; H : Timed_Handler_A);
	procedure Finalize;

end Timed_Handlers;

