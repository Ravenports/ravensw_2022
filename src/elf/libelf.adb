--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../../License.txt

with Interfaces.C.Strings;
with Interfaces.C.Extensions;
with elfdefinitions_h;

package body Libelf is

   package IC  renames Interfaces.C;
   package ICS renames Interfaces.C.Strings;
   package ICX renames Interfaces.C.Extensions;
   package DEF renames elfdefinitions_h;

   --------------------------------------------------------------------
   --  initialize_libelf
   --------------------------------------------------------------------
   function initialize_libelf return Boolean
   is
      use type IC.unsigned;
   begin
      return (libelf_h.elf_version (DEF.EV_CURRENT) /= DEF.EV_NONE);
   end initialize_libelf;


   --------------------------------------------------------------------
   --  elf_errmsg
   --------------------------------------------------------------------
   function elf_errmsg return String
   is
      result : ICS.chars_ptr;
   begin
      result := libelf_h.elf_errmsg (IC.int (-1));
      --  Don't free result
      return ICS.Value (result);
   end elf_errmsg;


   --------------------------------------------------------------------
   --  elf_begin_read
   --------------------------------------------------------------------
   function elf_begin_read (fd : Core.Unix.File_Descriptor) return access libelf_h.Elf
   is
   begin
      return libelf_h.elf_begin (IC.int (fd), libelf_h.ELF_C_READ, null);
   end elf_begin_read;


   --------------------------------------------------------------------
   --  elf_object_is_null
   --------------------------------------------------------------------
   function elf_object_is_null (elf_obj : access libelf_h.Elf) return Boolean
   is
      use type libelf_h.Elf;
   begin
      return (elf_obj = null);
   end elf_object_is_null;


   --------------------------------------------------------------------
   --  elf_end
   --------------------------------------------------------------------
   procedure elf_end (elf_obj : access libelf_h.Elf)
   is
      result : IC.int;
   begin
      if elf_obj /= null then
         result := libelf_h.elf_end (elf_obj);
      end if;
   end elf_end;


   --------------------------------------------------------------------
   --  get_elf_header
   --------------------------------------------------------------------
   function get_elf_header (elf_obj : access libelf_h.Elf;
                            header  : access gelf_h.GElf_Ehdr) return Boolean
   is
      result : access gelf_h.GElf_Ehdr;
   begin
      result := gelf_h.gelf_getehdr (elf_obj, header);
      return (result /= null);
   end get_elf_header;


   --------------------------------------------------------------------
   --  elf_next_section
   --------------------------------------------------------------------
   function elf_next_section (elf_obj : access libelf_h.Elf;
                              section : access libelf_h.Elf_Scn) return access libelf_h.Elf_Scn
   is
   begin
      return libelf_h.elf_nextscn (elf_obj, section);
   end elf_next_section;


   --------------------------------------------------------------------
   --  elf_get_section_header
   --------------------------------------------------------------------
   function elf_get_section_header (section : access libelf_h.Elf_Scn;
                                    sheader : access gelf_h.GElf_Shdr) return Boolean
   is
      result : access gelf_h.GElf_Shdr;
   begin
      result := gelf_h.gelf_getshdr (section, sheader);
      return (result /= null);
   end elf_get_section_header;


   --------------------------------------------------------------------
   --  section_header_is_elf_note
   --------------------------------------------------------------------
   function section_header_is_elf_note (section : access gelf_h.GElf_Shdr) return Boolean is
   begin
      case section.sh_type is
         when elfdefinitions_h.SHT_NOTE => return True;
         when others => return False;
      end case;
   end section_header_is_elf_note;


   --------------------------------------------------------------------
   --  section_header_is_dynlink_info
   --------------------------------------------------------------------
   function section_header_is_dynlink_info (section : access gelf_h.GElf_Shdr) return Boolean is
   begin
      case section.sh_type is
         when elfdefinitions_h.SHT_DYNAMIC => return True;
         when others => return False;
      end case;
   end section_header_is_dynlink_info;


   --------------------------------------------------------------------
   --  elf_getdata
   --------------------------------------------------------------------
   function elf_getdata (section : access libelf_h.Elf_Scn) return access libelf_h.Elf_Data is
   begin
      return libelf_h.elf_getdata (section, null);
   end elf_getdata;


   --------------------------------------------------------------------
   --  valid_elf_data
   --------------------------------------------------------------------
   function valid_elf_data (data : access libelf_h.Elf_Data) return Boolean is
   begin
      return data /= null;
   end valid_elf_data;


   --------------------------------------------------------------------
   --  get_ident_byte
   --------------------------------------------------------------------
   function get_ident_byte (header : gelf_h.GElf_Ehdr; offset : EI_OFFSETS) return EI_Byte
   is
      index : constant Natural := Natural (EI_OFFSETS'Pos (offset));
   begin
      return EI_Byte (header.e_ident (header.e_ident'First + index));
   end get_ident_byte;


   --------------------------------------------------------------------
   --  convert_elf_data_buffer
   --------------------------------------------------------------------
   function convert_elf_data_buffer (data : access libelf_h.Elf_Data) return String
   is
      result : String (1 .. Integer (data.d_size));

      for result'Address use data.d_buf;
   begin
      return result;
   end convert_elf_data_buffer;


   --------------------------------------------------------------------
   --  elf_note_size
   --------------------------------------------------------------------
   function elf_note_size return Natural is
      --  size returns #bits, so divide by 8 to get #bytes
   begin
      return (3 * IC.unsigned'Size) / 8;
   end elf_note_size;


   --------------------------------------------------------------------
   --  is_elf_file
   --------------------------------------------------------------------
   function is_elf_file (elf_object : access libelf_h.Elf) return Boolean
   is
      use type libelf_h.Elf_Kind;
   begin
      return libelf_h.F_elf_kind (elf_object) = libelf_h.ELF_K_ELF;
   end is_elf_file;


   --------------------------------------------------------------------
   --  is_relexecso_type
   --------------------------------------------------------------------
   function is_relexecso_type (header : gelf_h.GElf_Ehdr) return Boolean is
   begin
      case header.e_type is
         when elfdefinitions_h.ET_DYN |
              elfdefinitions_h.ET_EXEC |
              elfdefinitions_h.ET_REL => return True;
         when others => return False;
      end case;
   end is_relexecso_type;


   --------------------------------------------------------------------
   --  dynamic_payload
   --------------------------------------------------------------------
   function dynamic_payload
     (elf_object : access libelf_h.Elf;
      section : access gelf_h.GElf_Shdr;
      data : access libelf_h.Elf_Data;
      index : Natural;
      dstype : out dynamic_section_type) return String
   is
      use type elfdefinitions_h.Elf64_Sxword;

      dyn : access gelf_h.GElf_Dyn;
      dyn_mem : aliased gelf_h.GElf_Dyn;

   begin
      dyn := gelf_h.gelf_getdyn (arg1 => data,
                                 arg2 => IC.int (index),
                                 arg3 => dyn_mem'Access);
      if dyn = null then
         dstype := failed_to_determine;
         return "error";
      end if;

      if dyn.d_tag = elfdefinitions_h.DT_SONAME then
         dstype := soname;
      elsif dyn.d_tag = elfdefinitions_h.DT_NEEDED then
         dstype := needed;
      elsif dyn.d_tag = elfdefinitions_h.DT_RPATH then
         dstype := rpath;
      elsif dyn.d_tag = elfdefinitions_h.DT_RUNPATH then
         dstype := runpath;
      else
         dstype := dont_care;
         return "uninteresting";
      end if;

      declare
         use type ICS.chars_ptr;
         payload : ICS.chars_ptr;
      begin
         payload := Libelf_h.elf_strptr (arg1 => elf_object,
                                         arg2 => IC.unsigned_long (section.sh_link),
                                         arg3 => dyn.d_un.d_val);

         if payload = ICS.Null_Ptr then
            return "";
         end if;

         --  Don't free payload
         return ICS.Value (payload);
      end;

   end dynamic_payload;

end Libelf;
