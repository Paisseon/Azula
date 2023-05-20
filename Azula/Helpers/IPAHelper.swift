//
//  IPAHelper.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import UniformTypeIdentifiers
import ZIPFoundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

private let docs: URL = try! FileManager.default.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false
)

struct IPAHelper {
    let url: URL
    private let console: Console = .shared
    private var workURL: URL { docs.appendingPathComponent(".Workspace") }
    private var payloadURL: URL { workURL.appendingPathComponent("Payload") }
    
    func getBinaryURL() -> URL? {
        do {
            if access(workURL.path, F_OK) == 0 {
                try FileManager.default.removeItem(at: workURL)
            }
            
            try FileManager.default.unzipItem(at: url, to: workURL)
        } catch {
            console.log(error.localizedDescription, type: .error)
            return nil
        }
        
        guard let appURL: URL = try? FileManager.default.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: []
        ).first else {
            console.log("Couldn't find app in IPA", type: .error)
            return nil
        }
        
        return appURL.appendingPathComponent(appURL.lastPathComponent.dropLast(4).description)
    }
    
    func repackIPA(andInstall installWithTS: Bool = false) {
        let outputURL: URL = docs.appendingPathComponent(url.lastPathComponent.dropLast(4).description + "_Patched.ipa")
        
        do {
            if access(outputURL.path, F_OK) == 0 {
                try FileManager.default.removeItem(at: outputURL)
            }
            
            try FileManager.default.zipItem(at: payloadURL, to: outputURL)
            
            #if os(iOS)
            if installWithTS,
               let tsURL: URL = .init(string: "apple-magnifier://install?url=file://" + outputURL.path),
               UIApplication.shared.canOpenURL(tsURL)
            {
                console.log("Opening in TrollStore…", type: .info)
                UIApplication.shared.open(tsURL)
            } else {
                console.log("Can't open TrollStore", type: .error)
            }
            #else
            DispatchQueue.main.async {
                let savePanel: NSSavePanel = .init()
                
                savePanel.allowedContentTypes = [UTType(filenameExtension: "ipa")!]
                savePanel.canCreateDirectories = true
                savePanel.isExtensionHidden = false
                savePanel.nameFieldStringValue = outputURL.lastPathComponent.dropLast(4).description
                savePanel.title = "Save Patched IPA"
                savePanel.message = "Select"
                
                let response: NSApplication.ModalResponse = savePanel.runModal()
                
                if response == .OK,
                   let saveURL: URL = savePanel.url
                {
                    try? FileManager.default.moveItem(at: outputURL, to: saveURL)
                }
            }
            #endif
        } catch {
            console.log(error.localizedDescription, type: .error)
        }
    }
    
    func addDylib(_ dylibURL: URL) -> Bool {
        guard let appURL: URL = try? FileManager.default.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: []
        ).first else {
            console.log("Couldn't find app in IPA", type: .error)
            return false
        }
        
        let azulaURL: URL = appURL.appendingPathComponent("Azula")
        let frameworksURL: URL = appURL.appendingPathComponent("Frameworks")
        
        do {
            // Fix ZIPFoundation sometimes breaking empty frameworks, making apps uninstallable
            
            if !frameworksURL.hasDirectoryPath {
                try FileManager.default.removeItem(at: frameworksURL)
            }
            
            mkdir(frameworksURL.path, S_IRWXU | S_IRWXG | S_IRWXO)
            mkdir(azulaURL.path, S_IRWXU | S_IRWXG | S_IRWXO)
            
            try FileManager.default.copyItem(at: dylibURL, to: azulaURL.appendingPathComponent(dylibURL.lastPathComponent))
        } catch {
            console.log(error.localizedDescription, type: .warn)
            return false
        }
        
        return true
    }
}
