{-# LANGUAGE CPP #-}
{-# LANGUAGE RecordWildCards #-}

module Main (main) where
import Hasktags

import Data.Monoid
import Options.Applicative
import Text.PrettyPrint.ANSI.Leijen.Internal (text, line)
import System.IO (IOMode (AppendMode, WriteMode))

data Options = Options
  { _mode :: Mode
  , _files :: [FilePath]
  }

options :: Parser Options
options = Options
    <$> mode
    <*> files
  where
    mode :: Parser Mode
    mode = Mode
      <$> (ctags <|> etags <|> bothTags)
      <*> extendedCtag
      <*> appendTags
      <*> outputRedirection
      <*> cacheData
      <*> followSymlinks
      <*> suffixes
      <*> absoluteTagPaths
    ctags :: Parser Tags
    ctags = flag Both Etags $
         long "ctags"
      <> short 'c'
      <> help "generate CTAGS file (ctags)"

    etags :: Parser Tags
    etags = flag Both Etags  $
         long "etags"
      <> short 'e'
      <> help "generate ETAGS file (etags)"

    bothTags :: Parser Tags
    bothTags = flag' Both $
         long "both"
      <> short 'b'
      <> help "generate both CTAGS and ETAGS (default)"

    extendedCtag :: Parser Bool
    extendedCtag = switch $
         long "extendedctag"
      <> short 'x'
      <> showDefault
      <> help "Generate additional information in ctag file."

    appendTags :: Parser IOMode
    appendTags = flag WriteMode AppendMode $
         long "append"
      <> short 'a'
      <> showDefault
      <> help "append to existing CTAGS and/or ETAGS file(s). Afterward this file will no longer be sorted!"

    outputRedirection :: Parser TagsFile
    outputRedirection = strOption $
         long "output"
      <> long "file"
      <> short 'o'
      <> short 'f'
      <> metavar "FILE|-"
      <> value (TagsFile "tags" "TAGS")
      <> showDefault
      <> help "output to given file, instead of using the default names. '-' writes to stdout"

    cacheData :: Parser Bool
    cacheData = switch $
         long "cache"
      <> showDefault
      <> help "cache file data"

    followSymlinks :: Parser Bool
    followSymlinks = switch $
         long "follow-symlinks"
      <> short 'L'
      <> showDefault
      <> help "follow symlinks when recursing directories"

    suffixes :: Parser [String]
    suffixes = option auto $
         long "suffixes"
      <> short 'S'
      <> value [".hs", ".lhs", ".hsc"]
      <> showDefault
      <> help "list of hs suffixes including \".\""

    absoluteTagPaths :: Parser Bool
    absoluteTagPaths = switch $
         long "tags-absolute"
      <> short 'R'
      <> showDefault
      <> help "make tags paths absolute. Useful when setting tags files in other directories"

    files :: Parser [FilePath]
    files = some $ argument str (metavar "<files or directories...>")

parseArgs :: IO Options
parseArgs = execParser opts
    where
        opts = info (options <**> helper) $
               fullDesc
            <> progDescDoc (Just $
                   replaceDirsInfo <> line <> line
                <> symlinksInfo <> line <> line
                <> stdinInfo)

        replaceDirsInfo = text $ "directories will be replaced by DIR/**/*.hs DIR/**/*.lhs"
                ++ "Thus hasktags . tags all important files in the current"
                ++ "directory."
        symlinksInfo = text $ "If directories are symlinks they will not be followed"
                ++ "unless you pass -L."
        stdinInfo = text $ "A special file \"STDIN\" will make hasktags read the line separated file"
                ++ "list to be tagged from STDIN."

main :: IO ()
main = do
   Options{..} <- parseArgs
   generate _mode _files

-- Local Variables:
-- dante-target: "exe:hasktags"
-- End:
