//
//  Azula.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation
import MachO

var loadCommands: [any LoadCommand] = []
var machHeaders: [MachHeader] = []

struct Azula {
    private let console: Console = .shared
    private let extractor: Extractor
    private let injector: Injector
    private let patcher: Patcher
    private let payloads: [String]
    private let remPayloads: [String]
    private let remover: Remover
    private let target: Data
    private let url: URL

    init(
        injecting payloads: [String],
        removing remPayloads: [String],
        from url: URL
    ) {
        // Initialise all properties

        self.payloads = payloads
        self.remPayloads = remPayloads
        self.url = url
        target = (try? Data(contentsOf: url)) ?? Data()
        extractor = Extractor(target: target)
        patcher = Patcher(targetURL: url)
        injector = Injector(extractor: extractor, patcher: patcher)
        remover = Remover(extractor: extractor, patcher: patcher)

        // Parse the target binary to get headers and load commands

        guard let fatHeader: fat_header = extractor.extract() else {
            console.log("Couldn't find header", type: .error)
            return
        }

        if fatHeader.magic.byteSwapped == FAT_MAGIC {
            let archCount: UInt32 = _OSSwapInt32(fatHeader.nfat_arch)
            var offset: Int = MemoryLayout<fat_header>.size - MemoryLayout<fat_arch>.size

            console.log("Multi-architecture binary with \(archCount) arches", type: .info)

            for _ in 0 ..< archCount {
                offset += MemoryLayout<fat_arch>.size

                if let arch: fat_arch = extractor.extract(at: offset) {
                    let archOffset: Int = .init(_OSSwapInt32(arch.offset))
                    if let header: mach_header_64 = extractor.extract(at: archOffset) {
                        let mh: MachHeader = .init(header: header, offset: archOffset)
                        
                        machHeaders.append(mh)
                        loadCommands.append(contentsOf: getLoadCommands(for: mh))
                    }
                }
            }
        } else {
            console.log("Thin binary", type: .info)

            if let header: mach_header_64 = extractor.extract() {
                let mh: MachHeader = .init(header: header, offset: 0)

                machHeaders = [mh]
                loadCommands = getLoadCommands(for: mh)
            }
        }
    }

    func inject() -> Bool {
        guard !isEncrypted() else {
            console.log("Azula only works on decrypted binaries", type: .error)
            return false
        }

        for (payload, mh): (String, MachHeader) in product(payloads, machHeaders) {
            guard injector.inject(payload, withHeader: mh),
                  let binName: String = payload.components(separatedBy: "/").last,
                  let archName: String = getArchName(for: mh.header)
            else {
                return false
            }

            console.log("Successfully injected \(binName) into \(archName) slice", type: .info)
        }
        
        return true
    }
    
    func remove() -> Bool {
        remover.remove(remPayloads)
    }
    
    func slice() -> Bool {
        let signatureLoadCommands: [SignatureCommand] = loadCommands.lazy.compactMap { $0 as? SignatureCommand }
        var patches: [Patch] = []
        var strip: Int = 0x0000_1337
        
        for cslc: SignatureCommand in signatureLoadCommands {
            patches.append(Patch(offset: cslc.offset, data: Data(bytes: &strip, count: 4)))
        }
        
        return patcher.patch(patches)
    }

    private func getLoadCommands(for mh: MachHeader) -> [any LoadCommand] {
        var offset: Int = mh.offset + MemoryLayout.size(ofValue: mh.header)
        var ret: [any LoadCommand] = []

        for _ in 0 ..< mh.header.ncmds {
            guard let loadCommand: load_command = extractor.extract(at: offset) else {
                console.log(String(format: "Load command at 0x%X is out of bounds", offset), type: .error)
                return ret
            }

            switch loadCommand.cmd {
                case LC_LOAD_WEAK_DYLIB, UInt32(LC_LOAD_DYLIB):
                    let command: dylib_command = extractor.extract(at: offset)!
                    ret.append(DylibCommand(offset: offset, command: command, mh: mh))

                case UInt32(LC_ENCRYPTION_INFO_64):
                    let command: encryption_info_command_64 = extractor.extract(at: offset)!
                    ret.append(EncryptionCommand(offset: offset, command: command))

                case UInt32(LC_CODE_SIGNATURE):
                    let command: linkedit_data_command = extractor.extract(at: offset)!
                    ret.append(SignatureCommand(offset: offset, command: command))

                case UInt32(LC_SEGMENT_64):
                    let command: segment_command_64 = extractor.extract(at: offset)!
                    ret.append(SegmentCommand(offset: offset, command: command))

                default:
                    offset += Int(loadCommand.cmdsize)
                    continue
            }

            offset += Int(loadCommand.cmdsize)
        }

        return ret
    }
    
    private func isEncrypted() -> Bool {
        let encLoadCommands: [EncryptionCommand] = loadCommands.lazy.compactMap { $0 as? EncryptionCommand }
        
        for elc: EncryptionCommand in encLoadCommands {
            guard elc.command.cryptid == 0 else {
                return true
            }
        }
        
        return false
    }
    
    private func getArchName(
        for header: mach_header_64
    ) -> String? {
        if header.cputype != CPU_TYPE_ARM64 {
            return "x86_64"
        }
        
        return header.cpusubtype == CPU_SUBTYPE_ARM64E ? "arm64e" : "arm64"
    }
    
    private func product<T, U>(
        _ a: [T],
        _ b: [U]
    ) -> [(T, U)] {
        var result: [(T, U)] = []
        
        for i in a {
            for j in b {
                result.append((i, j))
            }
        }
        
        return result
    }
}
