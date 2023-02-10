//
//  CommitParser.swift
//  SwiftStudy
//
//  Created by oozoofrog on 2023/02/01.
//

import Foundation
import RegexBuilder
import SwiftUI
import Combine

final class Commits: ObservableObject {

    enum State: Equatable {
        case idle
        case gathering(Int)
        case saving(Int)
        case deleting
        case finish

        var isUpdating: Bool {
            self != .finish && self != .idle
        }
    }

    @Published var state: State = .idle
    @Published var parsedCommitLine: CommitLine?

    let visibleLimit = 10
    var visibleOffset: Int {
        get {
            UserDefaults.standard.integer(forKey: "VisibleOffset")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "VisibleOffset")
            objectWillChange.send()
        }
    }
    var visibleEnd: Int {
        visibleOffset + visibleLimit
    }

    @MainActor
    func updateGathering(_ count: Int) {
        self.state = .gathering(count)
    }

    @MainActor
    func updateSaving(_ count: Int) {
        self.state = .saving(count)
    }

    @MainActor
    func updateDeleting() {
        self.state = .deleting
    }

    @MainActor
    func finish() {
        self.state = .finish
    }

    @MainActor
    func updateCommitLine(_ line: CommitLine) {
        self.parsedCommitLine = line
    }

    func load() {
        Task {
            await self.updateGathering(0)
            do {
                var lines: [CommitLine] = []
                var count = 0
                var date = Date()
                for try await line in try await CommitLines(fileURL: Bundle.main.url(forResource: "commits", withExtension: nil)!).lines() {
                    lines.append(line)
                    count += 1
                    if Date().timeIntervalSince(date) > 0.1 {
                        date = Date()
                        await self.updateGathering(count)
                    }
                    if lines.count > 10000 {
                        try await PersistenceController.shared.insert(lines)
                        lines = []
                    }
                }
                await self.updateSaving(count)
                try await PersistenceController.shared.insert(lines)
            } catch {
                assertionFailure(error.localizedDescription)
            }
            await self.finish()
        }
    }

    func deleteAll() {
        Task {
            do {
                await self.updateDeleting()
                try await PersistenceController.shared.deleteAll()
                await self.finish()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }

    func checkUntil(_ commit: Commit) async {
        do {
            if let commitHash = commit.commit {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(commitHash, forType: NSPasteboard.PasteboardType.string)
            }
            try await PersistenceController.shared.checkAll(until: commit)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

struct CommitLines {

    let fileURL: URL

    func lines() async throws -> AsyncThrowingStream<CommitLine, Error> {
        var lines = try await URLSession.shared.bytes(from: fileURL).0.lines.makeAsyncIterator()
        return AsyncThrowingStream {
            if let line = try await lines.next() {
                return CommitLine(line)
            } else {
                return nil
            }
        }
    }

}

struct CommitLine {

    let commit: String
    let date: Date
    let comment: String

    @Sendable init?(_ line: String) {
        guard let (commit, date, comment) = Parser(line: line.trimmingCharacters(in: .whitespacesAndNewlines)).parse() else {
            return nil
        }
        self.commit = commit
        self.date = date
        self.comment = comment
    }

    var dictionary: [String: Any] {
        [
            "commit": commit,
            "date": date,
            "comment": comment
        ]
    }

    struct Parser {
        let line: String

        func parse() -> (String, Date, String)? {
            let regex = Regex {
                Capture {
                    OneOrMore(.hexDigit)
                }
                OneOrMore { .whitespace }
                Capture {
                    OneOrMore(.digit)
                }
                OneOrMore { .whitespace }
                Capture {
                    OneOrMore(.anyNonNewline)
                }
            }
            do {
                if let match = try regex.firstMatch(in: line) {
                    let (_, commit, date, comment) = match.output
                    return (String(commit), Date(timeIntervalSince1970: TimeInterval(date)!), String(comment))
                } else {
                    return nil
                }
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
    }

}

extension Commit {
    struct CommitID: Hashable {
        let objectID: NSManagedObjectID
        let checked: Bool
    }
    var listID: CommitID {
        .init(objectID: self.objectID, checked: self.checked)
    }
}
