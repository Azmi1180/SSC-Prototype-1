import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: The Game World
                // We create the scene dynamically based on the geometry size
                SpriteView(scene: makeScene(size: geometry.size))
                    .ignoresSafeArea()
                
                // Layer 2: The HUD (stays the same)
                VStack {
                    HStack {
                        Text("PACKET STATION")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("SCORE: \(controller.score)")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.accent)
                            
                            Text(controller.statusText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.5))
                    
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true)
    }
    
    // Helper to create the scene with the correct size
    func makeScene(size: CGSize) -> SKScene {
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill // crucial for responsiveness
        scene.gameController = controller
        return scene
    }
}
