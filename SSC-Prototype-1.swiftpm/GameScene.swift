//
//  GameScene.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SpriteKit

class GameScene: SKScene {
    weak var gameController: GameController?
            
    var gameNodes: [SKShapeNode] = []
    
    override func didMove(to view: SKView) {
        backgroundColor = Theme.background
        drawGrid()
        
        setupLevel()
        startSpawning()
    }
    
    
    func setupLevel() {
        let nodeA = createNode(at: CGPoint(x: 200, y: size.height/2), name: "Source")
                
        let nodeB = createNode(at: CGPoint(x: 800, y: size.height/2), name: "Destination")
                
        connectNodes(from: nodeA, to: nodeB)
    }
    
    
    func createNode(at position: CGPoint, name: String) -> SKShapeNode {
            let node = SKShapeNode(circleOfRadius: 20)
            node.position = position
            node.name = name
            node.fillColor = Theme.background
            node.strokeColor = Theme.nodeCore
            node.lineWidth = 3
            addChild(node)
            gameNodes.append(node)
             
            let label = SKLabelNode(text: name)
            label.fontSize = 14
            label.fontName = "Menlo-Bold"
            label.position = CGPoint(x: 0, y: 30)
            label.fontColor = .white
            node.addChild(label)
            
            return node
        }
    
    func connectNodes(from start: SKNode, to end: SKNode) {
        let path = CGMutablePath()
        path.move(to: start.position)
        path.addLine(to: end.position)
        
        let track = SKShapeNode(path: path)
        track.strokeColor = Theme.track
        track.lineWidth = 4
        track.zPosition = -1
        addChild(track)
    }
    
    func startSpawning() {
        let wait = SKAction.wait(forDuration: 1.5)
        let spawn = SKAction.run { [weak self] in
            self?.spawnPacket()
        }
        let sequence = SKAction.sequence([wait, spawn])
        run(SKAction.repeatForever(sequence))
    }
    
    
    func spawnPacket() {
        guard gameNodes.count >= 2 else { return }
        
        let startNode = gameNodes[0]
        let endNode = gameNodes[1]
                
        let types: [PacketType] = [.video, .email, .malware]
        let randomType = types.randomElement()!
                
        let packet = PacketNode(type: randomType)
        packet.position = startNode.position
        addChild(packet)
                
        // Distance formula: √((x2-x1)^2 + (y2-y1)^2)
        let dx = endNode.position.x - startNode.position.x
        let dy = endNode.position.y - startNode.position.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // Time = Distance / Speed
        let duration = TimeInterval(distance / packet.type.speed)
                
        let moveAction = SKAction.move(to: endNode.position, duration: duration)
        let doneAction = SKAction.removeFromParent() // Delete when finished
        
        // placeholder for a small "Arrival" sound or effect here later
        
        packet.run(SKAction.sequence([moveAction, doneAction]))
        
        // Optional: Update UI stats
        gameController?.statusText = "PACKET SENT: \(randomType)"
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
    
//    func spawnTestNode() {
//        // Create the Node visual
//        let node = SKShapeNode(circleOfRadius: 25)
//        node.fillColor = Theme.background
//        node.strokeColor = Theme.node
//        node.lineWidth = 3
//                
//        let glowShape = SKShapeNode(circleOfRadius: 25)
//        glowShape.fillColor = Theme.node
//        glowShape.strokeColor = .clear
//        glowShape.alpha = 0.4
//        
//        let glowEffect = SKEffectNode()
//        glowEffect.shouldRasterize = true
//        let blur = CIFilter(name: "CIGaussianBlur")
//        blur?.setValue(6.0, forKey: kCIInputRadiusKey)
//        glowEffect.filter = blur
//        glowEffect.zPosition = -1
//        glowEffect.addChild(glowShape)
//        
//        // Center it
//        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        node.name = "test_node"
//        glowEffect.position = node.position
//        
//        // Add a pulsing animation
//        let scaleUp = SKAction.scale(to: 1.1, duration: 1.0)
//        let scaleDown = SKAction.scale(to: 1.0, duration: 1.0)
//        let pulse = SKAction.sequence([scaleUp, scaleDown])
//        node.run(SKAction.repeatForever(pulse))
//        
//        addChild(node)
//        addChild(glowEffect)
//    }
//    
//    // Testing Interactions
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for touch in touches {
//            let location = touch.location(in: self)
//            let touchedNodes = nodes(at: location)
//            
//            for node in touchedNodes {
//                if node.name == "test_node" {
//                    gameController?.statusText = "NODE_ACCESSED"
//                    gameController?.incrementScore()
//                }
//            }
//        }
//    }
}

