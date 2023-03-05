//
//  SwiftStudyTests.swift
//  SwiftStudyTests
//
//  Created by oozoofrog on 2023/02/01.
//

import XCTest
@testable import SwiftCommitStudy

final class SwiftStudyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCommitLine() throws {
        let line = "06452fbb47f 1675260005 Merge pull request #63329 from aschwaighofer/initial_relative_protocol_witness_tables_runtime"

        let commitLine = CommitLine(line)!
        XCTAssertEqual(commitLine.commit, "06452fbb47f")
        XCTAssertEqual(commitLine.date, Date(timeIntervalSince1970: 1675260005))
        XCTAssertEqual(commitLine.comment, "Merge pull request #63329 from aschwaighofer/initial_relative_protocol_witness_tables_runtime")
    }

    func testCommitLines() async throws {

        let url = Bundle(for: Self.self).url(forResource: "testcommits", withExtension: "")!
        let commitLines = CommitLines(fileURL: url)

        var lines: [CommitLine] = []
        for try await line in try await commitLines.lines() {
            lines.append(line)
        }
        XCTAssertEqual(lines.count, 6)
        XCTAssertEqual(lines.map(\.commit), ["48546fd6d35","39d32642374","3302b27df8a","e6e7bd06290","11a55ec3a0a","8d49757fc69"])

        let dates = [
            1675201837,
            1675199382,
            1675206432,
            1675205790,
            1675202360,
            1675197345
        ].map(TimeInterval.init).map({ Date(timeIntervalSince1970: $0) })
        XCTAssertEqual(lines.map(\.date), dates)

        let comments = [
            "[move-only] Move BorrowToDestructureTransform back into the Object Checker rather than as a separate pass.",
            "[move-only] Make sure that when the borrow to destructure transform emits an error, we clean up the IR appropriately.",
            "Merge pull request #62775 from AnthonyLatsis/sugar-type-members-2",
            "Merge pull request #63296 from hyp/eng/print-ns-interface-quick",
            "ModuleInterface: Coallesce `@_backDeploy` attributes when printed.",
            "Merge pull request #63222 from xedin/diag-ambiguous-requirement-failures"
        ]
        XCTAssertEqual(lines.map(\.comment), comments)
    }
}
