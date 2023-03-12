//
//  URL.swift
//  AzulaApp
//
//  Created by Lilliana on 04/03/2023.
//

import Foundation

extension URL {
    func slash(
        _ nextPath: String
    ) -> URL {
        appendingPathComponent(nextPath)
    }
}
