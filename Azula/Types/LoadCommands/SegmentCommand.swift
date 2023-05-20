//
//  SegmentCommand.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import MachO

struct SegmentCommand: LoadCommand {
    typealias T = segment_command_64
    
    let offset: Int
    let command: T
}
