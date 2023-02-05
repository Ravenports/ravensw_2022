--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Database.Operations;
with Core.Create;
with Core.Event;

with Core.Strings;  use Core.Strings;

package body Cmd.Register is

   package DBO renames Core.Database.Operations;

   --------------------------------------------------------------------
   --  execute_register_command
   --------------------------------------------------------------------
   function execute_register_command (comline : Cldata) return Boolean
   is
      my_pkg : aliased Pkgtypes.A_Package;
      db     : Database.RDB_Connection;
   begin
      if not access_is_sufficient then
         return False;
      end if;

      my_pkg.package_type := Pkgtypes.PKG_INSTALLED;
      my_pkg.automatic := comline.register_automatic;

      if Create.command_load_metadata (pkg_access     => my_pkg'Unchecked_Access,
                                       metadatafile   => USS (comline.register_metafile),
                                       root_directory => USS (comline.register_root),
                                       testing        => comline.register_test) /= RESULT_OK
      then
         return False;
      end if;

      if not comline.register_skipreg then
         if DBO.rdb_open_localdb (db) /= RESULT_OK then
            Event.emit_notice ("Local database failed to open, exiting.");
            return False;
         end if;

         if not DBO.rdb_obtain_lock (db, Database.RDB_LOCK_EXCLUSIVE) then
            Event.emit_error
              ("Cannot get a exclusive lock on local database. It is locked by another process.");
            DBO.rdb_close (db);
            return False;
         end if;

         --  Todo: pkg_add_port

         if not DBO.rdb_release_lock (db, Database.RDB_LOCK_EXCLUSIVE) then
            Event.emit_error ("Cannot release exclusive lock on local database.");
         end if;
         DBO.rdb_close (db);
      else
         --  Todo: pkg_add_port
         null;
      end if;

      --  Todo: mystery messages?

      Event.emit_notice ("Register implementation unfinished.");
      return True;
   end execute_register_command;


   --------------------------------------------------------------------
   --  access_is_sufficient
   --------------------------------------------------------------------
   function access_is_sufficient return Boolean
   is
      use type Database.RDB_Mode_Flags;

      retcode : Action_Result;
      mode    : Core.Database.RDB_Mode_Flags;
   begin
      mode := (Database.RDB_MODE_READ or Database.RDB_MODE_WRITE or Database.RDB_MODE_CREATE);
      retcode := DBO.database_access (mode  => mode,
                                      dtype => Core.Database.RDB_DB_LOCAL);
      case retcode is
         when RESULT_OK =>
            return True;
         when RESULT_ENOACCESS =>
            Event.emit_notice ("Insufficient privileges to register packages");
            return False;
         when others =>
            Event.emit_notice ("Register package unexpected error: " & retcode'Img);
            return False;
      end case;
   end access_is_sufficient;


end Cmd.Register;
