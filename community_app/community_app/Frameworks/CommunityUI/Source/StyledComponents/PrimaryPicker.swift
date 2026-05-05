//
//  PrimaryPicker.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/05.
//

import SwiftUI

public struct PrimaryPicker: View {
    
    let label: String
    /// A binding to the string value that the text field edits.
    @Binding var text: Sport
    
    /// Creates a primary text input field.
    /// - Parameters:
    ///   - label: The label for the input field.
    public init(
        label: String,
        text: Binding<Sport>
    ) {
        self.label = label
        self._text = text
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Assets.theme.secondaryText)
            
            Picker("Select \(label)", selection: $text) {
                ForEach(Sport.allCases) { sport in
                    Text(sport.localizedName).tag(sport)
                }
            }
            .pickerStyle(.menu) // or .segmented, .inline, etc. based on design preference
            .labelsHidden() // Hide the default picker label if Text("SPORT") is used
            .padding()
            .background(Assets.theme.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .accentColor(Assets.theme.primary)
        }
    }
}
