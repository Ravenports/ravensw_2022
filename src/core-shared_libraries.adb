--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Ada.Directories;
with Ada.Direct_IO;
with Core.Event;

package body Core.Shared_Libraries is

   package DIR renames Ada.Directories;
   package EV  renames Core.Event;


   --------------------------------------------------------------------
   --  add_shlib_list_from_stage
   --------------------------------------------------------------------
   procedure add_shlib_list_from_stage (LS : in out Library_Set; stage_directory : String)
   is
      procedure scan_dir (library_directory : String);
      procedure scan_dir (library_directory : String)
      is
         full_path : constant String := stage_directory & library_directory;
      begin
         LS.scan_directory_for_shlibs (directory_path => full_path,
                                       strict_names   => False);
      end scan_dir;
   begin
      scan_dir ("/lib");
      scan_dir ("/usr/lib");
   end add_shlib_list_from_stage;


   --------------------------------------------------------------------
   --  add_shlib_from_elf_hints
   --------------------------------------------------------------------
   procedure add_shlib_from_elf_hints (LS : in out Library_Set)
   is
      function determine_hints_file return String;

      --  This function makes sense for FreeBSD ports system because it uses ldconfig
      --  extensively.   Ravenports does NOT use ldconfig, instead mandating the use of RUNPATH
      --  or RPATH.  Only the BSDs have the hints file anyway, and other than the system
      --  libraries, the hints files only point to /usr/local, the ports installation.
      --  The procedures are left in place, but they are commented out because they are useless
      --  on Ravenports.

      function determine_hints_file return String is
      begin
         case platform is
            when netbsd | openbsd => return "/var/run/ld.so.hints";
            when others => return "/var/run/ld-elf.so.hints";
         end case;
      end determine_hints_file;

      hintsfile : constant String := determine_hints_file;
   begin
      --  case platform is
      --     when netbsd | openbsd | freebsd | dragonfly =>
      --        LS.read_elf_hints (hintsfile  => hintsfile,
      --                           must_exist => True);
      --     when others => null;
      --  end case;
      null;
   end add_shlib_from_elf_hints;


   --------------------------------------------------------------------
   --  scan_directory_for_shlibs
   --------------------------------------------------------------------
   procedure scan_directory_for_shlibs (LS : in out Library_Set;
                                        directory_path : String;
                                        strict_names : Boolean)
   is
      procedure check_file (item : DIR.Directory_Entry_Type);
      function search_pattern return String;
      function contains_library_extension (filename : String) return Boolean;

      --  Expect shlibs to follow the name pattern libfoo.so.N if strictnames is true,
      --  ie. when searching the default library search path.
      --  Otherwise, allow any name ending in .so or .so.N,
      --  ie. when searching RPATH or RUNPATH and assuming it contains private shared libraries
      --  which can follow just about any naming convention

      function search_pattern return String is
      begin
         if strict_names then
            return "lib*";
         else
            return "*";
         end if;
      end search_pattern;

      function contains_library_extension (filename : String) return Boolean
      is
         midobject : constant String := ".so.";
         index : Natural := filename'Last;
      begin
         if not Strings.contains (filename, midobject) then
            return False;
         end if;

         loop
            case filename (index) is
               when '.' => null;
               when '0' .. '9' => null;
               when others => exit;
            end case;
            exit when index = filename'First;
            index := index - 1;
         end loop;
         if index - 3 >= filename'First then
            if filename (index - 3 .. index) = midobject then
               return True;
            end if;
         end if;
         return False;
      end contains_library_extension;

      procedure check_file (item : DIR.Directory_Entry_Type)
      is
         file_name : constant String := DIR.Simple_Name (item);

         --  Valid library names end in ".so" or ".so.X+" where X is a digit or a period.
         --  For strict names they also have to start with the letters "lib"
      begin
         if strict_names then
            --  Name can't be shorter than "libx.so".
            --  Pattern takes care of leading "lib" check
            if file_name'Length < 7 then
               return;
            end if;
         end if;

         if not Strings.trails (file_name, ".so") and then
           not contains_library_extension (file_name)
         then
            return;
         end if;

         LS.shlib_list_add (directory_path   => directory_path,
                            library_filename => file_name);
      end check_file;

   begin
      DIR.Search (Directory => directory_path,
                  Pattern   => search_pattern,
                  Filter    => (DIR.Directory => False, others => True),
                  Process   => check_file'Access);
   exception
      when DIR.Name_Error =>
         EV.emit_error (directory_path & " directory does not exist");
      when DIR.Use_Error =>
         EV.emit_error (directory_path & " directory USE error (scan_directory_for_shlibs)");
   end scan_directory_for_shlibs;


   --------------------------------------------------------------------
   --  shlib_list_add
   --------------------------------------------------------------------
   procedure shlib_list_add (LS : in out Library_Set;
                             directory_path : String;
                             library_filename : String)
   is
      --  Reject any subsequent instance of library_filename.
      --  In theory the same filename could appear in multiple stage directories.
      --  In practice, that shouldn't happen.

      key : constant Text := Strings.SUS (library_filename);
   begin
      if LS.shlibs.Contains (key) then
         return;
      end if;

      declare
         value : constant Text := Strings.SUS (directory_path & "/" & library_filename);
      begin
         LS.shlibs.Insert (key, value);
      end;
   end shlib_list_add;


   --------------------------------------------------------------------
   --  read_elf_hints
   --------------------------------------------------------------------
   procedure read_elf_hints (LS : in out Library_Set;
                             hintsfile : String;
                             must_exist : Boolean)
   is
   begin
      if not DIR.Exists (hintsfile) then
         if must_exist then
            EV.emit_error ("Cannot open " & hintsfile);
         end if;
         return;
      end if;
      declare
         hints_size : constant Natural := Natural (DIR.Size (hintsfile));
      begin
         if hints_size > 16 * 1024 then
            EV.emit_error (hintsfile & " is unreasonable large");
            return;
         end if;
         declare
            subtype File_String    is String (1 .. hints_size);
            package File_String_IO is new Ada.Direct_IO (File_String);

            function read_32_uint (hints : File_String; index : Natural) return Natural;
            procedure handle_hints (delimited_hints : String);

            File       : File_String_IO.File_Type;
            Contents   : File_String;
            elfmagic   : constant Natural := 16#746e6845#;
            magic      : Natural;
            version    : Natural;
            strtab     : Natural;
            dirlist    : Natural;
            dirlistlen : Natural;
            indexf     : Natural;
            indexl     : Natural;

            function read_32_uint (hints : File_String; index : Natural) return Natural
            is
               A : Natural := Character'Pos (Contents (Contents'First + index));
               B : Natural := Character'Pos (Contents (Contents'First + index + 1));
               C : Natural := Character'Pos (Contents (Contents'First + index + 2));
               D : Natural := Character'Pos (Contents (Contents'First + index + 3));
            begin
               --  Little Endian
               return (D * 16777216) + (C * 65536) + (B * 256) + A;
            end read_32_uint;

            procedure handle_hints (delimited_hints : String)
            is
               number_paths : constant Natural := Strings.count_char (delimited_hints, ':') + 1;
            begin
               if number_paths > 0 then
                  for field in 1 .. number_paths loop
                     LS.scan_directory_for_shlibs
                       (directory_path => Strings.specific_field (delimited_hints, field, ":"),
                        strict_names   => True);
                  end loop;
               end if;
            end handle_hints;
         begin
            File_String_IO.Open  (File, Mode => File_String_IO.In_File,
                                  Name => hintsfile);
            File_String_IO.Read  (File, Item => Contents);
            File_String_IO.Close (File);

            --  Check magic string
            magic := read_32_uint (Contents, 0);
            if magic /= elfmagic then
               EV.emit_error (hintsfile & " invalid file format");
               return;
            end if;

            version    := read_32_uint (Contents, 4);
            strtab     := read_32_uint (Contents, 8);
            dirlist    := read_32_uint (Contents, 16);
            dirlistlen := read_32_uint (Contents, 20);
            indexf     := Contents'First + strtab + dirlist;
            indexl     := indexf + dirlistlen - 1;

            handle_hints (Contents (indexf .. indexl));
         end;
      end;
   end read_elf_hints;

end Core.Shared_Libraries;
