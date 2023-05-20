//
//  Injector.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation
import MachO

struct Injector {
    let extractor: Extractor
    let patcher: Patcher
    private let console: Console = .shared
    
    func inject(
        _ payload: String,
        withHeader mh: MachHeader
    ) -> Bool {
        let payloadSize: Int = MemoryLayout<dylib_command>.size + (payload.count & -8) + 8
        let cmdOffset: UInt64 = .init(mh.offset + MemoryLayout<mach_header_64>.size)
        
        if isAlreadyInjected(payload) {
            console.log("Payload is already injected", type: .info)
            return true
        }
        
        guard hasSpace(for: payload, inHeader: mh.header) else {
            console.log("Not enough space to inject payload", type: .error)
            return false
        }
        
        var dylibCmd: dylib_command = .init()
        var newHeader: mach_header_64 = mh.header
        
        dylibCmd.cmd = LC_LOAD_WEAK_DYLIB
        dylibCmd.cmdsize = UInt32(payloadSize)
        dylibCmd.dylib.name = lc_str(offset: UInt32(MemoryLayout<dylib_command>.size))
        
        newHeader.ncmds += 1
        newHeader.sizeofcmds += UInt32(payloadSize)
        
        if let index: Int = machHeaders.firstIndex(where: { $0.offset == mh.offset }) {
            machHeaders[index] = MachHeader(header: newHeader, offset: mh.offset)
        }
        
        let patches: [Patch] = [
            Patch(offset: mh.offset, data: Data(bytes: &newHeader, count: MemoryLayout<mach_header_64>.size)),
            Patch(offset: Int(cmdOffset) + Int(mh.header.sizeofcmds), data: Data(bytes: &dylibCmd, count: MemoryLayout<dylib_command>.size)),
            Patch(offset: nil, data: payload.data(using: .utf8) ?? Data(repeating: 0, count: payload.count)),
        ]
        
        return patcher.patch(patches)
    }
    
    private func hasSpace(
        for payload: String,
        inHeader header: mach_header_64
    ) -> Bool {
        let segCmds: [SegmentCommand] = loadCommands.lazy.compactMap { $0 as? SegmentCommand }
        let slc: SegmentCommand? = segCmds.first(where: { withUnsafePointer(to: $0.command.segname) { ptr in strcmp(ptr, "__TEXT") == 0 } })
        
        guard let slc else {
            console.log("Couldn't find text segment", type: .error)
            return false
        }
        
        for i: UInt32 in 0 ..< slc.command.nsects {
            let sectOffset: Int = slc.offset + MemoryLayout<segment_command_64>.size + MemoryLayout<section_64>.size * Int(i)
            
            guard let sectCmd: section_64 = extractor.extract(at: sectOffset) else {
                return false
            }
            
            // __TEXT,__text
            
            if sectCmd.flags == 0x80000400 {
                let space: UInt32 = sectCmd.offset - header.sizeofcmds - UInt32(MemoryLayout<mach_header_64>.size)
                console.log(String(format: "Space available in arch: 0x%X", space), type: .info)
                return space > MemoryLayout<dylib_command>.size + (payload.count & -8) + 8
            }
        }
        
        console.log("Couldn't find text section", type: .error)
        return false
    }
    
    private func isAlreadyInjected(_ payload: String) -> Bool {
        let dllcs: [DylibCommand] = loadCommands.lazy.compactMap { $0 as? DylibCommand }
        
        for dllc in dllcs {
            let lcStrOff: Int = .init(dllc.command.dylib.name.offset)
            let strOff: Int = dllc.offset + lcStrOff
            let len: Int = .init(dllc.command.cmdsize) - lcStrOff
            
            guard let data: Data = extractor.extractRaw(offset: strOff, length: len),
                  let curPath: String = .init(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
            else {
                console.log("Couldn't read existing load command", type: .warn)
                continue
            }
            
            guard curPath != payload else {
                return true
            }
            
            if curPath.components(separatedBy: "/").last == payload.components(separatedBy: "/").last {
                console.log("Similar path \(curPath) found in target", type: .warn)
            }
        }
        
        return false
    }
}
