--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Strings;

private with Ada.Containers.Hashed_Maps;

package Core.Shared_Libraries is

   type Library_Set is tagged private;

   --  Scans stage subdirectories for shared libraries
   procedure add_shlib_list_from_stage (LS : in out Library_Set; stage_directory : String);

   --  For BSD, add shared libraries from Elf Hints
   --  How do we handle Linux?
   procedure add_shlib_from_elf_hints (LS : in out Library_Set);



private

   package CON renames Ada.Containers;

   --  Key is library filename
   --  Element is full path of library file
   package Library_Crate is new CON.Hashed_Maps
     (Key_Type        => Text,
      Element_Type    => Text,
      Hash            => Strings.map_hash,
      Equivalent_Keys => Strings.equivalent,
      "="             => SU."=");

   type Library_Set is tagged
      record
         shlibs : Library_Crate.Map;
         rpaths : Library_Crate.Map;
      end record;

   --  called by stage directory iterator
   procedure scan_directory_for_shlibs
     (LS : in out Library_Set;
      directory_path : String;
      strict_names : Boolean);

   procedure shlib_list_add
     (LS : in out Library_Set;
      directory_path : String;
      library_filename : String);

   procedure read_elf_hints
     (LS : in out Library_Set;
      hintsfile : String;
      must_exist : Boolean);

end Core.Shared_Libraries;
