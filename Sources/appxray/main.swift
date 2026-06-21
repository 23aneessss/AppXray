import Foundation
import AppXrayKit

// App X-Ray CLI — zero third-party dependencies, hand-rolled argument parsing.
//
//   appxray <path-to-.app> [--json] [--markdown] [--out <file>] [--no-color]
//   appxray --installed
//   appxray --help | --version

let exitCode = CLI.run(arguments: Array(CommandLine.arguments.dropFirst()))
exit(exitCode)
