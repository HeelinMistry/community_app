//
//  PrimaryPicker.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/05/05.
//

import SwiftUI

public struct PrimaryPicker<SelectionValue: Hashable>: View {
    
    let label: String
    /// A binding to the selected value of the picker.
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    let optionLabel: (SelectionValue) -> Text
    var errorMessage: String?
    
    /// Creates a primary picker field.
    /// - Parameters:
    ///   - label: The label for the input field.
    ///   - selection: A binding to the selected value.
    ///   - options: An array of values to choose from in the picker.
    ///   - optionLabel: A closure that provides a `Text` view for each option. Defaults to `Text(String(describing: value))`.
    ///   - errorMessage: An optional error message to display below the picker.
    public init(
        label: String,
        selection: Binding<SelectionValue>,
        options: [SelectionValue],
        optionLabel: @escaping (SelectionValue) -> Text = { value in Text(String(describing: value)) },
        errorMessage: String? = nil
    ) {
        self.label = label
        self._selection = selection
        self.options = options
        self.optionLabel = optionLabel
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(errorMessage == nil ? Assets.theme.secondaryText : .red)
            
            Picker("Select \(label)", selection: $selection) {
                ForEach(options, id: \.self) { value in
                    optionLabel(value).tag(value)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .padding()
            .background(Assets.theme.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorMessage == nil ? Color.white.opacity(0.1) : Color.red, lineWidth: 1)
            )
            .accentColor(Assets.theme.primary)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
}
