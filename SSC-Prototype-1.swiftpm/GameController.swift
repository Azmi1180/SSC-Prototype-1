//
//  GameController.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

class GameController: ObservableObject {
    @Published var score: Int = 0
    @Published var showLogicMenu: Bool = false
    
    // The Rules currently active on the selected router
    @Published var activeRules: [LogicRule] = []
    
    // Helper to sync: UI -> Controller -> GameScene -> RouterNode
    var onRulesChanged: (([LogicRule]) -> Void)?
    
    func addRule(color: PacketType, action: RouterAction) {
        if activeRules.count < 3 {
            let newRule = LogicRule(conditionColor: color, action: action)
            activeRules.append(newRule)
            syncRules()
        }
    }
    
    func removeRule(at index: IndexSet) {
        activeRules.remove(atOffsets: index)
        syncRules()
    }
    
    func clearRules() {
        activeRules.removeAll()
        syncRules()
    }
    
    private func syncRules() {
        // Send the updated list to the GameScene
        onRulesChanged?(activeRules)
    }
}
