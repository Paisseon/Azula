//
//  ContentView.swift
//  Azula
//
//  Created by Lilliana on 15/05/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var isElleKit: Bool = false
    @State private var isImporting: Bool = false
    @State private var shouldSlice: Bool = false
    @State private var ipaURL: URL? = nil
    @State private var dylibURLs: [URL] = []
    
    var body: some View {
        VStack {
            Text("Azula 🔥")
                .font(.system(size: 32, design: .monospaced))
                .fontWeight(.semibold)
                .padding()
            
            VStack(alignment: .leading) {
                Toggle("Add ElleKit", isOn: $isElleKit)
                    .font(.system(size: 13, design: .monospaced))
                Toggle("Slice Codesign", isOn: $shouldSlice)
                    .font(.system(size: 13, design: .monospaced))
            }
            .padding()
            
            if ipaURL == nil || dylibURLs.isEmpty {
                Button("Select Files") { isImporting.toggle() }
                .font(.system(size: 13, design: .monospaced))
                .sheet(isPresented: $isImporting) {
                    FilePickerView(ipaURL: $ipaURL, dylibURLs: $dylibURLs, isShowing: $isImporting)
                }
            } else {
                Button("Patch") {
                    Task {
                        await patch()
                    }
                }
            }
            
            ConsoleView()
                .padding(30)
        }
    }
    
    private func patch() async {
        defer {
            ipaURL = nil
            dylibURLs = []
        }
        
        let ipaHelper: IPAHelper = .init(url: ipaURL!)
        
        guard let binURL: URL = ipaHelper.getBinaryURL() else {
            return
        }
        
        if isElleKit {
            guard let ekURL: URL = Bundle.main.url(forResource: "libellekit", withExtension: "dylib"),
                  ipaHelper.addDylib(ekURL)
            else {
                Console.shared.log("Hooking library not found", type: .error)
                return
            }
            
            for dylibURL in dylibURLs {
                let ekAzula: Azula = .init(
                    injecting: ["@executable_path/Azula/libellekit.dylib"],
                    removing: ["/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"],
                    from: dylibURL
                )
                
                guard ekAzula.remove(),
                      ekAzula.inject()
                else {
                    Console.shared.log("Couldn't fix Substrate path", type: .error)
                    return
                }
            }
        }
        
        let azula: Azula = .init(
            injecting: dylibURLs.map { "@executable_path/Azula/" + $0.lastPathComponent },
            removing: [],
            from: binURL
        )
        
        guard azula.inject() else {
            return
        }
        
        _ = dylibURLs.map {
            if !ipaHelper.addDylib($0) {
                Console.shared.log("Couldn't add \($0.lastPathComponent) to IPA", type: .warn)
            }
        }
        
        if shouldSlice {
            if azula.slice() {
                Console.shared.log("Sliced code signature", type: .info)
            } else {
                Console.shared.log("Couldn't slice code signature", type: .warn)
            }
        }
        
        ipaHelper.repackIPA(andInstall: shouldSlice)
        
        Console.shared.log("Glory to the Fire Nation 🔥", type: .info)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
