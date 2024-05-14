# Cozy Log Writer

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

Cozy Log Writer is a basic logging module for Nim programs. It automatically uses a styled or plain text format depending on whether the output file is a terminal or not. The module also reads and respects the [`NO_COLOR`](https://no-color.org) environment variable by default.

## Features

- Supports different log levels: log, info, warn, err, panic
- Styled output with colours and UTF icons for terminal output
- Plain text output for non-terminal output
- Respects the `NO_COLOR` environment variable (unless compiled with `-d:ClwIgnoreNocolor`)

## Installation
Cozy Log Writer is not yet the nimble directory, `git clone` or just download the module.

Upon acceptance in the nimble directory, use `atlas` or `nimble` to install:
```
atlas use cozytaskpool
```

```
nimble install cozytaskpool
```

## Usage

```nim
import pkg/cozylogwriter

# Initialize the logger with stderr as the output file
newCozyLogWriter(stderr)

log("This is a log message", (complex: "types", are: "stringified", n: 42))
info("This is an info message")
warn("This is a warning message")
err("This is an error message")
panic("This is a panic message") # Exits the program with code 1
panicWithCode(QuitSuccess, "This is a panic message") # Exits the program with a given code
```

> [!WARNING]
> The logger uses a global object internally and is not thread-safe. The module does not prevent or manage concurrent access in any way.

## Documentation
Documentation is included. You can generate it locally with `nim doc cozylogwriter.nim`.

## License
Cozy Log Writer is licensed under GNU General Public License version 2.0 or later. See the LICENSE file for details.
