import SwiftUI

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}

struct InfoView: View {
    private var version: String? = nil

    init(hasPermissions: Bool = false) {
        self.version = Bundle.main.buildNumber
    }

    var body: some View {
        Group {
            VStack {
                HStack(alignment: .bottom) {
                    Text("⌘ Swift Shift").font(.headline)
                    if version != nil {
                        Text("v" + version!).font(.subheadline)
                    }
                }.padding(.bottom)

                Text("Made with 🩵 by")

                Button(action: {
                    guard let url = URL(string: "https://pablopunk.com") else {
                        print("Invalid URL")
                        return
                    }
                    NSWorkspace.shared.open(url)
                }, label: {
                    Text("Pablo Varela")
                }).buttonStyle(.link)

                UIButton(action: {
                    guard let url = URL(string: "https://github.com/pablopunk/SwiftShift") else {
                        print("Invalid URL")
                        return
                    }
                    NSWorkspace.shared.open(url)
                }, background: .orange, label: {
                    Image(systemName: "swift")
                    Text("Go to Open Source Project")
                })
                .padding(.top)
            }
        }.padding()

        Divider()

        HStack {
            UIButton(action: {
                NSApplication.shared.terminate(0)
            }, label: {
                HStack {
                    Text("Quit")
                    Text("⌘Q").font(.subheadline).opacity(0.6)
                }
            })
            .keyboardShortcut("Q", modifiers: .command)

            Spacer()

            CheckUpdatesButton(label: "Check for updates")
        }.padding()
    }
}

#Preview {
    InfoView().frame(width: MAIN_WINDOW_WIDTH)
}
