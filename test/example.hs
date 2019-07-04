{-# LANGUAGE
    CPP,
    DeriveGeneric #-}
#if __GLASGOW_HASKELL__ >= 806
{-# LANGUAGE
    DerivingStrategies,
    DerivingVia #-}
#endif

import Data.Semigroup (Semigroup(..))
import GHC.Generics
import Generic.Data (gmappend, Generically(..))
import Generic.Data.Orphans ()

data Foo a = Bar [a] [a] deriving Generic

instance Semigroup (Foo a) where
  (<>) = gmappend

#if __GLASGOW_HASKELL__ >= 806
data Foo2 a = Bar2 [a] [a]
  deriving Generic
  deriving Semigroup via (Generically (Foo2 a))
#endif

data Foo3 = A3 | B3 [Int]
  deriving (Generic, Show)
  deriving Semigroup via Generically Foo3

main :: IO ()
main = pure ()
