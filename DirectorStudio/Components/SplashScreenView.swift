import SwiftUI

// MARK: - Splash Screen with Beautiful Vintage Camera

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Vintage Film Grain Effect
            filmGrainOverlay
            
            VStack(spacing: 0) {
                Spacer()
                
                // Camera Image
                cameraImage
                
                // App Title
                appTitle
                
                // Tagline
                tagline
                
                Spacer()
                
                // Animated Loading Bar
                loadingBar
                
                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Components
    
    private var cameraImage: some View {
        Image("splash_camera") // Use your vintage camera image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 280, height: 280)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 1.2), value: isAnimating)
    }
    
    private var appTitle: some View {
        Text("DirectorStudio")
            .font(.system(size: 48, weight: .bold, design: .serif))
            .foregroundColor(.white)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)
    }
    
    private var tagline: some View {
        Text("Where Stories Become Cinema")
            .font(.system(size: 18, weight: .light, design: .serif))
            .foregroundColor(.gray)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
            .padding(.top, 8)
    }
    
    private var loadingBar: some View {
        VStack(spacing: 12) {
            // Film strip decoration
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 60, height: 2)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            Text("Loading your creative studio...")
                .font(.caption)
                .foregroundColor(.gray)
                .opacity(showContent ? 1.0 : 0.0)
        }
    }
    
    private var filmGrainOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.orange.opacity(0.03),
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
            .opacity(0.5)
    }
    
    // MARK: - Animation Logic
    
    private func startAnimation() {
        isAnimating = true
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            showContent = true
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isPresented = false
            }
        }
    }
}

// MARK: - Alternative: Full Screen Splash with Menu Options

struct MainSplashScreen: View {
    @State private var isAnimating = false
    @State private var showMenus = false
    @Binding var selectedAction: SplashAction?
    
    enum SplashAction {
        case newProject
        case openProject
        case settings
    }
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.0),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Vintage Camera Image
                Image("splash_camera")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320, height: 320)
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // App Title with Film Strip Style
                VStack(spacing: 12) {
                    Text("DirectorStudio")
                        .font(.system(size: 52, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 40, height: 2)
                        
                        Text("AI-POWERED CINEMATIC STORYTELLING")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange)
                            .tracking(2)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 40, height: 2)
                    }
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 30)
                
                Spacer()
                
                // Menu Options
                if showMenus {
                    VStack(spacing: 16) {
                        MenuButton(
                            title: "Create New Project",
                            icon: "plus.circle.fill",
                            gradient: [.purple, .pink]
                        ) {
                            selectedAction = .newProject
                        }
                        
                        MenuButton(
                            title: "Open Project",
                            icon: "folder.fill",
                            gradient: [.blue, .cyan]
                        ) {
                            selectedAction = .openProject
                        }
                        
                        MenuButton(
                            title: "Settings",
                            icon: "gearshape.fill",
                            gradient: [.gray, .gray.opacity(0.6)],
                            secondary: true
                        ) {
                            selectedAction = .settings
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 60)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                showMenus = true
            }
        }
    }
}

// MARK: - Menu Button Component

struct MenuButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    var secondary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.6)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: secondary ? 300 : .infinity)
            .background(
                Group {
                    if secondary {
                        Color.white.opacity(0.1)
                    } else {
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(16)
            .shadow(color: secondary ? .clear : gradient.first!.opacity(0.3), radius: 10, y: 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
    }
}

// MARK: - Preview

#Preview("Simple Splash") {
    SplashScreenView(isPresented: .constant(true))
}

#Preview("Main Splash with Menus") {
    MainSplashScreen(selectedAction: .constant(nil))
}
