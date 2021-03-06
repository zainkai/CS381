-------------------------------------------------
-- Kevin Turkington
-- 7/29/17
-- CS 381 Keeley Abbott
-- HW1
-------------------------------------------------

module MiniLogo where


import Data.List 
import Prelude hiding (Num)

--
-- * MiniLogo
--
-- | The grammar:
--      num ::= (any natural number)
--      var ::= (any variable name)
--    macro ::= (any macro name)
--
--     prog ::= ε | cmd; prog                 sequence of commands
--
--     mode ::= up | down                     pen status
--
--     expr ::= var                           variable reference
--           |  num                           literal number
--           |  expr + expr                   addition expression
--
--      cmd ::= pen mode                      change pen status
--           |  move (expr, expr)             move pen to a new position
--           |  define macro (var*) {prog}    define a macro
--           |  call macro (expr*)            invoke a macro

-- | 1. Define the abstract syntax as a set of Haskell data types.
--

type Num = Int
type Var = String
type Macro = String

type Prog = [Cmd]

--data Mode == pen off page
            -- pen on page
data Mode = Up
          | Down
          deriving(Show,Eq)

--data Expr == Var String
            -- Num Int
            -- Add Expr Expr

data Expr = Var Var
          | Num Num
          | Add Expr Expr
          deriving (Eq,Show)

--data Cmd == up or down
           -- move x y
           -- define "name" [parameters]
           --       [Program instructions]
           -- Call "name" [parameters]
data Cmd = Pen Mode
         | Move Expr Expr
         | Define Macro [Var] Prog
         | Call Macro [Expr]
         deriving(Eq,Show)

-- | 2. Define a MiniLogo macro "line."
--
--      Concrete syntax in a comment:
--      Abstract syntax in code (include correct type header):
-- the x# and y# can theoretically be replaced by ints
line :: Cmd
line = Define "line" ["x1","y1","x2","y2"]
       [Pen Up,     Move (Var "x1") (Var "y1"),
        Pen Down,   Move (Var "x2") (Var "y2")]

-- | 3. Define a MiniLogo macro "nix" using "line" defined above.
--
--      Concrete syntax in a comment:
--
-- (x,y+h) \/ (x+w,y+h)
--   (x,y) /\ (x+w,y)
-- line1 == (x,y) to (x+w,y+h)
-- line2 == (x+w,y) to (x,y+h)
nix :: Cmd
nix = Define "nix" ["x","y","w","h"]
      [Call "line" [Var "x",Var "y",Add (Var "x") (Var "w"), Add (Var "y") (Var "h")],
       Call "line" [Add (Var "x") (Var "w"),Var "y",Var "x", Add (Var "y") (Var "h")]]

-- | 4. Define a Haskell function "steps" (steps :: Int -> Prog) that draws
--      a staircase of n steps starting from (0,0).
--
-- Note: no need to use define because this is a prog(Set of commands ex.line, nix,...) 
steps :: Int -> Prog
steps 0 = []
steps 1 = [Pen Up, Move (Num 0) (Num 0), Pen Down,
           Move (Num 0) (Num 1),Move (Num 1) (Num 1),
           Pen Up]
steps x = steps (pred x) ++ [Pen Up, Move (Num x) (Num x), Pen Down,
           Move (Num x) (Num (succ x)),Move (Num (succ x)) (Num (succ x)),
           Pen Up]

-- | 5. Define a Haskell function "macros" (macros :: Prog -> [Macro] that
--      returns a list of the names of all the macros that are defined anywhere
--      in a given MiniLogo program.
--
-- Synonmous with:
-- macros :: [Cmd] -> [Macro]
macros :: Prog -> [Macro]
macros [] = []
macros ((Define mac _ _): cmds) = mac : macros cmds
macros ((Pen _): cmds)          = macros cmds
macros ((Call _ _): cmds)       = macros cmds
macros ((Move _ _): cmds)       = macros cmds


-- | 6. Define a Haskell function "pretty" (pretty :: Prog -> String) that
--      "pretty-prints" a MiniLogo program.
--
pretty :: Prog -> String
pretty [] = ""
pretty ((Pen p):cmds) = "(Pen " ++ (case p of
      Up -> "Up) "
      Down -> "Down) ") ++ pretty cmds ++ " "
pretty ((Move x y):cmds) = "Move (" ++  (prettyExpr x) ++ ") (" ++ (prettyExpr y) ++ ") " ++ pretty cmds ++ " "
pretty ((Call x y):cmds) = "Call " ++ x ++ " (" ++ concat (map prettyExpr y) ++ ") " ++ pretty cmds ++ " "
pretty ((Define x y z):cmds) = "Define " ++ x ++ "( (" ++ concat(intersperse " " y) ++ ") (" ++ pretty z ++"))" ++ pretty cmds ++ " "

--helper function
--https://stackoverflow.com/questions/2784271/haskell-converting-int-to-string
prettyExpr :: Expr -> String
prettyExpr (Var x) = x 
prettyExpr (Num x) = (show x)
prettyExpr (Add x y) = "(Add " ++ "(" ++ prettyExpr x ++ ")" ++ "(" ++ prettyExpr y ++ ")) " 


--
-- * Bonus Problems
--
-- | 7. Define a Haskell function "optE" (optE :: Expr -> Expr) that partially
--      evaluates expressions by replacing additions of literals with the
--      result.
--
optE :: Expr -> Expr
optE (Var x) = Var x 
optE (Num x) = Num x
optE (Add x y) = Add (optE x) (optE y)


-- | 8. Define a Haskell function "optP" (optP :: Prog -> Prog) that optimizes
--      all of the expressions contained in a given program using optE.
--
optP :: Prog -> Prog
optP [] = []
optP (x:xs) = optPCmd x : optP xs --map commands function over [Cmd]

optPCmd :: Cmd -> Cmd
optPCmd (Call x y) = Call x (map optE y)
optPCmd (Move x y) = Move (optE x) (optE y)
optPCmd (Pen x) = (Pen x)
