//
//  Theme.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI
import SpriteKit

struct Theme {
    // Background: Deep Void
    static let background = SKColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1.0)
    
    // Grid Lines: Dark Grey/Blue
    static let gridLine = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
    
    // Node: Silver/White
    static let node = SKColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
    
    // UI Accent: Amber
    static let accent = Color(red: 1.0, green: 0.8, blue: 0.0)
        
    // UI Elements
    static let nodeCore = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    static let track = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
    
    // Packet Colors (The "Neon" Palette)
    static let packetVideo = SKColor(red: 1.0, green: 0.0, blue: 0.33, alpha: 1.0) // Neon Red
    static let packetEmail = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0) // Neon Cyan
    static let packetMalware = SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0) // Matrix Green
}
