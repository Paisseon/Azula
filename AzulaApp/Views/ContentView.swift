//
//  ContentView.swift
//  AzulaApp
//
//  Created by Lilliana on 02/03/2023.
//

import AzulaKit
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    // MARK: Internal

    @State private var isElleKit: Bool = true
    @State private var shouldSlice: Bool = false
    @State private var targetURLs: [URL] = []
    @State private var dylibURLs: [URL] = []

    var body: some View {
        VStack {
            HStack {
                Image("HeaderIcon")
                
                Text("Azula")
                    .font(.title)
                    .padding([.top, .trailing, .bottom])
            }

            VStack(alignment: .leading) {
                FilePickerView(
                    fileURLs: $targetURLs,
                    title: "Target IPA",
                    fileExtension: "ipa",
                    allowMultiple: false
                )

                FilePickerView(
                    fileURLs: $dylibURLs,
                    title: "Dylib(s)",
                    fileExtension: "dylib",
                    allowMultiple: true
                )

                CheckboxView(isChecked: $isElleKit, title: "Add ElleKit")
                    .padding([.leading, .trailing, .top])

                #if os(iOS)
                CheckboxView(isChecked: $shouldSlice, title: "TrollStore Install")
                    .padding([.leading, .trailing, .bottom])
                #else
                CheckboxView(isChecked: $shouldSlice, title: "Slice Code Signature")
                    .padding([.leading, .trailing, .bottom])
                #endif
            }

            Button("Patch") {
                Task(priority: .userInitiated) {
                    await patch()
                }
            }
            .disabled(targetURLs.isEmpty || dylibURLs.isEmpty)
            .padding()

            ConsoleView()
                .shadow(radius: 10)
                .padding()
        }
        .padding()
    }

    // MARK: Private

    private func patch() async {
        let ipaHelper: IPAHelper = .init(ipaURL: targetURLs.first!)

        guard let binURL: URL = ipaHelper.getBinaryURL() else {
            return
        }
        
        #if DEBUG
        let tick: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        #endif

        if isElleKit {
            guard let ellekitURL: URL = Bundle.main.url(forResource: "libellekit", withExtension: "dylib"),
                  ipaHelper.addDylib(ellekitURL)
            else {
                RainbowLogger.shared.print(Log(text: "libellekit.dylib not found", type: .error))
                return
            }

            let tmpAzula: AzulaKit = .init(
                dylibs: ["@executable_path/Azula/libellekit.dylib"],
                remove: ["/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"],
                targetURL: dylibURLs.first!,
                printer: RainbowLogger.shared
            )

            guard tmpAzula.remove(),
                  tmpAzula.inject()
            else {
                RainbowLogger.shared.print(Log(text: "Couldn't replace Substrate with ElleKit", type: .error))
                return
            }
        }

        let azula: AzulaKit = .init(
            dylibs: dylibURLs.map { "@executable_path/Azula/" + $0.lastPathComponent },
            remove: [],
            targetURL: binURL,
            printer: RainbowLogger.shared
        )

        if azula.inject() {
            for dylibURL in dylibURLs {
                guard ipaHelper.addDylib(dylibURL) else {
                    RainbowLogger.shared.print(Log(text: "Couldn't add \(dylibURL.lastPathComponent) to IPA", type: .error))
                    return
                }
            }

            if shouldSlice {
                RainbowLogger.shared.print(Log(text: "Slicing code signature...", type: .info))
                _ = azula.slice()
            }

            ipaHelper.repackIPA(forTrollStore: shouldSlice)

            RainbowLogger.shared.print(Log(text: "Glory to the Fire Nation 🔥", type: .info))
            
            targetURLs = []
            dylibURLs = []
        }
        
        #if DEBUG
        let tock: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
        let stepRuntime: String = .init(format: "%.2fs", tock - tick)
        
        RainbowLogger.shared.print(Log(text: "Completed in \(stepRuntime)", type: .info))
        #endif
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
