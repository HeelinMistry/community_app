//
//  CategoryPicker.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/05.
//

import SwiftUI

public struct CategoryPicker<SelectionValue: Hashable>: View {
    let options: [SelectionValue]
    @Binding var selection: SelectionValue
    let optionLabel: (SelectionValue) -> (text: String, icon: String)
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { value in
                    let labelData = optionLabel(value)
                    
                    Button(action: {
                        withAnimation(.spring()) { selection = value }
                    }, label: {
                        HStack(spacing: 8) {
                            Image(systemName: labelData.icon)
                            Text(labelData.text)
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selection == value ? Assets.theme.primary : Assets.theme.inputBackground)
                        .foregroundColor(selection == value ? .white : Assets.theme.secondaryText)
                        .cornerRadius(20)
                    })
                }
            }
            .padding(.horizontal)
        }
    }
}
