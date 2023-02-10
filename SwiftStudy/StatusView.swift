import SwiftUI

struct StatusView: View {

    @EnvironmentObject var commitLoader: Commits

    @Environment(\.managedObjectContext) private var viewContext

    let lastCommitHash: String?

    var body: some View {
        HStack {
            switch commitLoader.state {
            case .gathering(let count):
                Text("로딩 중... \(count)")
            case .saving(let count):
                Text("저장 중... \(count)")
            case .deleting:
                Text("삭제 중...")
            case .idle, .finish:
                if lastCommitHash == nil {
                    Button {
                        commitLoader.load()
                    } label: {
                        Text("커밋 로딩")
                    }
                } else {
                    Button {
                        commitLoader.deleteAll()
                    } label: {
                        Text("DeleteAll")
                    }

                    Button {
                        withAnimation {
                            commitLoader.visibleOffset += commitLoader.visibleLimit
                        }
                    } label: {
                        Text("Next")
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}
