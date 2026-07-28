//
//  ProductDetailsViewModelProtocol.swift
//  CommunityUI
//
//  Created by Heelin Mistry on 2026/07/26.
//

import Combine
import CommunityCore
import CoreLocation
import MapKit
import Foundation
import SwiftUI

@MainActor
public protocol ProductDetailsViewModelProtocol: ValidatableViewModel where DataType == SupplierDetailResponse {
//    var supplierDetailResponse: SupplierDetailResponse? { get }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    var productURL: URL? { get }
    var isCreateProduct: Bool { get }

    func productDetail()
    func requestLocationAuthorization() async
}
