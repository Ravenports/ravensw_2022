--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Pkgtypes;

package Cmd.Register is

   --  Executes register command
   function execute_register_command (comline : Cldata) return Boolean;

private

   function access_is_sufficient return Boolean;

   procedure fix_up_abi
     (pkg_access     : Pkgtypes.A_Package_Access;
      root_directory : String;
      testing        : Boolean);

   function command_load_metadata
     (pkg_access     : Pkgtypes.A_Package_Access;
      metadatafile   : String;
      root_directory : String;
      testing        : Boolean) return Action_Result;

end Cmd.Register;
