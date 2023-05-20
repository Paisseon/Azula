//
//  Remover.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation
import MachO

struct Remover {
    let extractor: Extractor
    let patcher: Patcher
    private let console: Console = .shared
    
    func remove(_ payloads: [String]) -> Bool {
        let dllcs: [DylibCommand] = loadCommands.lazy.compactMap { $0 as? DylibCommand }
        var patches: [Patch] = []
        
        for dllc: DylibCommand in dllcs {
            let lcStrOff: Int = .init(dllc.command.dylib.name.offset)
            let strOff: Int = dllc.offset + lcStrOff
            let len: Int = .init(dllc.command.cmdsize) - lcStrOff
            
            if let data: Data = extractor.extractRaw(offset: strOff, length: len),
               let curPath: String = .init(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters),
               payloads.contains(curPath)
            {
                console.log("Found load command to remove at \(curPath)", type: .info)
                
                var dylibCmd: dylib_command = dllc.command
                dylibCmd.cmd = LC_LOAD_WEAK_DYLIB
                
                let strData: Data = .init(repeating: 0, count: len)
                let cmdData: Data = .init(bytes: &dylibCmd, count: MemoryLayout<dylib_command>.size)
                
                patches.append(Patch(offset: strOff, data: strData))
                patches.append(Patch(offset: dllc.offset, data: cmdData))
            }
        }
        
        return patcher.patch(patches)
    }
}
