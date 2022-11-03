#!/usr/bin/swift

import Foundation
import RegexBuilder

if #available(macOS 13.0, *) {
  enum TerminalCommand {
    static func run(_ command: String) throws -> String {
      let process = Process()
      let pipe = Pipe()

      process.standardOutput = pipe
      process.standardError = pipe
      process.arguments = ["-c", command]
      process.executableURL = URL(fileURLWithPath: "/bin/zsh")
      process.standardInput = nil

      try process.run()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)!

      return output
    }
  }

  let currentSetting = Reference(Int.self)
  guard let userDefaultsValue = try TerminalCommand
    .run("defaults read com.apple.WindowManager")
    .firstMatch(of: Regex {
      "AppWindowGroupingBehavior = "
      TryCapture(as: currentSetting) {
        OneOrMore(.digit)
      } transform: { match in
        Int(match)
      }
    }) else {
    fatalError("Unable to find AppWindowGroupingBehavior entry.")
  }

  let newValue: Int
  if userDefaultsValue[currentSetting] == 1 {
    newValue = 0
  } else {
    newValue = 1
  }

  _ = try TerminalCommand
    .run("defaults write com.apple.WindowManager AppWindowGroupingBehavior -int \(newValue)")

}
