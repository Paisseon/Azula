//
//  Patcher.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation

struct Patcher {
    let targetURL: URL
    private let console: Console = .shared
    
    func patch(_ patches: [Patch]) -> Bool {
        guard !patches.isEmpty else {
            console.log("No patches", type: .info)
            return true
        }
        
        guard let handle: FileHandle = try? .init(forWritingTo: targetURL) else {
            console.log("Couldn't get write handle to \(targetURL.path)", type: .error)
            return false
        }
        
        do {
            var curOffset: UInt64 = 0
            
            for patch: Patch in patches {
                if let offset: Int = patch.offset {
                    try handle.seek(toOffset: UInt64(offset))
                    curOffset = UInt64(offset)
                }
                
                console.log(String(format: "Patching 0x%X bytes at 0x%X", patch.data.count, curOffset), type: .info)
                try handle.write(contentsOf: patch.data)
            }
            
            try handle.close()
        } catch {
            console.log(error.localizedDescription, type: .error)
            return false
        }
        
        return true
    }
}
