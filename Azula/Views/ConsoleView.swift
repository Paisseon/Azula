//
//  ConsoleView.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import SwiftUI

#if os(iOS)
private struct VisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    }
}
#else
private struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        return NSVisualEffectView()
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .contentBackground
    }
}
#endif

struct ConsoleView: View {
    @StateObject private var console: Console = .shared
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(console.logs, id: \.self) { log in
                            LogMessageView(log: log)
                        }
                    }
                    .padding()
                    .padding(.bottom, 10)
                    .id("NYESTE_LOG")
                }
                .onChange(of: console.logs) { _ in
                    withAnimation {
                        proxy.scrollTo("NYESTE_LOG", anchor: .bottom)
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 100)
    }
}
