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
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                
                // HUD
                VStack {
                    HStack {
                        Text("LOGIC: \(controller.selectedRouterLogic.rawValue)")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.yellow)
                            .cornerRadius(4)
                        Spacer()
                        Text("SCORE: \(controller.score)")
                            .font(.monospaced(.title)())
                            .foregroundColor(.white)
                    }
                    .padding()
                    Spacer()
                }
            }
            // The Logic Sheet
            .sheet(isPresented: $controller.showLogicMenu) {
                LogicMenu(controller: controller)
                    .presentationDetents([.medium]) // iOS 16+ half sheet
            }
        }
        .statusBar(hidden: true)
    }
}
