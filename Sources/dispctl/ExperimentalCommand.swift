import ArgumentParser
import DisplayBackendCG
import DisplayCore
import Foundation

struct ExperimentalCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "experimental",
    abstract: "Experimental commands (private API). They affect real displays.",
    subcommands: [Disable.self, Enable.self, Probe.self]
  )

  struct Disable: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Cut the video signal of an external display without recording it.")

    @Argument(help: "Display ID from `dispctl list`.")
    var id: UInt32

    @Option(help: "If given, re-enable the display itself after this many seconds (1-3600).")
    var revertAfter: Int?

    func validate() throws {
      if let revertAfter, !(1...3600).contains(revertAfter) {
        throw ValidationError("--revert-after must be between 1 and 3600.")
      }
    }

    func run() throws {
      try reportingErrors {
        let service = makeService()
        try service.disable(id)
        print("Display \(id) disabled.")
        guard let revertAfter else { return }
        print("It will be re-enabled in \(revertAfter) s; the process stays running.")
        fflush(stdout)
        Thread.sleep(forTimeInterval: TimeInterval(revertAfter))
        try service.enable(id)
        print("Display \(id) re-enabled.")
      }
    }
  }

  struct Enable: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Re-enable a disabled display.")

    @Argument(help: "ID of the display to re-enable.")
    var id: UInt32

    func run() throws {
      try reportingErrors {
        try makeService().enable(id)
        print("Display \(id) re-enabled.")
      }
    }
  }

  struct Probe: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Print the public online list next to the private CGSGetDisplayList output.")

    func run() throws {
      try reportingErrors {
        let backend = CGDisplayBackend()
        let online = try backend.onlineDisplays().map(\.id).sorted()
        print("online (public): \(online)")
        do {
          print("CGSGetDisplayList (private): \(try backend.privateDisplayIDs().sorted())")
        } catch {
          print("CGSGetDisplayList (private): \(error.localizedDescription)")
        }
      }
    }
  }
}
