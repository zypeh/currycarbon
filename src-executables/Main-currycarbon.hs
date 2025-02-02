{-# LANGUAGE OverloadedStrings #-}

import           Paths_currycarbon                  (version)
import           Currycarbon.Parsers
import           Currycarbon.Types
import           Currycarbon.CLI.RunCalibrate       (runCalibrate, 
                                                     CalibrateOptions (..))

import           Data.Version                       (showVersion)
import qualified Options.Applicative                as OP

-- * CLI interface configuration
--
-- $cliInterface
--
-- This module contains the necessary code to configure the currycarbon CLI interface

-- data types
data Options = CmdCalibrate CalibrateOptions

-- CLI interface configuration
main :: IO ()
main = do
    cmdOpts <- OP.customExecParser p optParserInfo
    runCmd cmdOpts
    where
        p = OP.prefs OP.showHelpOnEmpty

runCmd :: Options -> IO ()
runCmd o = case o of
    CmdCalibrate opts -> runCalibrate opts

optParserInfo :: OP.ParserInfo Options
optParserInfo = OP.info (OP.helper <*> versionOption <*> optParser) (
    OP.briefDesc <>
    OP.progDesc "Simple intercept calibration for one or multiple radiocarbon dates"
    )

versionOption :: OP.Parser (a -> a)
versionOption = OP.infoOption (showVersion version) (OP.long "version" <> OP.help "Show version")

optParser :: OP.Parser Options
optParser = CmdCalibrate <$> calibrateOptParser

calibrateOptParser :: OP.Parser CalibrateOptions
calibrateOptParser = CalibrateOptions <$> parseUncalC14String
                                      <*> parseUncalC14FromFile
                                      <*> parseCalCurveFromFile
                                      <*> parseCalibrationMethod
                                      <*> parseDontInterpolateCalCurve
                                      <*> parseQuiet
                                      <*> parseDensityFile
                                      <*> parseHDRFile
                                      <*> parseCalCurveSegmentFile
                                      <*> parseCalCurveMatrixFile

-- ** Input parsing functions
--
-- $inputParsing
--
-- These functions define and handle the CLI input arguments

parseUncalC14String :: OP.Parser [UncalC14]
parseUncalC14String = concat <$> OP.many (OP.argument (OP.eitherReader readUncalC14String) (
    OP.metavar "DATES" <>
    OP.help "A string with one or multiple uncalibrated dates of \
            \the form \"<sample name>,<mean age BP>,<one sigma standard deviation>;...\" \
            \where <sample name> is optional. \
            \So for example \"S1,4000,50;3000,25;S3,1000,20\"."
    ))

parseUncalC14FromFile :: OP.Parser [FilePath]
parseUncalC14FromFile = OP.many (OP.strOption (
    OP.long "inputFile" <>
    OP.short 'i' <>
    OP.help "A file with a list of uncalibrated dates. \
            \Formated just as DATES, but with a new line for each input date. \
            \DATES and --uncalFile can be combined and you can provide multiple instances of --uncalFile"
    ))

parseCalCurveFromFile :: OP.Parser (Maybe FilePath)
parseCalCurveFromFile = OP.option (Just <$> OP.str) (
    OP.long "calibrationCurveFile" <>
    OP.help "Path to an calibration curve file in .14c format. \
            \The calibration curve will be read and used for calibration. \
            \If no file is provided, currycarbon will use the intcal20 curve." <>
    OP.value Nothing
    )

parseCalibrationMethod :: OP.Parser CalibrationMethod
parseCalibrationMethod = OP.option (OP.eitherReader readCalibrationMethod) (
    OP.long "method" <>
    OP.help "The calibration algorithm that should be used: Bchron (default) or MatrixMultiplication" <>
    OP.value Bchron
    )
  where
    readCalibrationMethod :: String -> Either String CalibrationMethod
    readCalibrationMethod s = case s of
        "MatrixMultiplication"  -> Right MatrixMultiplication
        "Bchron"                -> Right Bchron
        _                       -> Left "must be Bchron or MatrixMultiplication"

parseDontInterpolateCalCurve :: OP.Parser (Bool)
parseDontInterpolateCalCurve = OP.switch (
    OP.long "noInterpolation" <> 
    OP.help "Don't interpolate the calibration curve"
    )


parseQuiet :: OP.Parser (Bool)
parseQuiet = OP.switch (
    OP.long "quiet" <> 
    OP.short 'q' <>
    OP.help "Suppress the printing of calibration results to the command line"
    )

parseDensityFile :: OP.Parser (Maybe FilePath)
parseDensityFile = OP.option (Just <$> OP.str) (
    OP.long "densityFile" <>
    OP.help "Path to an output file which stores output densities per sample and calender year" <>
    OP.value Nothing
    )

parseHDRFile :: OP.Parser (Maybe FilePath)
parseHDRFile = OP.option (Just <$> OP.str) (
    OP.long "hdrFile" <>
    OP.help "Path to an output file which stores the high probability density regions for each \
            \sample" <>
    OP.value Nothing
    )

parseCalCurveSegmentFile :: OP.Parser (Maybe FilePath)
parseCalCurveSegmentFile = OP.option (Just <$> OP.str) (
    OP.long "calCurveSegmentFile" <>
    OP.help "Path to an output file which stores the relevant, interpolated calibration curve \
            \segment for the first (!) input date in a long format. \
            \This option as well as --calCurveMatrixFile are mostly meant for debugging" <>
    OP.value Nothing
    )

parseCalCurveMatrixFile :: OP.Parser (Maybe FilePath)
parseCalCurveMatrixFile = OP.option (Just <$> OP.str) (
    OP.long "calCurveMatrixFile" <>
    OP.help "Path to an output file which stores the relevant, interpolated calibration curve \
            \segment for the first (!) input date in a wide matrix format" <>
    OP.value Nothing
    )