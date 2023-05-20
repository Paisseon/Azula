//
//  DylibCommand.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import MachO

struct DylibCommand: LoadCommand {
    typealias T = dylib_command
    
    let offset: Int
    let command: T
    let mh: MachHeader
}
