--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with Core.Strings;

private with Ada.Containers.Hashed_Maps;

package Core.Shared_Libraries is

   type Library_Set is tagged private;

   --  Scans stage subdirectories for shared libraries
   procedure add_shlib_list_from_stage (LS : in out Library_Set; stage_directory : String);

   --  For BSD, add shared libraries from Elf Hints
   --  This procedure has been effectively disabled; ldconfig is not used on Ravenports
   procedure add_shlib_from_elf_hints (LS : in out Library_Set);

   --  filter library based on its filename
   --  returns RESULT_FATAL if filename not registered
   --  returns RESULT_END if ALLOW_BASE_LIBRARY set (basically disabled the filter)
   --  returns RESULT_END if ALLOW_BASE_LIBRARY unset, but it's a base library
   function filter_system_shlibs
     (LS : Library_Set;
      library_filename : String) return Action_Result;

   --  Scans rpath directories for shared libraries
   procedure add_shlib_list_from_rpath
     (LS : in out Library_Set;
      rpath : String;
      origin : String);

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

   function find_shlib_path_by_name
     (LS : Library_Set;
      library_filename : String) return String;

end Core.Shared_Libraries;
