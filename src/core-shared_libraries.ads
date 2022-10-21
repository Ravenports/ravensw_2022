--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Strings;

private with Ada.Containers.Hashed_Maps;

package Core.Shared_Libraries is

   type Library_Set is tagged private;

   --  Scans stage subdirectories for shared libraries
   procedure add_shlib_list_from_stage (LS : Library_Set; stage_directory : String);

   --  For FreeBSD and DragonFly, add shared libraries from Elf Hints
   --  How do we handle Linux?
   function add_shlib_from_elf_hints (LS : Library_Set) return Action_Result;



private

   package CON renames Ada.Containers;

   type Shared_Library is
      record
         name : Text;
         path : Text;
      end record;

   package Library_Crate is new CON.Hashed_Maps
     (Key_Type        => Text,
      Element_Type    => Shared_Library,
      Hash            => Strings.map_hash,
      Equivalent_Keys => Strings.equivalent);

   type Library_Set is tagged
      record
         shlibs : Library_Crate.Map;
         rpaths : Library_Crate.Map;
      end record;

end Core.Shared_Libraries;
