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
            pretty.print("Azula requires macOS 11 or iOS 14", type: .warn)
            return
        }
        
        let targetURL: URL = input.hasSuffix(".ipa") ? handleIPA()! : .init(fileURLWithPath: input)
        let dylibsArr: [String] = dylibs.components(separatedBy: ",")
        let removeArr: [String] = remove.components(separatedBy: ",")
        let azula: AzulaKit = .init(dylibs: dylibsArr, remove: removeArr, targetURL: targetURL, printer: pretty)
        
        if !remove.isEmpty {
            pretty.print(azula.remove() ? "Successfully removed dylib(s)" : "Dylib removal failed", type: .info)
        }
        
        if !dylibs.isEmpty {
            pretty.print(azula.inject() ? "Successfully injected dylib(s)" : "Dylib injection failed", type: .info)
        }
        
        if slice != 0 {
            pretty.print(azula.slice() ? "Successfully sliced codesign" : "Failed to slice codesign", type: .info)
        }
        
        if input.hasSuffix(".ipa") {
            compressIPA()
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
    
    @available(macOS 11, iOS 14, *)
    private func handleIPA() -> URL? {
        let ipaURL: URL = .init(fileURLWithPath: input)
        let workURL: URL = .init(fileURLWithPath: "./.Workspace")
        let payloadURL: URL = workURL.appendingPathComponent("Payload")
        
        do {
            pretty.print("Extracting IPA...", type: .info)
            try FileManager.default.unzipItem(at: ipaURL, to: workURL)
            
            let appURL: URL = try FileManager.default.contentsOfDirectory(
                at: payloadURL,
                includingPropertiesForKeys: []
            ).first!
            
            let targetURL: URL = try FileManager.default.contentsOfDirectory(
                at: appURL,
                includingPropertiesForKeys: []
            ).first(where: {
                $0.lastPathComponent == appURL.lastPathComponent.dropLast(4).description
            })!
            
            return targetURL
        } catch {
            pretty.print(error.localizedDescription, type: .error)
            return nil
        }
    }
    
    @available(macOS 11, iOS 14, *)
    private func compressIPA() {
        let ipaURL: URL = .init(fileURLWithPath: input)
        let workURL: URL = .init(fileURLWithPath: "./.Workspace")
        let payloadURL: URL = workURL.appendingPathComponent("Payload")
        let outputURL: URL = .init(fileURLWithPath: ipaURL.path.dropLast(4).description + "_Patched.ipa")
        
        do {
            if access(outputURL.path, F_OK) == 0 {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            pretty.print("Compressing patched IPA...", type: .info)

            try FileManager.default.zipItem(at: payloadURL, to: outputURL)
            try FileManager.default.removeItem(at: workURL)
        } catch {
            pretty.print(error.localizedDescription, type: .error)
        }
    }
}
