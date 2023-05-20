//
//  MachHeader.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import MachO

struct MachHeader {
    let header: mach_header_64
    let offset: Int
}
