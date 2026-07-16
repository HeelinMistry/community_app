//
//  SupplierFeedItemView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/16.
//

import SwiftUI
import CommunityCore

// A new struct to display a single match, replacing FeedItemPlaceholder
struct SupplierFeedItemView: View {
    @EnvironmentObject private var router: NavigationRouter
    let supplier: SupplierResponse

    private var shadowColor: Color {
        if supplier.is_creator {
            return Assets.theme.primaryAccent.opacity(0.1) // Distinct color for creators
        } else {
            return Assets.theme.secondary.opacity(0.1)
        }
    }
    
    var body: some View {
        NavigationLink(value: Destination.supplierDetail(supplier_id: supplier.id)) {
            VStack(alignment: .leading, spacing: 8) {
                // Business Name
                PrimaryText(label: supplier.business_name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                // Category
                HStack {
                    Image(systemName: "tag.fill")
                    PrimaryText(label: supplier.category)
                }
                .font(.subheadline)
                .foregroundColor(Assets.theme.secondaryText)
                
                // Distance
                HStack {
                    Image(systemName: "location.fill")
                    Text(String(format: "%.1f km away", supplier.distance_km))
                }
                .font(.subheadline)
                .foregroundColor(Assets.theme.secondaryText)
                
                // Description
                Text(supplier.description)
                    .font(.caption)
                    .foregroundColor(Assets.theme.secondaryText)
                    .lineLimit(2) // Limit to 2 lines to keep the card compact
                    .padding(.vertical, 4)
                
                // Creator Status Indicator
                HStack {
                    if supplier.is_creator {
                        Label("You are Creator", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                HStack {
                    ShareLink(
                        item: URL(string: "community-app://com.mistcreation.community-app/supplier/\(supplier.id)")!,
                        subject: Text("Supplier Details")
                    ) {
                        Label("Share Supplier", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(Assets.theme.secondaryText)
                    .padding(.top, 8)
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            .padding()
            .background(Assets.theme.inputBackground)
            .cornerRadius(15)
            .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
