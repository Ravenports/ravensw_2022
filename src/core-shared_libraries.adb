--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt


package body Core.Shared_Libraries is


   --------------------------------------------------------------------
   --  add_shlib_list_from_stage
   --------------------------------------------------------------------
   procedure add_shlib_list_from_stage (LS : Library_Set; stage_directory : String)
   is
   begin
      null;
   end add_shlib_list_from_stage;


   --------------------------------------------------------------------
   --  add_shlib_from_elf_hints
   --------------------------------------------------------------------
   function add_shlib_from_elf_hints (LS : Library_Set) return Action_Result
   is
   begin
   end add_shlib_from_elf_hints;

end Core.Shared_Libraries;
