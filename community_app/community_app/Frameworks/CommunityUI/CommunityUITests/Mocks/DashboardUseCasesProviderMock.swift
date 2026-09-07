//
//  DashboardUseCasesProviderMock.swift
//  community_app
//
//  Created by Heelin Mistry on 2026/07/11.
//

import Foundation
import CommunityCore
@testable import CommunityUI

final class DashboardUseCasesProviderMock: DashboardUseCasesProvider, @unchecked Sendable {
    
    let mockSuppliersUseCases = SupplierUseCasesMock()
    var suppliers: any SupplierUseCasesProtocol { mockSuppliersUseCases }
    
    let mockProductsUseCases = ProductUseCasesMock()
    var products: any ProductUseCasesProtocol { mockProductsUseCases }
    
    let mockMatchUseCases = MatchUseCasesMock()
    var matches: any MatchUseCaseProtocol { mockMatchUseCases }
    
    let locationMock = LocationServiceMock()
    var location: any LocationProtocol { locationMock }
}
