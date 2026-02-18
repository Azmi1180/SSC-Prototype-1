import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    var scene: SKScene {
        let scene = GameScene()        
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .aspectFill
        scene.gameController = controller // Inject the dependency
        return scene
    }
    
    var body: some View {
        ZStack {
            // Layer 1: The Game World
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            // Layer 2: The Retro HUD
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
                .background(Color.black.opacity(0.5)) // Contrast bar
                
                Spacer()
                
                // Bottom Control Bar placeholder
                Text("// AWAITING INPUT...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
        .statusBar(hidden: true)
    }
}
