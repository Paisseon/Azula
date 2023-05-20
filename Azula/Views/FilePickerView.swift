//
//  FilePickerView.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    @Binding var ipaURL: URL?
    @Binding var dylibURLs: [URL]
    @Binding var isShowing: Bool
    @State private var ipaImporting: Bool = false
    @State private var dylibImporting: Bool = false
    
    private let docs: URL = try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false
    )
    
    var body: some View {
        VStack {
            Button { ipaImporting.toggle() } label: {
                Label("Select IPA   ", systemImage: "square.and.arrow.up")
                    .font(.system(size: 13, design: .monospaced))
            }
                .fileImporter(
                    isPresented: $ipaImporting,
                    allowedContentTypes: [UTType(filenameExtension: "ipa")!]
                ) { result in
                    ipaURL = try? result.get()
                    isShowing = ipaURL == nil || dylibURLs.isEmpty
                }
                .padding([.top, .leading, .trailing])
                .opacity(ipaURL == nil ? 1 : 0.5)
             
            Button { dylibImporting.toggle() } label: {
                Label("Select Dylibs", systemImage: "square.and.arrow.up")
                    .font(.system(size: 13, design: .monospaced))
            }
                .fileImporter(
                    isPresented: $dylibImporting,
                    allowedContentTypes: [UTType(filenameExtension: "dylib")!],
                    allowsMultipleSelection: true
                ) { result in
                    dylibURLs = (try? result.get()) ?? []
                    isShowing = ipaURL == nil || dylibURLs.isEmpty
                }
                .padding([.leading, .trailing])
                .opacity(dylibURLs.isEmpty ? 1 : 0.5)
            
            Button { isShowing.toggle() } label: {
                Label("Cancel       ", systemImage: "xmark.square")
                    .font(.system(size: 13, design: .monospaced))
            }
            .padding([.bottom, .leading, .trailing])
        }
    }
}
