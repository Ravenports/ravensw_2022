--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Ada.Characters.Latin_1;
with Core.Elf_Operations;
with Core.Event;
with Core.Strings;
with Core.Config;
with Core.Context;
with Core.Manifest;
with Core.Database.Iterator;
with Core.Database.Operations;

use Core.Strings;

package body Core.Create is

   package LAT renames Ada.Characters.Latin_1;
   package CDO renames Core.Database.Operations;

   --------------------------------------------------------------------
   --  fix_up_abi
   --------------------------------------------------------------------
   procedure fix_up_abi
     (pkg_access     : Pkgtypes.A_Package_Access;
      root_directory : String;
      testing        : Boolean)
   is
      defaultarch : Boolean := False;
   begin
      --  If not defined architecture, autodetermine it
      if IsBlank (pkg_access.abi) then
         declare
            arch : String := Config.get_ci_key (Config.abi);
         begin
            pkg_access.abi := SUS (arch);
            defaultarch := True;
         end;
      end if;

      if not testing then
         case Elf_Operations.analyze_packaged_files
           (pkg_access      => pkg_access,
            stage_directory => root_directory)
         is
            when RESULT_OK => Event.emit_debug (2, "Passed packaged file analysis");
            when others => null;
         end case;
      end if;

      if Context.reveal_developer_mode then
         suggest_arch (pkg_access => pkg_access,
                       is_default => defaultarch);
      end if;
   end fix_up_abi;


   --------------------------------------------------------------------
   --  command_load_metadata
   --------------------------------------------------------------------
   function command_load_metadata
     (pkg_access     : Pkgtypes.A_Package_Access;
      metadatafile   : String;
      root_directory : String;
      testing        : Boolean) return Action_Result
   is
      rc : Action_Result;
   begin

      rc := Manifest.parse_metadata_file (pkg_access   => pkg_access,
                                          metadatafile => metadatafile);
      if rc = RESULT_OK then
         Create.fix_up_abi (pkg_access     => pkg_access,
                            root_directory => root_directory,
                            testing        => testing);
      end if;

      return rc;
   end command_load_metadata;


   --------------------------------------------------------------------
   --  suggest_arch
   --------------------------------------------------------------------
   procedure suggest_arch
     (pkg_access     : Pkgtypes.A_Package_Access;
      is_default     : Boolean)
   is
      use type Pkgtypes.Containment_Flags;

      abi : constant String := Strings.USS (pkg_access.abi);
      is_wildcard : constant Boolean := Strings.contains (abi, "*");
   begin
      if is_wildcard and then is_default then
         Event.emit_developer_mode
           ("Configuration error: arch " & LAT.Quotation & abi & LAT.Quotation &
              " cannot use wildcards as default");
      end if;
      if (pkg_access.cont_flags and
        (Pkgtypes.PKG_CONTAINS_ELF_OBJECTS or Pkgtypes.PKG_CONTAINS_STATIC_LIBS)) > 0
      then
         if is_wildcard then
            --  Definitely has to be arch specific
            Event.emit_developer_mode
              ("Error error: arch " & LAT.Quotation & abi & LAT.Quotation &
                 " -- package installs architecture specific files");
         end if;
      else
         if (pkg_access.cont_flags and Pkgtypes.PKG_CONTAINS_LA) > 0 then
            if is_wildcard then
               --  Could well be arch specific
               Event.emit_developer_mode
                 ("Warning error: arch " & LAT.Quotation & abi & LAT.Quotation &
                    "-- package installs libtool files which are often architecture specific");
            end if;
         else
            --  Might be arch independent
            if is_wildcard then
               Event.emit_developer_mode
                 ("Notice: arch " & LAT.Quotation & abi & LAT.Quotation &
                    "no architecture specific files found");
               Event.emit_developer_mode ("**** could this package use a wildcard architecture?");
            end if;
         end if;
      end if;
   end suggest_arch;


   --------------------------------------------------------------------
   --  test_package_installed
   --------------------------------------------------------------------
   function test_package_installed
     (rdb_access     : Database.RDB_Connection_Access;
      pkg_access     : Pkgtypes.A_Package_Access;
      name           : String) return Action_Result
   is
      it : Database.Iterator.DB_SQLite_Iterator;
   begin
      if it.initialize_as_standard_query (conn     => rdb_access.all,
                                          pattern  => name,
                                          match    => Database.MATCH_EXACT,
                                          just_one => True) /= RESULT_OK
      then
         return RESULT_FATAL;
      end if;

      return it.Next (pkg_access => pkg_access,
                      sections   => (Pkgtypes.basic => True, others => False));
   end test_package_installed;


   --------------------------------------------------------------------
   --  package_is_installed
   --------------------------------------------------------------------
   function package_is_installed
     (rdb_access     : Database.RDB_Connection_Access;
      name           : String) return Action_Result
   is
      mypkg : aliased Pkgtypes.A_Package;
   begin
      return test_package_installed (rdb_access => rdb_access,
                                     pkg_access => mypkg'Unchecked_Access,
                                     name       => name);
   end package_is_installed;


   --------------------------------------------------------------------
   --  register_package
   --------------------------------------------------------------------
   function register_package
     (pkg_access     : Pkgtypes.A_Package_Access;
      rdb_access     : Database.RDB_Connection_Access;
      input_path     : String;
      testing        : Boolean) return Action_Result
   is
   begin
      if CDO.rdb_connected (rdb_access) and then
        package_is_installed
          (rdb_access => rdb_access, name => Strings.USS (pkg_access.name)) /= RESULT_END
      then
         return RESULT_INSTALLED;
      end if;


      TODO: pkg-emit-install-begin

   end register_package;

end Core.Create;
