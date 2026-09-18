//
//  ProductFeedView.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/08/15.
//

import Foundation
import SwiftUI
import MapKit
import CommunityCore

public struct ProductFeedView<T: DashboardViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.dashboardModel.products, id: \.id) { product in
                    ProductFeedItemView(product: product)
                }
                // Add a Spacer to push the list items to the top if they don't fill the available space.
                Spacer()
            }
        }
        
        // Ensure the VStack fills all available vertical space in both map and list modes.
        // A VStack naturally aligns its content to the top.
    }
}
