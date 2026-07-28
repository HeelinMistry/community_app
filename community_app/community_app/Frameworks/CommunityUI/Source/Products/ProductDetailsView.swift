//
//  ProductDetailsView.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/26.
//

import SwiftUI
import Foundation
import CommunityCore
import MapKit
import CoreLocation

// MARK: - Main SupplierDetailsView

public struct ProductDetailsView<T: ProductDetailsViewModelProtocol>: View {
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var viewModel: T

    // State to control the map's camera position
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    public init(viewModel: @escaping @autoclosure () -> T) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch viewModel.state {
                case .idle:
                    Text("Loading supplier details...")
                        .foregroundColor(Assets.theme.secondaryText)
                case .loading:
                    ProgressView("Loading Supplier Details...")
                        .controlSize(.large)
                case .success(let supplier):
                    Text("Success")
                case .error(let message):
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                }
            }
            .padding() // Padding around the VStack content
        }
        .navigationTitle(viewModel.isCreateProduct ? "Create Product" : "Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !viewModel.isCreateProduct {
                viewModel.productDetail()
            }
            Task {
                await viewModel.requestLocationAuthorization()
            }
        }
    }
}
