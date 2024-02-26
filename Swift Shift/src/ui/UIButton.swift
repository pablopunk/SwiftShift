import SwiftUI

//struct UIButton: View {
//    var action: () -> Void
//    var iconName: String?

//}

struct UIButton<Label: View>: View {
    @State private var isPressed = false
    @State private var isHovering = false
    let action: () -> Void
    let label: () -> Label
    let background: Color?
    
    init(action: @escaping () -> Void, background: Color? = nil, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
        if let background = background {
            self.background = background.opacity(0.3)
        } else {
            self.background = Color.primary.opacity(0.1)
        }
    }

    var body: some View {
        Button(action: {
            self.isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isPressed = false
                self.action()
            }
        }) {
            HStack(alignment: .center, content: label)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .foregroundColor(.primary)
                .background(background.opacity(isHovering ? 0.7 : 1))
                .cornerRadius(40)
                .scaleEffect(isPressed ? 0.90 : 1.0)
                .shadow(radius: 6)
        }
        .buttonStyle(.borderless)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}


#Preview {
    HStack {
        UIButton(action: {print("Pressed")}) {
            Text("Quit")
            Text("⌘Q").font(.subheadline).opacity(0.6)
        }
        
        UIButton(action: {print("Pressed")}, background: .teal) {
            Image(systemName: "hand.thumbsup")
            Text("Press me")
        }
        
        UIButton(action: {print("Pressed")}, background: .indigo) {
            Image(systemName: "gear")
            Text("Settings")
        }
    }.padding(120)
}
