--  Check blake3 returns correct hash

with blake_3;
with Ada.Text_IO;

procedure check_blake3 is

   package TIO renames Ada.Text_IO;

   test1 : constant String := "Texas";
   test2 : constant String := "A quick brown fox fell asleep.";
   test3 : constant String := "";

   expected_result1 : constant String := "f4b213a9769f4fbe4f49682c1a25186e16509a8960ecbba31967172c3d9f9d90";
   expected_result2 : constant String := "8aa63858237fb0dfb04f6eba622a3b0d89bfef7be50c73b41bb54dff2221c4b8";
   expected_result3 : constant String := "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262";

begin

   TIO.Put_Line ("Test 1   : " & test1);
   TIO.Put_Line ("expected : " & expected_result1);

   declare
      result : constant String :=  blake_3.hex (blake_3.digest (test1));
   begin
      TIO.Put_Line ("obtained : " & result);
      if result = expected_result1 then
         TIO.Put_Line ("PASSED.");
      else
         TIO.Put_Line ("FAILED!");
      end if;
   end;

   TIO.Put_Line ("Test 2   : " & test2);
   TIO.Put_Line ("expected : " & expected_result2);

   declare
      result : constant String := blake_3.hex (blake_3.digest (test2));
   begin
      TIO.Put_Line ("obtained : " & result);
      if result = expected_result2 then
         TIO.Put_Line ("PASSED.");
      else
         TIO.Put_Line ("FAILED!");
      end if;
   end;

   TIO.Put_Line ("Test 3   : " & test3);
   TIO.Put_Line ("expected : " & expected_result3);

   declare
      result : constant String := blake_3.hex (blake_3.digest (test3));
   begin
      TIO.Put_Line ("obtained : " & result);
      if result = expected_result3 then
         TIO.Put_Line ("PASSED.");
      else
         TIO.Put_Line ("FAILED!");
      end if;
   end;

end check_blake3;
