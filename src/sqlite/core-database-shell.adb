--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../../License.txt

with Ada.Characters.Latin_1;

with Core.Database.CustomCmds;
with Core.Strings;
with Core.Config;
with SQLite;
with sqlite_h;

use Core.Strings;

package body Core.Database.Shell is

   package LAT renames Ada.Characters.Latin_1;
   package IC  renames Interfaces.C;

   --------------------------------------------------------------------
   --  verbatim_command
   --------------------------------------------------------------------
   procedure start_shell (arguments : String)
   is
      numargs : constant Natural := count_char (arguments, LAT.LF) + 1;
   begin
      if not SQLite.initialize_sqlite then
         return;
      end if;

      declare
         type argv_t is array (1 .. numargs) of aliased ICS.chars_ptr;
         delim : constant String (1 .. 1) := (1 => LAT.LF);
         argv    : argv_t;
         argsval : access ICS.chars_ptr;
      begin
         for x in 1 .. numargs loop
            argv (x) := ICS.New_String (specific_field (arguments, x, delim));
         end loop;

         argsval := argv (1)'Access;

         pragma Warnings (Off, "*unused_result*");
         declare
            unused_result : IC.int;
         begin
            unused_result := sqlite_h.sqlite3_shell (IC.int (numargs), argsval);
         end;
         pragma Warnings (On, "*unused_result*");

         for x in 1 .. numargs loop
            ICS.Free (argv (x));
         end loop;
      end;
   end start_shell;


   --------------------------------------------------------------------
   --  pkgshell_open
   --------------------------------------------------------------------
   procedure pkgshell_open (reponame : access ICS.chars_ptr)
   is
      dbdir  : constant String := Config.configuration_value (Config.dbdir);
      dbfile : constant String := dbdir & "/" & local_ravensw_db;
   begin
      reponame.all := ICS.New_String (dbfile);
      pragma Warnings (Off, "*unused_res*");
      declare
         unused_res : IC.int;
      begin
         unused_res := sqlite_h.sqlite3_auto_extension (callback => CustomCmds.sqlcmd_init'Access);
      end;
      pragma Warnings (On, "*unused_res*");
   end pkgshell_open;


end Core.Database.Shell;
