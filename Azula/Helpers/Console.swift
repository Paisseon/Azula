//
//  Console.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Combine

final class Console: ObservableObject {
    static let shared: Console = .init()
    @Published private(set) var logs: [Log] = []
    
    func log(_ message: String, type: LogType) {
        Task {
            await MainActor.run {
                self.logs.append(Log(message: message, type: type))
            }
        }
    }
}
