//
//  Azula.swift
//  Azula
//
//  Created by Lilliana on 16/02/2023.
//

import ArgumentParser
import AzulaKit
import Foundation
import MachO
import ZIPFoundation

private let version = "0.0.1"
private let pretty: RainbowLogger = .init()

// MARK: - Inject

@main
struct Azula: ParsableCommand {
    // MARK: Internal

    static let configuration: CommandConfiguration = .init(
        abstract: "Azula v\(version)",
        discussion: "Azula is a utility to inject or remove tweaks from 64-bit Mach-O files",
        version: version
    )

    mutating func run() throws {
        guard #available(macOS 11, iOS 14, *) else {
            pretty.print(Log(text: "Azula requires macOS 11 or iOS 14", type: .warn))
            return
        }
        
        let ipaHelper: IPAHelper = .init(ipaURL: URL(fileURLWithPath: input), pretty: pretty)
        let targetURL: URL = input.hasSuffix(".ipa") ? ipaHelper.getBinaryURL()! : .init(fileURLWithPath: input)
        let dylibsArr: [String] = dylibs.components(separatedBy: ",")
        let dylibzArr: [String] = dylibsArr.map { "@executable_path/Azula/" + URL(fileURLWithPath: $0).lastPathComponent }
        let removeArr: [String] = remove.components(separatedBy: ",")
        
        let azula: AzulaKit = .init(
            dylibs: input.hasSuffix(".ipa") ? dylibzArr : dylibsArr,
            remove: removeArr,
            targetURL: targetURL,
            printer: pretty
        )
        
        if !remove.isEmpty {
            pretty.print(Log(text: azula.remove() ? "Successfully removed dylib(s)" : "Dylib removal failed", type: .info))
        }
        
        if !dylibs.isEmpty {
            pretty.print(Log(text: azula.inject() ? "Successfully injected dylib(s)" : "Dylib injection failed", type: .info))
        }
        
        if slice != 0 {
            pretty.print(Log(text: azula.slice() ? "Successfully sliced codesign" : "Failed to slice codesign", type: .info))
        }
        
        if input.hasSuffix(".ipa") {
            ipaHelper.repackIPA()
        }
    }

    // MARK: Private

    @Argument(help: "The target file, a Mach-O binary or IPA")
    private var input: String

    @Option(name: .shortAndLong, help: "Dylib paths to add, separated by a comma")
    private var dylibs: String = ""
    
    @Option(name: .shortAndLong, help: "Dylib paths to remove, separated by a comma")
    private var remove: String = ""
    
    @Flag(name: .shortAndLong, help: "Remove code signature")
    private var slice: Int
}
