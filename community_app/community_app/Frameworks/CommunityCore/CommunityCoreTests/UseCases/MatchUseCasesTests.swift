//
//  DashboardUseCasesTests.swift
//  CommunityCoreTests
//
//  Created by Heelin Mistry on 2026/04/30.
//

import XCTest
@testable import CommunityCore

final class MatchUseCasesTests: XCTestCase {
    
    private var sut: MatchUseCases!
    private var mockRepository: MatchRepositoryMock!
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testMatchesExecute_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = MatchRepositoryMock()
        
        let expectedResponse: Matches = [.init()]
        await mockRepository.setMatchResult(
            .success(expectedResponse)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        let response = try await sut.userRelatedMatches()
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testMatchesExecute_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = MatchRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setMatchResult(
            .failure(expectedError)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        do {
            _ = try await sut.userRelatedMatches()
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testCreateMatch_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = MatchRepositoryMock()
        
        let expectedResponse: CreateMatchResponse = .init(match_id: "m_6cfbde8b")
        await mockRepository.setCreateMatchResult(
            .success(expectedResponse)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        let response = try await sut.userCreateMatch(.init())
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testCreateMatch_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = MatchRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setCreateMatchResult(
            .failure(expectedError)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        do {
            _ = try await sut.userCreateMatch(.init())
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testMatchDetail_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = MatchRepositoryMock()
        
        let expectedResponse: MatchDetailResponse = .init()
        await mockRepository.setMatchDetailResult(
            .success(expectedResponse)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        let response = try await sut.matchDetail(.init(""))
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testMatchDetail_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = MatchRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setMatchDetailResult(
            .failure(expectedError)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        do {
            _ = try await sut.matchDetail(.init(""))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testMatchParticipation_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = MatchRepositoryMock()
        
        let expectedResponse: ParticipationResponse = .init()
        await mockRepository.setParticipationResult(
            .success(expectedResponse)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        let response = try await sut.toggleParticipation(.init(""))
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testMatchParticipation_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = MatchRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setParticipationResult(
            .failure(expectedError)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        do {
            _ = try await sut.toggleParticipation(.init(""))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testMatchCancellation_WhenSuccessful_ReturnsSuccessResponse() async throws {
        mockRepository = MatchRepositoryMock()
        
        let expectedResponse: CancellationResponse = .init()
        await mockRepository.setCancellationResult(
            .success(expectedResponse)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        let response = try await sut.toggleCancellation(.init(""))
        
        XCTAssertTrue(response == expectedResponse)
    }
    
    func testMatchCancellation_WhenRepositoryThrowsError_ThrowsSameError() async {
        mockRepository = MatchRepositoryMock()
        
        let expectedError = NSError(domain: "NetworkError", code: 401, userInfo: nil)
        await mockRepository.setCancellationResult(
            .failure(expectedError)
        )
        
        let sut = MatchUseCases(match: mockRepository)
        do {
            _ = try await sut.toggleCancellation(.init(""))
            XCTFail("Expected error to be thrown, but it succeeded.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "NetworkError")
            XCTAssertEqual(nsError.code, 401)
        }
    }
}
