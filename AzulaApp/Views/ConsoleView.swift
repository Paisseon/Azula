//
//  ConsoleView.swift
//  AzulaApp
//
//  Created by Lilliana on 05/03/2023.
//

import AzulaKit
import SwiftUI

// MARK: - ConsoleView

struct ConsoleView: View {
    // MARK: Internal

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading) {
                    ForEach(rainbow.logs, id: \.id) { log in
                        LogMessageView(log: log)
                            .id(log.id)
                    }
                }
                .onChange(of: rainbow.logs.count) { _ in
                    proxy.scrollTo(rainbow.logs.last?.id, anchor: .bottom)
                }
            }
        }
        .frame(minWidth: 300, minHeight: 100)
        .padding()
        .background(Color.black.clipShape(RoundedRectangle(cornerRadius: 18)))
    }

    // MARK: Private

    @StateObject private var rainbow: RainbowLogger = .shared
}
