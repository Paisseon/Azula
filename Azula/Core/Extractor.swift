//
//  Extractor.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation

struct Extractor {
    let target: Data
    private let console: Console = .shared
    
    func extract<T>(at offset: Int = 0) -> T? {
        let endOffset: Int = offset + MemoryLayout<T>.size
        
        guard endOffset < target.count else {
            console.log(String(format: "Offset 0x%X is out of bounds for \(T.self)", endOffset), type: .error)
            return nil
        }
        
        let data: Data = target.subdata(in: offset ..< endOffset)
        
        return data.withUnsafeBytes { bytes in
            guard let pointer: UnsafePointer<T> = bytes.baseAddress?.bindMemory(to: T.self, capacity: 1) else {
                console.log(String(format: "Couldn't extract \(T.self) at 0x%X", offset), type: .error)
                return nil
            }
            
            return pointer.pointee
        }
    }
    
    func extractRaw(offset: Int, length: Int) -> Data? {
        guard offset + length < target.count, length >= 0 else {
            console.log(String(format: "Offset 0x%X is out of bounds", offset + length), type: .error)
            return nil
        }
        
        return target.subdata(in: offset ..< offset + length)
    }
}
