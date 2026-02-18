import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
    
    // Store nodes to access them later
    var sourceNode: SKShapeNode?
    var destNode: SKShapeNode?
    
    override func didMove(to view: SKView) {
        backgroundColor = Theme.background
        
        drawGrid()
        setupLevel()
        startSpawning()
    }
    
    // --- Level Setup ---
    func setupLevel() {
        removeAllChildren()
        drawGrid()
        
        let startPos = CGPoint(x: size.width * 0.2, y: size.height * 0.5)
        
        let endPos = CGPoint(x: size.width * 0.8, y: size.height * 0.5)
         
        sourceNode = createNode(at: startPos, name: "Source")
        destNode = createNode(at: endPos, name: "Destination")
                
        connectNodes(from: startPos, to: endPos)
    }
    
    // --- Helper Functions ---
    func createNode(at position: CGPoint, name: String) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 25)
        node.position = position
        node.name = name
        node.fillColor = Theme.background
        node.strokeColor = Theme.nodeCore
        node.lineWidth = 3
        
        // Add Label
        let label = SKLabelNode(text: name)
        label.fontSize = 14
        label.fontName = "Menlo-Bold"
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 35)
        node.addChild(label)
        
        addChild(node)
        return node
    }
    
    func connectNodes(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        
        let track = SKShapeNode(path: path)
        track.strokeColor = Theme.track
        track.lineWidth = 4
        track.zPosition = -1 // Behind nodes
        addChild(track)
    }
    
    // --- Packet Logic ---
    func startSpawning() {
        let wait = SKAction.wait(forDuration: 1.5)
        let spawn = SKAction.run { [weak self] in
            self?.spawnPacket()
        }
        let sequence = SKAction.sequence([wait, spawn])
        run(SKAction.repeatForever(sequence))
    }
    
    func spawnPacket() {
        guard let start = sourceNode, let end = destNode else { return }
        
        // Randomize type to test all colors
        let type: PacketType = [.video, .email, .malware].randomElement()!
        let packet = PacketNode(type: type)
        packet.position = start.position
        addChild(packet)
        
        // Distance formula: √((x2-x1)^2 + (y2-y1)^2)
        let dx = end.position.x - start.position.x
        let dy = end.position.y - start.position.y
        let distance = sqrt(dx*dx + dy*dy)
                
        let duration = TimeInterval(distance / type.speed)
                
        let move = SKAction.move(to: end.position, duration: duration)
        let remove = SKAction.removeFromParent()
        
        packet.run(SKAction.sequence([move, remove]))
                
        gameController?.statusText = "PACKET: \(type)"
    }
        
    func drawGrid() {
        let gridSize: CGFloat = 50
        let rows = Int(size.height / gridSize) + 1
        let cols = Int(size.width / gridSize) + 1
        
        for x in 0...cols {
            let path = CGMutablePath()
            let xPos = CGFloat(x) * gridSize
            path.move(to: CGPoint(x: xPos, y: 0))
            path.addLine(to: CGPoint(x: xPos, y: size.height))
            
            let line = SKShapeNode(path: path)
            line.strokeColor = Theme.gridLine
            line.lineWidth = 1
            line.alpha = 0.3
            addChild(line)
        }
        
        for y in 0...rows {
            let path = CGMutablePath()
            let yPos = CGFloat(y) * gridSize
            path.move(to: CGPoint(x: 0, y: yPos))
            path.addLine(to: CGPoint(x: size.width, y: yPos))
            
            let line = SKShapeNode(path: path)
            line.strokeColor = Theme.gridLine
            line.lineWidth = 1
            line.alpha = 0.3
            addChild(line)
        }
    }
}
