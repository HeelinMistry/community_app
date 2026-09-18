//
//  MultiTagPickerView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import SwiftUI

public struct MultiTagPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    let availableTags: [String]
    @Binding var chosenTags: [String]
    let theme: Theme // Use the AppTheme to access colors
    
    // Internal state to hold selections before confirming
    @State private var internalSelectedTags: Set<String>
    
    public init(availableTags: [String], chosenTags: Binding<[String]>, theme: Theme) {
        self.availableTags = availableTags
        self._chosenTags = chosenTags
        self.theme = theme
        _internalSelectedTags = State(initialValue: Set(chosenTags.wrappedValue))
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    Button {
                        if internalSelectedTags.contains(tag) {
                            internalSelectedTags.remove(tag)
                        } else {
                            internalSelectedTags.insert(tag)
                        }
                    } label: {
                        HStack {
                            Text(tag)
                                .foregroundColor(theme.secondaryText)
                            Spacer()
                            if internalSelectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accentColor(theme.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        chosenTags = Array(internalSelectedTags).sorted()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accentColor(theme.primary)
                }
            }
        }
    }
}
