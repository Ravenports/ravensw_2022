--  Check blake3 returns correct hash of file contents
--  Required input: file path
--  Optional input "power".  defaults to 16 (2^16 = 65536)


with blake_3;
with Ada.Text_IO;
with Ada.Command_Line;
With Ada.Directories;

procedure file_digest is

   package TIO renames Ada.Text_IO;
   package CLI renames Ada.Command_Line;
   package DIR renames Ada.Directories;

   subtype power_range is Positive range 12 .. 24;
   
   power : power_range := 16;
begin

   if CLI.Argument_Count = 0 then
      TIO.Put_Line ("Usage: file_digest [path-to-file] <power (default=16)>");
      return;
   end if;

   if CLI.Argument_Count >= 2 then
      --  will throw exceptions if not a integer, or if it's out of range
      power := power_range'Value (CLI.Argument (2));
   end if;

   declare
      filepath : String renames CLI.Argument (1);
   begin
      if not DIR.exists (filepath) then
         TIO.Put_Line ("Error: file does not exist: " & filepath);
         return;
      end if;
      
      TIO.Put_Line ("Getting Blake3 hash of " & filepath & " with a buffer power of " & power'Img);
      declare
         result : constant String := blake_3.hex (blake_3.file_digest (filepath, power));
      begin
         TIO.Put_Line (result);
      end;
   end;

end file_digest;
