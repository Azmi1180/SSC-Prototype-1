import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject var controller = GameController()
    
    // Setup Scene
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .aspectFill
        // Inject controller agar Logic Router di SpriteKit sinkron
        scene.gameController = controller
        return scene
    }
    
    var body: some View {
        ZStack {
            // MARK: - LAYER 1: GAME WORLD (SpriteKit)
            SpriteView(scene: scene, isPaused: controller.showLogicMenu)
                .ignoresSafeArea()
            
            // MARK: - LAYER 2: ROUTER VISUAL (SwiftUI Overlay)
            // RouterView kita taruh tepat di tengah layar karena RouterNode ada di (0.5, 0.5)
            RouterView(controller: controller)
                .scaleEffect(0.5)
                .allowsHitTesting(true) // Supaya bisa diklik untuk buka menu
                .zIndex(1) // Pastikan di atas SpriteView tapi di bawah Menu
            
            // MARK: - LAYER 3: HUD (Score & Info)
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                        Text("RULES: \(controller.activeRules.count)/3")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.8))
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
                
                // Hint Text (Hanya muncul kalau menu tertutup)
                if !controller.showLogicMenu {
                    Text("// TAP CENTER NODE TO CONFIGURE")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
            }
            .zIndex(2) // HUD selalu di atas Router
            
            // MARK: - LAYER 4: LOGIC MENU (Modal)
            if controller.showLogicMenu {
                // Dimming Background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { controller.showLogicMenu = false }
                    .zIndex(99)
                
                // The Menu
                LogicMenu(controller: controller)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(100)
            }
        }
        .statusBar(hidden: true)
        // Animasi halus saat menu muncul/hilang
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.showLogicMenu)
    }
}
