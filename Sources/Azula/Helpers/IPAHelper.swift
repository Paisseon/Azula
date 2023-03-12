//
//  IPAHelper.swift
//  Azula
//
//  Created by Lilliana on 04/03/2023.
//

import AzulaKit
import Foundation
import ZIPFoundation

struct IPAHelper {
    let ipaURL: URL
    let pretty: RainbowLogger
    
    func getBinaryURL() -> URL? {
        let docs: URL = ipaURL.deletingLastPathComponent()
        let workURL: URL = docs.slash(".Workspace")
        let payloadURL: URL = workURL.slash("Payload")
        
        if access(workURL.path, F_OK) == 0 {
            try? FileHelper.remove(at: workURL)
        }
        
        do {
            try FileManager.default.unzipItem(at: ipaURL, to: workURL)
        } catch {
            pretty.print(Log(text: error.localizedDescription, type: .error))
            return nil
        }
        
        guard let appURL: URL = try? FileManager.default.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: []
        ).first else {
            pretty.print(Log(text: "Couldn't find app in Payload", type: .error))
            return nil
        }
        
        return appURL.slash(appURL.lastPathComponent.dropLast(4).description)
    }
    
    func repackIPA() {
        let docs: URL = ipaURL.deletingLastPathComponent()
        let workURL: URL = docs.slash(".Workspace")
        let payloadURL: URL = workURL.slash("Payload")
        let outputURL: URL = docs.slash(ipaURL.lastPathComponent.dropLast(4).description + "_Patched.ipa")
        
        do {
            if access(outputURL.path, F_OK) == 0 {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            pretty.print(Log(text: "Compressing patched IPA...", type: .info))
            
            try FileManager.default.zipItem(at: payloadURL, to: outputURL)
            try FileHelper.remove(at: workURL)
        } catch {
            pretty.print(Log(text: error.localizedDescription, type: .error))
        }
    }
    
    func addDylib(
        _ dylibURL: URL
    ) -> Bool {
        let docs: URL = ipaURL.deletingLastPathComponent()
        let workURL: URL = docs.slash(".Workspace")
        let payloadURL: URL = workURL.slash("Payload")
        
        guard let appURL: URL = try? FileManager.default.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: []
        ).first else {
            pretty.print(Log(text: "Couldn't find app in Payload", type: .error))
            return false
        }
        
        do {
            let frameworksURL: URL = appURL.slash("Azula")
            
            if access(frameworksURL.path, F_OK) != 0 {
                try FileHelper.makeDirectory(at: frameworksURL)
            }
            
            try FileHelper.copy(from: dylibURL, to: frameworksURL.slash(dylibURL.lastPathComponent))
        } catch {
            pretty.print(Log(text: error.localizedDescription, type: .warn))
            return false
        }
        
        pretty.print(Log(text: "Added \(dylibURL.lastPathComponent) to IPA", type: .info))
        
        return true
    }
}
