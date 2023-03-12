//
//  RainbowLogger.swift
//  Azula
//
//  Created by Lilliana on 16/02/2023.
//

import AzulaKit

struct RainbowLogger: PrettyPrinter {
    func print(
        _ log: Log
    ) {
        let faint: String = "\u{001B}[38;5;249m"
        let green: String = "\u{001B}[38;5;46m"
        let red: String = "\u{001B}[38;5;196m"
        let reset: String = "\u{001B}[0m"
        let yellow: String = "\u{001B}[38;5;226m"

        switch log.type {
            case .error:
                Swift.print("\(faint)[\(red)!\(faint)]\(reset) " + log.text)
            case .info:
                Swift.print("\(faint)[\(green)*\(faint)]\(reset) " + log.text)
            case .warn:
                Swift.print("\(faint)[\(yellow)!\(faint)]\(reset) " + log.text)
        }
    }
}
