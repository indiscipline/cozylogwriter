## Cozy Log Writer
## ===============
##
## This module provides a most basic logging system for Nim programs.
## The main purpose of the logger is to automatically use either a styled or
## plain text format depending on whether the output file is a terminal or not.
##
## This module reads and respects the `NO_COLOR` environment variable by
## default. Use the compilation flag `-d:ClwIgnoreNocolor` to ignore it.
##
## .. warning:: The logger is using a global object internally and is not
##    thread-safe. The module does not prevent or manage concurrent access
##    in any way.
##
## Usage:
## ------
##
runnableExamples:
  # Initialize the logger with stderr as the output file
  newCozyLogWriter(stderr)
  log("This is a log message ", (complex: "types", are: "stringified", n: 42))
  info("This is an info message")
  warn("This is a warning message")
  err("This is an error message")
  # # The following line is commented out so tests pass:
  # panic("This is a panic message") # Exits the program with code 1
  panicWithCode(QuitSuccess, "This is a panic message") # Exits the program with a given code

import std/[macros, terminal]

const
  ClwIgnoreNocolor* {.booldefine.} = false ## |
  ## Used as a compilation flag to skip reading the `NO_COLOR` environmental
  ## variable, which disables all styling by default.

when not ClwIgnoreNocolor:
  import std/envvars

type
  LogKind = enum lkLog, lkInfo, lkWarn, lkErr, lkPanic
  Logger {.requiresinit.} = ref object
    f: File
    l: proc(f: File, knd: LogKind; m: varargs[string, `$`])

proc styledLog(f: File, knd: LogKind; m: varargs[string, `$`]) =
  case knd
    of lkLog:
      f.setForegroundColor(fgGreen); f.write("✔ ")
    of lkInfo:
      f.setStyle({styleDim})
    of lkWarn:
      f.setForegroundColor(fgYellow, false); f.write("⚠ ")
    of lkErr:
      f.setStyle({styleBright}); f.setForegroundColor(fgRed); f.write("✕ ")
    of lkPanic:
      f.setForegroundColor(fgRed)
  for item in m:
    f.write(item)
  f.write("\n")
  f.flushFile()
  f.resetAttributes()

proc plainLog(f: File, knd: LogKind; m: varargs[string, `$`]) =
  case knd
    of lkLog:  f.write("[LOG]:  ")
    of lkInfo: f.write("[INFO]: ")
    of lkWarn: f.write("[WARN]: ")
    of lkErr:  f.write("[ERR]:  ")
    of lkPanic:f.write("[FATAL]:")
  for item in m: f.write(item)
  f.write("\n")
  f.flushFile()

macro bracketify(m: varargs[untyped]): untyped =
  ## This is a hack
  result = newNimNode(nnkBracket)
  m.copyChildrenTo(result)

var globallogger: Logger

proc newCozyLogWriter*(output: File; forceNocolor = false) =
  ## Initializes the global logger object with the given file to write to.
  ## The logger is set to use styling/colourized by default, unless any
  ## of the following conditions is met:
  ##
  ## * `forceNocolor` is set to true
  ## * `NO_COLOR` evironment variable exists and not set to `0`
  ##   (unless compiled with the `-d:ClwIgnoreNocolor` flag)
  ## * The output file is not a TTY
  ##
  ## .. warning:: This procedure initializes an object stored in a global
  ##  variable and is not thread-safe. It should only be called once during
  ## program initialization.
  ##
  template readNoColorEnv(): bool =
    when not ClwIgnoreNocolor:
      const NoColor = "NO_COLOR"
      if existsEnv(NoColor) and getEnv(NoColor) != "0": true # "what std/options?"
      else: false
    else: false
  globallogger = new(Logger)
  globallogger.f = output
  let noColor = readNoColorEnv() or not output.isatty() or forceNocolor
  globallogger.l = if noColor: plainLog else: styledLog

template dolog(knd: LogKind; m: varargs[string, `$`]) =
  ## Internal template used to log messages with the given log level.
  globallogger.l(globallogger.f, knd, m)

template log*(msg: varargs[typed, `$`]) =
  ## Logs a message with the "log" level.
  dolog(lkLog, bracketify(msg))
template info*(msg: varargs[typed, `$`]) =
  ## Logs a message with the "info" level.
  dolog(lkInfo, bracketify(msg))
template warn*(msg: varargs[typed, `$`]) =
  ## Logs a message with the "warn" level.
  dolog(lkWarn, bracketify(msg))
template err*(msg: varargs[typed, `$`]) =
  ## Logs a message with the "err" level.
  dolog(lkErr, bracketify(msg))
template panicWithCode*(ec: int = QuitFailure; msg: varargs[typed, `$`]) =
  ## Logs a message with the "panic" level and exits the program with a given
  ## exit code.
  dolog(lkPanic, bracketify(msg)); quit(ec)
template panic*(msg: varargs[typed, `$`]) =
  ## Logs a message with the "panic" level and exits the program with the
  ## `QuitFailure` exit code (1).
  dolog(lkPanic, bracketify(msg)); quit(QuitFailure)

when isMainModule:
  newCozyLogWriter(stderr)
  log("test ", ["123123"])
  info("stringification ", 'i', 's', ["""not""", "required"])
  warn("Pay attention ", (fizz: "3", buzz: 5))
  err("Bad ", 0xBEEF)
  #panic("Abandon ", "sheep!")
  panicWithCode(127, "Abandon ", "sheep!")
