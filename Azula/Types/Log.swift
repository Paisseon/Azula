//
//  Log.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import Foundation

struct Log: Hashable {
    let id: UUID = .init()
    let message: String
    let type: LogType
}
