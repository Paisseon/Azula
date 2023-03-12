//
//  FilePickerView.swift
//  AzulaApp
//
//  Created by Lilliana on 05/03/2023.
//

import AzulaKit
import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    @Binding var fileURLs: [URL]
    @State private var isImporting: Bool = false
    let title: String
    let fileExtension: String
    let allowMultiple: Bool

    var body: some View {
        HStack {
            Button("Import") {
                isImporting = true
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType(filenameExtension: fileExtension)!],
                allowsMultipleSelection: allowMultiple
            ) { result in
                Task {
                    if let urls: [URL] = try? result.get() {
                        fileURLs = urls.map {
                            guard fileExtension == "dylib" else {
                                RainbowLogger.shared.print(Log(text: "Imported IPA", type: .info))
                                return $0
                            }

                            let newURL: URL = docs.slash($0.lastPathComponent)
                            
                            do {
                                try FileHelper.copy(from: $0, to: newURL)
                            } catch {
                                RainbowLogger.shared.print(Log(text: "Couldn't copy dylib to workspace", type: .error))
                                return $0
                            }

                            return newURL
                        }
                    }
                }
            }

            Text(fileURLs.isEmpty ? title : fileURLs.map(\.path).joined(separator: ", "))
        }
    }

    private let docs: URL = try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    )
}
