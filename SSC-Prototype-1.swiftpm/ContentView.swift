import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    var scene: SKScene {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        scene.gameController = controller
        return scene
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Game
                // PAUSE LOGIC ADDED HERE:
                SpriteView(scene: scene, isPaused: controller.showLogicMenu)
                    .ignoresSafeArea()
                
                // Layer 2: HUD
                VStack {
                    HStack {
                        HStack {
                            Image(systemName: "cpu")
                            Text("RULES: \(controller.activeRules.count)/3")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black.opacity(0.8)) // Darker for contrast
                        .foregroundColor(.yellow)
                        .cornerRadius(4)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.yellow, lineWidth: 1))
                        
                        Spacer()
                        
                        Text("SCORE: \(controller.score)")
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                    }
                    .padding()
                    
                    Spacer()
                    
                    if !controller.showLogicMenu {
                        Text("// TAP CENTER NODE TO CONFIGURE")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 20)
                    }
                }
            }
            if controller.showLogicMenu {
                LogicMenu(controller: controller)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(100)
            }
        }
        .statusBar(hidden: true)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.showLogicMenu)
    }
}
