-- tests.adb
-- Validation & Verification suite for the Context Tree Weighting package.
-- Over 13 test cases to disprove the assumption that the code is non-functional.

with Ada.Text_IO; use Ada.Text_IO;
with Context_Tree_Weighting; use Context_Tree_Weighting;

procedure Tests is

   -- Helper for floating point equivalence
   procedure Assert_Float_Eq (Actual, Expected : Long_Float; Message : String) is
      Tolerance : constant Long_Float := 0.000001;
   begin
      if abs (Actual - Expected) > Tolerance then
         Put_Line ("      FAIL: " & Message & " (Expected:" & Long_Float'Image (Expected) & 
                   ", Got:" & Long_Float'Image (Actual) & ")");
         raise Program_Error;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert_Float_Eq;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert;

   Tree          : Context_Tree;
   Empty_Context : constant Bit_Array (1 .. 0) := (others => 0);
   Ctx_0         : constant Bit_Array (1 .. 1) := (1 => 0);
   Ctx_1         : constant Bit_Array (1 .. 1) := (1 => 1);
   Ctx_Long      : constant Bit_Array (1 .. 3) := (0, 1, 0);

begin
   Put_Line ("--- Starting CTW Test Suite ---");

   -- TEST 1: Initial Tree State
   Put_Line ("TEST 1 - Initialization & Empty Probability");
   Tree := Initialize_Tree (Max_Depth => 2);
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 1.0, "Empty P_w = 1.0");
   Assert_Float_Eq (Get_KT_Probability (Tree), 1.0, "Empty P_e = 1.0");

   -- TEST 2: Zero-Order Model Update 
   Put_Line ("TEST 2 - Zero-Order Update (Bit 0)");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.5, "P_e(a=1, b=0) = 0.5");
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.5, "Zero Order P_w = P_e = 0.5");

   -- TEST 3: Zero-Order Model Update Sequence (0, 0)
   Put_Line ("TEST 3 - Zero-Order Sequence (0, 0)");
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.375, "P_e(a=2, b=0) = 0.375");

   -- TEST 4: Zero-Order Model Mixed Sequence
   Put_Line ("TEST 4 - Zero-Order Mixed Sequence");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   Update (Tree, Empty_Context, 0);
   Update (Tree, Empty_Context, 1);
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.125, "P_e(a=1, b=1) = 0
