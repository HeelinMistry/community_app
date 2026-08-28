//
//  TagChip.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/28.
//

import SwiftUI

public struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    public var body: some View {
        HStack {
            Text(tag)
                .font(.subheadline)
                .foregroundColor(Assets.theme.primary)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Assets.theme.primary.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Assets.theme.primary.opacity(0.3), lineWidth: 1)
        )
    }
}
