//
//  RainbowLogger.swift
//  AzulaApp
//
//  Created by Lilliana on 04/03/2023.
//

import AzulaKit
import Combine
import Dispatch

final class RainbowLogger: ObservableObject, PrettyPrinter {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared: RainbowLogger = .init()

    @Published private(set) var logs: [Log] = []

    func print(_ log: Log) {
        DispatchQueue.main.async {
            self.logs.append(log)
        }
    }
}
