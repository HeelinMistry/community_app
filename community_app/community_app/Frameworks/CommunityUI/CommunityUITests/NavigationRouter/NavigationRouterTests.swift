//
//  NavigationRouterTests.swift
//  community_appTests
//
//  Created by Heelin Mistry on 2026/05/02.
//

import CommunityUI // Import the module where NavigationRouter is defined
import SwiftUI      // Needed for NavigationPath, Alert.Button
import XCTest

@MainActor
final class NavigationRouterTests: XCTestCase {
    private var router: NavigationRouter!
    
    override func setUp() {
        super.setUp()
        router = .init()
    }
    
    override func tearDown() {
        router = nil
        super.tearDown()
    }
    
    func testNavigateToDestination() async {
        let initialPathCount = router.path.count
        let destination: Destination = .dashboard

        router.navigate(to: destination)

        XCTAssert(router.path.count == initialPathCount + 1, "Path count should increase by 1.")
    }

    func testPresentSheet() async {
        let sheetDestination: SheetDestination = .registration

        router.present(sheet: sheetDestination)

        XCTAssert(router.sheet == sheetDestination, "The sheet should be set to the specified destination.")
        XCTAssert(router.sheet?.id == sheetDestination.id, "The sheet's ID should match the destination's ID.")
    }

    func testAlertPresentation() async {
        let title = "Test Alert"
        let message = "This is a test message."

        router.alert(title: title, message: message)

        XCTAssert(router.alertItem != nil, "An alert item should be present.")
        XCTAssert(router.alertItem?.title == title, "Alert title should match.")
        XCTAssert(router.alertItem?.message == message, "Alert message should match.")
    }

    func testLoginSuccess() async {
        router.isAuthenticated = false
        router.present(sheet: .registration) // Simulate a sheet being open
        router.path.append(Destination.login) // Simulate some path history

        XCTAssert(router.sheet != nil, "Sheet should initially be present.")
        XCTAssert(!router.path.isEmpty, "Path should initially have items.")
        XCTAssert(router.isAuthenticated == false, "User should initially not be authenticated.")

        router.loginSuccess()

        XCTAssert(router.sheet == nil, "Sheet should be dismissed after login success.")
        XCTAssert(router.isAuthenticated == true, "User should be authenticated after login success.")
        XCTAssert(router.path.isEmpty, "Navigation path should be cleared after login success.")
    }

    func testInitialState() async {
        XCTAssert(router.path.isEmpty, "Path should be empty initially.")
        XCTAssert(router.sheet == nil, "Sheet should be nil initially.")
        XCTAssert(router.alertItem == nil, "Alert item should be nil initially.")
        XCTAssert(router.isAuthenticated == false, "User should not be authenticated initially.")
    }
}
