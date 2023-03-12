//
//  CheckboxView.swift
//  AzulaApp
//
//  Created by Lilliana on 05/03/2023.
//

import SwiftUI

struct CheckboxView: View {
    @Binding var isChecked: Bool
    let title: String
    
    private func toggle() {
        isChecked.toggle()
    }
    
    var body: some View {
        HStack {
            Button(action: toggle) {
                Image(systemName: isChecked ? "checkmark.square" : "square")
            }
            .buttonStyle(.borderless)
            
            Text(title)
        }
    }
}
