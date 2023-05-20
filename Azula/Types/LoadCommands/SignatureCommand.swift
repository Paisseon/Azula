//
//  SignatureCommand.swift
//  Azula
//
//  Created by Lilliana on 16/05/2023.
//

import MachO

struct SignatureCommand: LoadCommand {
    typealias T = linkedit_data_command
    
    let offset: Int
    let command: T
}
