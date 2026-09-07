//
//  ProductFeedItemView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/15.
//

import SwiftUI
import CommunityCore

struct ProductFeedItemView: View {
    @EnvironmentObject private var router: NavigationRouter
    let product: ProductResponse

    private var shadowColor: Color {
        if product.is_creator {
            return Assets.theme.primaryAccent.opacity(0.1) // Distinct color for creators
        } else {
            return Assets.theme.secondary.opacity(0.1)
        }
    }
    
    var body: some View {
        NavigationLink(value: Destination.productDetail(product_id: product.id)) {
            VStack(alignment: .leading, spacing: 8) {
                // Business Name
                PrimaryText(label: product.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                // Description
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(Assets.theme.secondaryText)
                    .lineLimit(2) // Limit to 2 lines to keep the card compact
                    .padding(.vertical, 4)
                
                // Distance
                HStack {
                    Image(systemName: "location.fill")
                    Text(String(format: "%.1f km away", product.distance_km))
                }
                .font(.subheadline)
                .foregroundColor(Assets.theme.secondaryText)
                
                // Creator Status Indicator
                HStack {
                    if product.is_creator {
                        Label("You are Creator", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(Assets.theme.primaryAccent)
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                HStack {
                    ShareLink(
                        item: URL(string: "community-app://com.mistcreation.community-app/product/\(product.id)")!,
                        subject: Text("Product Details")
                    ) {
                        Label("Share Product", systemImage: "square.and.arrow.up")
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
