--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../../License.txt


with Ada.Streams.Stream_IO;

package body blake_3 is

   package INT renames Interfaces;

   --------------------------------------------------------------------
   --  b3_update
   --------------------------------------------------------------------
   procedure b3_update (self : blake3_hasher_Access; plain : String)
   is
   begin
      if plain'Length = 0 then
         C_b3hasher_update (self, null, 0);
      else
         declare
            buffer : array (plain'Range) of aliased IC.unsigned_char;
         begin
            for x in plain'Range loop
               buffer (x) := IC.unsigned_char (Character'Pos (plain (x)));
            end loop;

            C_b3hasher_update (self, buffer (buffer'First)'Access, plain'Length);
         end;
      end if;
   end b3_update;


   --------------------------------------------------------------------
   --  b3_finalize
   --------------------------------------------------------------------
   function b3_finalize (self : blake3_hasher_Access) return blake3_hash
   is
      result : blake3_hash;
      buffer : array (blake3_hash'Range) of aliased IC.unsigned_char;
   begin
      C_b3hasher_finalize (self, buffer (buffer'First)'Access, BLAKE3_OUT_LEN);
      for x in blake3_hash'Range loop
         result (x) := Character'Val (buffer (x));
      end loop;
      return result;
   end b3_finalize;


   --------------------------------------------------------------------
   --  b3_hashsize
   --------------------------------------------------------------------
   function b3_hashsize return Natural
   is
   begin
      return blake3_hash'Length;
   end b3_hashsize;


   --------------------------------------------------------------------
   --  char2hex
   --------------------------------------------------------------------
   function char2hex (quattro : Character) return hexrep
   is
      type halfbyte is mod 2 ** 4;
      type fullbyte is mod 2 ** 8;
      function halfbyte_to_hex (value : halfbyte) return Character;

      std_byte  : INT.Unsigned_8;
      work_4bit : halfbyte;
      result    : hexrep;

      function halfbyte_to_hex (value : halfbyte) return Character
      is
         zero     : constant Natural := Character'Pos ('0');
         alpham10 : constant Natural := Character'Pos ('a') - 10;
      begin
         case value is
            when 0 .. 9 => return Character'Val (zero + Natural (value));
            when others => return Character'Val (alpham10 + Natural (value));
         end case;
      end halfbyte_to_hex;

   begin
      std_byte   := INT.Unsigned_8 (Character'Pos (quattro));
      work_4bit  := halfbyte (INT.Shift_Right (std_byte, 4));
      result (1) := halfbyte_to_hex (work_4bit);

      work_4bit  := halfbyte (fullbyte (Character'Pos (quattro)) and 2#1111#);
      result (2) := halfbyte_to_hex (work_4bit);

      return result;
   end char2hex;


   --------------------------------------------------------------------
   --  hex
   --------------------------------------------------------------------
   function hex (hash : blake3_hash) return blake3_hash_hex
   is
     result : blake3_hash_hex;
     index  : Positive := 1;
   begin
      for x in hash'Range loop
         result (index .. index + 1) := char2hex (hash (x));
         index := index + 2;
      end loop;
      return result;
   end hex;


   --------------------------------------------------------------------
   --  digest
   --------------------------------------------------------------------
   function digest (input_string : String) return blake3_hash
   is
      hasher : aliased blake_3.blake3_hasher;
   begin
      blake_3.b3_init (hasher'Unchecked_Access);
      blake_3.b3_update (hasher'Unchecked_Access, input_string);
      return blake_3.b3_finalize (hasher'Unchecked_Access);
   end digest;


   --------------------------------------------------------------------
   --  file_digest
   --------------------------------------------------------------------
   function file_digest (path : String; power : Positive := 16) return blake3_hash
   is
      chunk_size : constant Ada.Streams.Stream_Element_Offset := 2 ** power;
      subtype Buffer_Type is Ada.Streams.Stream_Element_Array (1 .. chunk_size);

      hasher : aliased blake_3.blake3_hasher;
      Buffer : Buffer_Type;
      File   : Ada.Streams.Stream_IO.File_Type;
      LastSE : Ada.Streams.Stream_Element_Offset;

      use type Ada.Streams.Stream_Element_Offset;

      function buffer_to_string (Buffer : Buffer_Type;
                                 LastSE : Ada.Streams.Stream_Element_Offset) return String;

      function buffer_to_string
        (Buffer : Buffer_Type;
         LastSE : Ada.Streams.Stream_Element_Offset) return String
      is
         result : String (Integer (Buffer'First) .. Integer (LastSE));
      begin
         for x in Buffer'First .. LastSE loop
            result (Integer (x)) := Character'Val (Buffer (x));
         end loop;
         return result;
      end buffer_to_string;
   begin
      blake_3.b3_init (hasher'Unchecked_Access);
      Ada.Streams.Stream_IO.Open (File,
                                  Mode => Ada.Streams.Stream_IO.In_File,
                                  Name => path);
      loop
         Ada.Streams.Stream_IO.Read (File, Item => Buffer, Last => LastSE);
         blake_3.b3_update (hasher'Unchecked_Access, buffer_to_string (Buffer, LastSE));
         exit when LastSE < Buffer'Last;
      end loop;
      Ada.Streams.Stream_IO.Close (File);
      return blake_3.b3_finalize (hasher'Unchecked_Access);
   end file_digest;

end blake_3;
