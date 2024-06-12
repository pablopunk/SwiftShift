import SwiftUI

struct UIButton<Label: View>: View {
    @State private var isPressed = false
    @State private var isHovering = false
    let action: () -> Void
    let label: () -> Label
    let background: Color?
    let backgroundHover: Color?
    let plain: Bool
    
    init(action: @escaping () -> Void, plain: Bool = false, background: Color? = nil, @ViewBuilder label: @escaping () -> Label, backgroundHover: Color? = nil) {
        self.action = action
        self.label = label
        self.plain = plain
        if let background = background {
            self.background = plain ? background : background.opacity(0.3)
        } else {
            self.background = Color.primary.opacity(0.1)
        }
        if let bgHover = backgroundHover {
            self.backgroundHover = bgHover
        } else {
            self.backgroundHover = self.background
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
                .foregroundColor(plain ? background : .primary)
                .background(getBackground())
                .cornerRadius(40)
                .scaleEffect(isPressed ? 0.90 : isHovering ? 1.1 : 1)
                .shadow(radius: 6)
        }
        .buttonStyle(.borderless)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) { isHovering = hovering }
        }
    }
    
    
    private func getBackground() -> Color? {
        if plain && !isHovering {
            return nil
        }
        if isHovering && self.backgroundHover != nil {
            return self.backgroundHover
        }
        if isHovering {
            return self.background?.opacity(0.7)
        }
        return self.background
    }
}


#Preview {
    VStack {
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
        
        UIButton(action: {print("Pressed")}, plain: true, label: {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.teal)
        }, backgroundHover: .teal.opacity(0.2))
        
        UIButton(action: {print("Pressed")}, plain: true, background: .cyan, label: {
            Text("Plain")
        }, backgroundHover: .teal.opacity(0.2))
    }.padding(120)
}
