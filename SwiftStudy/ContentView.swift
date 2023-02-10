//
//  ContentView.swift
//  SwiftStudy
//
//  Created by oozoofrog on 2023/02/01.
//

import CoreData
import SwiftUI
import AppKit

struct ContentView: View {

    @EnvironmentObject var commitLoader: Commits

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Commit.date, ascending: true)], animation: .default)
    private var commits: FetchedResults<Commit>

    var body: some View {
        VStack {
            StatusView(lastCommitHash: commits.last?.commit)
            if !commits.isEmpty {
                List(commits[0..<commitLoader.visibleEnd], id: \.listID) { commit in
                    CommitView(commit: viewContext.object(with: commit.objectID) as! Commit).onTapGesture {
                        self.commitLoader.checkUntil(commit)
                    }
                }
            } else {
                Spacer()
            }
        }.disabled(commitLoader.state.isUpdating)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct CommitView: View {
    let commit: Commit

    var body: some View {
        HStack {
            if commit.checked {
                Image(systemName: "bookmark.fill")
            } else {
                Image(systemName: "bookmark")
            }
            Text("\(commit.commit!)")
            Text(commit.date!, format: .dateTime)
            Spacer()
            Text(commit.comment ?? "nil")
        }
    }
}
