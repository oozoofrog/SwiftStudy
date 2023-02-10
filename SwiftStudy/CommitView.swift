import SwiftUI

struct CommitView: View {
    let commit: Commit

    let selectedCommit: Commit?

    var body: some View {
        if selectedCommit == commit {
            self.contentView.foregroundColor(.white).background(Color.black)
        } else {
            self.contentView
        }
    }

    var contentView: some View {
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
        }.padding(.init(top: 3, leading: 8, bottom: 3, trailing: 8))
    }
}
