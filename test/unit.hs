{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeApplications #-}

import Control.Applicative
import Data.Semigroup
import Data.Monoid (Sum(..))
import Test.Tasty
import Test.Tasty.HUnit

import GHC.Generics
import Generic.Data
import Generic.Data.Orphans ()

data P a = P a a
  deriving (Generic, Generic1)

type PTy a = a -> a -> Generically (P a)

p :: PTy a
p a b = Generically (P a b)

p' :: PTy Int
p' = p

pl :: PTy [Int]
pl = p

data P1 f a = P1 (f a) (f a)
  deriving Generic1

type PTy1 a = [a] -> [a] -> Generically1 (P1 []) a

p1 :: PTy1 a
p1 a b = Generically1 (P1 a b)

p1' :: PTy1 Int
p1' = p1

pl1 :: PTy1 [Int]
pl1 = p1

data E = E0 | E1 | E2
  deriving (Eq, Show, Generic)

main :: IO ()
main = defaultMain test

test :: TestTree
test = testGroup "unit"
  [ testGroup "Eq"
      [ testCase "(==)" $ p' 1 2 @?= p' 1 2
      , testCase "(/=)" $ False @?= (p' 1 2 == p' 1 1)
      ]
  , testGroup "Ord"
      [ testCase "compare" $ LT @?= compare (p' 1 2) (p' 2 1)
      , testCase "(<=)" $ True @?= (p' 1 1 <= p' 1 1)
      ]
  , testGroup "Semigroup"
      [ testCase "(<>)" $ pl [1, 5] [2, 3] @?= (pl [1] [2] <> pl [5] [3])
      ]
  , testGroup "Monoid"
      [ testCase "mempty" $ pl [] [] @?= mempty
      ]
  , testGroup "Functor"
      [ testCase "fmap" $ p1' [1] [2] @?= fmap (+ 1) (p1 [0] [1])
      ]
  , testGroup "Applicative"
      [ testCase "pure" $ p1' [3] [3] @?= pure 3
      , testCase "ap" $ p1' [1, 3] [2] @?= (p1 [id, (+2)] [(+2)] <*> p1 [1] [0])
      ]
  , testGroup "Alternative"
      [ testCase "empty" $ p1' [] [] @?= empty
      , testCase "(<|>)" $ p1' [1, 5] [2, 3] @?= (p1 [1] [2] <|> p1 [5] [3])
      ]
  , testGroup "Foldable"
      [ testCase "foldMap" $ Sum 3 @?= foldMap Sum (p1' [1] [2])
      , testCase "foldr" $ 3 @?= foldr (+) 0 (p1' [1] [2])
      ]
  , testGroup "Traversable"
      [ testCase "traverse" $
          [p1 [1] [2], p1 [1] [3], p1 [2] [2], p1 [2] [3]] @?=
            traverse (\y -> [y, y+1]) (p1' [1] [2])
      , testCase "sequenceA" $
          [p1 [1] [2], p1 [2] [2]] @?= sequenceA (pl1 [[1, 2]] [[2]])
      ]
  , testGroup "Bounded"
      [ testCase "minBound @E" $ E0 @?= gminBound
      , testCase "maxBound @E" $ E2 @?= gmaxBound
      , testCase "minBound @(P Int)" $ p' minBound minBound @?= gminBound
      , testCase "maxBound @(P Int)" $ p' maxBound maxBound @?= gmaxBound
      ]
  , testGroup "Enum"
      [ testCase "toEnum" $ [E0, E1, E2] @?= fmap gtoEnum [0, 1, 2]
      , testCase "fromEnum" $ [0, 1, 2] @?= fmap gfromEnum [E0, E1, E2]
      ]
  , testGroup "Show"
      [ testCase "show" $ "P 1 2" @?= show (p' 1 2)
      , testCase "showsPrec" $ "(P 1 2)" @?= showsPrec 11 (p' 1 2) ""
      ]

  , testGroup "Meta"
      [ testCase "datatypeName" $ "Maybe" @?= gdatatypeName @(Maybe Int)
      , testCase "moduleName" $ "GHC.Base" @?= gmoduleName @(Maybe Int)
      , testCase "packageName" $ "base" @?= gpackageName @(Maybe Int)
      , testCase "isNewtype" $ False @?= gisNewtype @(Maybe Int)
      , testCase "conName" $ "Just" @?= gconName (Just ())
      , testCase "conFixity" $ Prefix @?= gconFixity (Just ())
      , testCase "conIsRecord" $ False @?= gconIsRecord (Just ())
      , testCase "conNum" $ 2 @?= gconNum @(Maybe Int)
      ]
  ]