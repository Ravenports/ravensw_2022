--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Pkgtypes;

package Cmd.Register is

   --  Executes register command
   function execute_register_command (comline : Cldata) return Boolean;

private

   function access_is_sufficient return Boolean;



end Cmd.Register;
