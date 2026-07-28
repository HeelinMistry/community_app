import Combine
import CommunityCore
import CoreLocation
import MapKit
import Foundation // For URL
import SwiftUI

@MainActor
public protocol SupplierDetailsViewModelProtocol: ValidatableViewModel where DataType == SupplierDetailResponse {
    var supplierDetailResponse: SupplierDetailResponse? { get }
    var lastKnownLocation: CLLocation? { get }
    var isAuthorized: Bool { get }
    var supplierURL: URL { get }

    func supplierDetail()
    func requestLocationAuthorization() async
    func showDirectionsOnMap()
}
