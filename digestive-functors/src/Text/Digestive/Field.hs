{-# LANGUAGE ExistentialQuantification, GADTs, OverloadedStrings #-}
module Text.Digestive.Field
    ( Field (..)
    , SomeField (..)
    , evalField
    ) where

import Data.Maybe (fromMaybe, listToMaybe)

import Data.Text (Text)
import qualified Data.Text as T

import Text.Digestive.Types
import Text.Digestive.Util

data Field v a where
    Singleton :: a -> Field v a
    Text      :: Text -> Field v Text
    Choice    :: Eq a => [(a, v)] -> Int -> Field v a
    Bool      :: Bool -> Field v Bool

instance Show (Field v a) where
    show (Singleton _) = "Singleton _"
    show (Text t)      = "Text " ++ show t
    show (Choice _ _)  = "Choice _ _"
    show (Bool b)      = "Bool " ++ show b

data SomeField v = forall a. SomeField (Field v a)

evalField :: Method      -- ^ Get/Post
          -> Maybe Text  -- ^ Given input
          -> Field v a   -- ^ Field
          -> a           -- ^ Result
evalField _    _        (Singleton x) = x
evalField _    Nothing  (Text x)      = x
evalField _    (Just x) (Text _)      = x
evalField _    Nothing  (Choice ls x) = fst $ ls !! x
evalField _    (Just x) (Choice ls y) = fromMaybe (fst $ ls !! y) $ do
    -- Expects input in the form of @foo.bar.2@
    t <- listToMaybe $ reverse $ toPath x
    i <- readMaybe $ T.unpack t
    return $ fst $ ls !! i
evalField Get  _        (Bool x)      = x
evalField Post Nothing  (Bool _)      = False
evalField Post (Just x) (Bool _)      = x == "on"