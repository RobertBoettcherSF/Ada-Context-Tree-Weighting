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
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.125, "P_e(a=1, b=1) = 0.125");

   -- TEST 5: Depth-1 Empty Context Behavior
   Put_Line ("TEST 5 - Depth 1, No Context Traverse");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.75, "P_w = 0.5*0.5 + 0.5*1*1 = 0.75");

   -- TEST 6: Depth-1 Valid Context Traversal (Child 0)
   Put_Line ("TEST 6 - Depth 1, Traversal to Child 0");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_0, 0);
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.5, "P_w bounds child check");

   -- TEST 7: Depth-1 Valid Context Traversal (Child 1)
   Put_Line ("TEST 7 - Depth 1, Traversal to Child 1");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_1, 1);
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.5, "P_w bounds child 1 check");

   -- TEST 8: Exception Handling (Uninitialized)
   Put_Line ("TEST 8 - Uninitialized Tree Fault Detection");
   declare
      Uninit_Tree : Context_Tree;
      Caught      : Boolean := False;
   begin
      begin
         Update (Uninit_Tree, Ctx_0, 0);
      exception
         when Tree_Uninitialized => Caught := True;
      end;
      Assert (Caught, "Caught Tree_Uninitialized exception on Update");
   end;

   -- TEST 9: Max_Depth Truncation enforcement
   Put_Line ("TEST 9 - Depth Limit Enforcement");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 1);
   Update (Tree, Ctx_Long, 1); 
   -- Max depth is 1, so the traversal should stop early and return gracefully
   Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.5, "Stopped cleanly at Max Depth 1");

   -- TEST 10: State Deallocation & Reset Integrity
   Put_Line ("TEST 10 - Memory Freeing and State Reset");
   Free_Tree (Tree);
   declare
      Caught : Boolean := False;
   begin
      begin
         Update (Tree, Ctx_0, 0);
      exception
         when Tree_Uninitialized => Caught := True;
      end;
      Assert (Caught, "Free_Tree marks tree uninitialized");
   end;

   -- TEST 11: Alternating Pattern Degradation
   Put_Line ("TEST 11 - Alternating 0-1 Pattern KT tracking");
   Tree := Initialize_Tree (0);
   Update (Tree, Empty_Context, 0);
   Update (Tree, Empty_Context, 1);
   Update (Tree, Empty_Context, 0);
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.0625, "P_e(a=2, b=1) = 0.0625");
   Update (Tree, Empty_Context, 1);
   Assert_Float_Eq (Get_KT_Probability (Tree), 0.0234375, "P_e(a=2, b=2) exact match");

   -- TEST 12: Context Index Alignment
   Put_Line ("TEST 12 - Context Array Alignment");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 2);
   -- Pass an arbitrarily indexed array to test 'First and 'Last mapping
   declare
      Shifted_Ctx : Bit_Array (4 .. 5) := (4 => 1, 5 => 0);
   begin
      Update (Tree, Shifted_Ctx, 1);
      Assert_Float_Eq (Get_Weighted_Probability (Tree), 0.5, "Shifted array indexing succeeded");
   end;

   -- TEST 13: Floating Point Underflow Resistance (Stability check)
   Put_Line ("TEST 13 - Probability Degradation Stability");
   Free_Tree (Tree);
   Tree := Initialize_Tree (Max_Depth => 0);
   for I in 1 .. 50 loop
      Update (Tree, Empty_Context, 0);
   end loop;
   Assert (Get_KT_Probability (Tree) > 0.0, "Probability correctly avoided 0.0");
   Assert (Get_KT_Probability (Tree) < 0.1, "Probability successfully degraded");

   Put_Line ("--- All Tests Executed Successfully ---");
end Tests;
