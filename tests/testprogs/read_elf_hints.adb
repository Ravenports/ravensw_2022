with Ada.Text_IO;
with Ada.Direct_IO;
with Ada.Directories;
with Core.Strings;

use Core;

procedure read_elf_hints
is
   --  Test on DragonFly
   hintsfile : constant String := "/var/run/ld-elf.so.hints";
   must_exist : constant Boolean := True;
begin
   if not Ada.Directories.Exists (hintsfile) then
      if must_exist then
         Ada.Text_IO.Put_Line ("Cannot open " & hintsfile);
      end if;
      return;
   end if;
   declare
      hints_size : constant Natural := Natural (Ada.Directories.Size (hintsfile));
   begin
      if hints_size > 16 * 1024 then
         Ada.Text_IO.Put_Line (hintsfile & " is unreasonable large");
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
                  Ada.Text_IO.Put_Line (Strings.specific_field (delimited_hints, field, ":"));
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
            Ada.Text_IO.Put_Line (hintsfile & " invalid file format");
            return;
         end if;

         version    := read_32_uint (Contents, 4);
         strtab     := read_32_uint (Contents, 8);
         dirlist    := read_32_uint (Contents, 16);
         dirlistlen := read_32_uint (Contents, 20);

         Ada.Text_IO.Put_Line ("version = " & version'Img);
         Ada.Text_IO.Put_Line ("strtab = " & strtab'Img);
         Ada.Text_IO.Put_Line ("dirlist offset = " & dirlist'Img);
         Ada.Text_IO.Put_Line ("dirlist length = " & dirlistlen'Img);
         Ada.Text_IO.Put_Line ("Path Hints:");
         handle_hints (Contents (Contents'First + strtab + dirlist ..
                         Contents'First + strtab + dirlist + dirlistlen -1));
      end;
   end;
end read_elf_hints;
