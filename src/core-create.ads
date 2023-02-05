--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt


with Core.Pkgtypes;
with Core.Database;

package Core.Create is

   function command_load_metadata
     (pkg_access     : Pkgtypes.A_Package_Access;
      metadatafile   : String;
      root_directory : String;
      testing        : Boolean) return Action_Result;

   --  if the provided database is unconnected then we don't want to register the package
   --  in the database aka NO_PKG_REGISTER
   function register_package
     (pkg_access     : Pkgtypes.A_Package_Access;
      rdb_access     : Database.RDB_Connection_Access;
      input_path     : String;
      reloc          : String;
      testing        : Boolean) return Action_Result;

   function test_package_installed
     (rdb_access     : Database.RDB_Connection_Access;
      pkg_access     : Pkgtypes.A_Package_Access;
      name           : String) return Action_Result;

   function package_is_installed
     (rdb_access     : Database.RDB_Connection_Access;
      name           : String) return Action_Result;

private

   procedure fix_up_abi
     (pkg_access     : Pkgtypes.A_Package_Access;
      root_directory : String;
      testing        : Boolean);

   procedure suggest_arch
     (pkg_access     : Pkgtypes.A_Package_Access;
      is_default     : Boolean);

end Core.Create;
