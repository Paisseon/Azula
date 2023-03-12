//
//  IPAHelper.swift
//  AzulaApp
//
//  Created by Lilliana on 04/03/2023.
//

#if os(macOS)
import AppKit
#endif

import AzulaKit
import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

private let docs: URL = try! FileManager.default.url(
    for: .documentDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false
)

struct IPAHelper {
    let ipaURL: URL
    let pretty: RainbowLogger = .shared
    
    func getBinaryURL() -> URL? {
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
            
            #if os(macOS)
            Task {
                await MainActor.run {
                    showSavePanel(for: outputURL)
                }
            }
            #endif
        } catch {
            pretty.print(Log(text: error.localizedDescription, type: .error))
        }
    }
    
    func addDylib(
        _ dylibURL: URL
    ) -> Bool {
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
            let azulaDirURL: URL = appURL.slash("Azula")
            let frameworksURL: URL = appURL.slash("Frameworks")
            
            if !frameworksURL.hasDirectoryPath {
                try FileHelper.remove(at: frameworksURL)
            }
            
            if access(frameworksURL.path, F_OK) != 0 {
                try FileHelper.makeDirectory(at: frameworksURL)
            }
            
            if access(azulaDirURL.path, F_OK) != 0 {
                try FileHelper.makeDirectory(at: azulaDirURL)
            }
            
            try FileHelper.copy(from: dylibURL, to: azulaDirURL.slash(dylibURL.lastPathComponent))
        } catch {
            pretty.print(Log(text: error.localizedDescription, type: .warn))
            return false
        }
        
        pretty.print(Log(text: "Added \(dylibURL.lastPathComponent) to IPA files", type: .info))
        
        return true
    }
    
    #if os(macOS)
    @MainActor
    private func showSavePanel(
        for ipaURL: URL
    ) {
        let savePanel: NSSavePanel = .init()
        
        savePanel.allowedContentTypes = [UTType(filenameExtension: "ipa")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = ipaURL.lastPathComponent.dropLast(4).description
        savePanel.title = "Save patched IPA"
        savePanel.message = "Choose a location to save"
        
        let response: NSApplication.ModalResponse = savePanel.runModal()
        let url: URL? = response == .OK ? savePanel.url : nil
        
        if let url {
            do {
                try FileHelper.move(from: ipaURL, to: url)
            } catch {
                pretty.print(Log(text: error.localizedDescription, type: .error))
                pretty.print(Log(text: "Couldn't save IPA", type: .error))
            }
        }
    }
    #endif
}
