//
//  URL.swift
//  Azula
//
//  Created by Lilliana on 05/03/2023.
//

import Foundation

extension URL {
    func slash(
        _ nextPath: String
    ) -> URL {
        appendingPathComponent(nextPath)
    }
}
