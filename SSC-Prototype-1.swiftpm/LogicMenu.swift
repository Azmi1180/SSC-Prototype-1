//
//  LogicMenu.swift
//  SSC-Prototype
//
//  Created by Muhammad Azmi on 18/02/26.
//

import SwiftUI

struct LogicMenu: View {
    @ObservedObject var controller: GameController

    @State private var selectedColor: PacketType = .video
    @State private var selectedAction: RouterAction = .drop
    
    // MARK: - Helpers
    private var isMemoryFull: Bool { controller.activeRules.count >= 3 }
    private var memoryUsage: Double { Double(controller.activeRules.count) / 3.0 }
    
    private var availableActions: [RouterAction] {
        var actions: [RouterAction] = [.drop]
            
        for server in controller.currentLevel.servers {
            actions.append(.forward(to: server.id, name: server.name))
        }
            
        for router in controller.currentLevel.routers where router.id != controller.selectedRouterID {
            actions.append(.forward(to: router.id, name: router.name))
        }
        
        return actions
    }

    var body: some View {
        ZStack {
            // Scrim — tap to close
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { controller.showLogicMenu = false }

            // Adaptive card
            GeometryReader { geo in
                let isWide = geo.size.width > 700
                let cardWidth: CGFloat = isWide ? min(geo.size.width - 80, 760) : min(geo.size.width - 48, 420)

                Group {
                    if isWide {
                        HStack(spacing: 0) {
                            memoryPanel
                                .frame(maxWidth: 340)
                            Divider()
                                .background(Color.white.opacity(0.12))
                            compilerPanel
                        }
                    } else {
                        VStack(spacing: 0) {
                            memoryPanel
                            Divider()
                                .background(Color.white.opacity(0.12))
                            compilerPanel
                        }
                    }
                }
                .frame(width: cardWidth, alignment: .top)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.7), radius: 50, x: 0, y: 24)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .environment(\.colorScheme, .dark)
        }
    }

    // MARK: - Memory Panel
    private var memoryPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("ROUTER_CONFIG")
                        .font(.system(.subheadline, design: .monospaced, weight: .black))
                        .foregroundColor(.white)
                    Text("LOGIC MEMORY BANK")
                        // FIXED: Weight must be before Design
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Button(action: { controller.showLogicMenu = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(white: 0.13))

            // Memory usage bar
            memoryUsageBar

            // Rules list
            rulesListContent
        }
    }

    // MARK: - Memory Usage Bar
    private var memoryUsageBar: some View {
        HStack(spacing: 10) {
            Text("MEM")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                    if isMemoryFull {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * memoryUsage)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent.opacity(0.8), Theme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * memoryUsage)
                    }
                }
            }
            .frame(height: 4)
            .animation(.spring(response: 0.4), value: memoryUsage)

            Text("\(controller.activeRules.count)/3")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(isMemoryFull ? .red : .white.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(white: 0.11))
    }

    // MARK: - Rules List
    private var rulesListContent: some View {
        Group {
            if controller.activeRules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.15))
                    VStack(spacing: 4) {
                        Text("> MEMORY EMPTY")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        Text("> PACKETS ROUTING RANDOMLY")
                            .font(.system(.caption2, design: .monospaced, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                List {
                    // FIX: We convert enumerated to Array to avoid complexity errors
                    // FIX: We inline the view to avoid the "RoutingRule not found" error
                    ForEach(Array(controller.activeRules.enumerated()), id: \.element.id) { index, rule in
                        
                        // --- ROW VIEW START ---
                        HStack(spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white.opacity(0.25))
                                .frame(width: 20)

                            Text("IF")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(rule.conditionColor.uiColor)
                                    .frame(width: 7, height: 7)
                                Text(rule.conditionColor.name)
                                    .font(.system(.caption, design: .monospaced, weight: .black))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(rule.conditionColor.uiColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(rule.conditionColor.uiColor.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundColor(rule.conditionColor.uiColor)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.25))

                            Text(rule.action.displayString)
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            Spacer()

                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                        )
                        // --- ROW VIEW END ---
                        
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                    .onDelete(perform: controller.removeRule)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(minHeight: 400, maxHeight: 600) // Ini buat ubah tinggi
        .background(Color(white: 0.09))
    }

    // MARK: - Compiler Panel
    private var compilerPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus.diamond.fill")
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 13))
                Text("NEW INSTRUCTION")
                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            VStack(spacing: 12) {
                // IF picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.accent.opacity(0.7))
                        Text("IF PACKET IS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Picker("", selection: $selectedColor) {
                        Text("RED").tag(PacketType.video)
                        Text("BLUE").tag(PacketType.email)
                        Text("GREEN").tag(PacketType.malware)
                    }
                    .pickerStyle(.segmented)
                }

                // THEN picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.accent.opacity(0.7))
                        Text("THEN DO")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Picker("", selection: $selectedAction) {
                        ForEach(availableActions, id: \.self) { action in
                            Text(action.displayString).tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            // Live preview
            HStack(spacing: 10) {
                Text("PREVIEW:")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))

                HStack(spacing: 5) {
                    Circle()
                        .fill(selectedColor.uiColor)
                        .frame(width: 7, height: 7)
                    Text(selectedColor.name)
                        .font(.system(.caption, design: .monospaced, weight: .black))
                        .foregroundColor(selectedColor.uiColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedColor.uiColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))

                Text(selectedAction.displayString)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.15), value: selectedColor)
            .animation(.easeInOut(duration: 0.15), value: selectedAction)

            // Compile button
            compileButton
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color(white: 0.13))
    }

    // MARK: - Compile Button
    private var compileButton: some View {
        VStack(spacing: 6) {
            Button(action: {
                guard !isMemoryFull else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                controller.addRule(color: selectedColor, action: selectedAction)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isMemoryFull ? "lock.fill" : "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(isMemoryFull ? "MEMORY BANK FULL" : "COMPILE INSTRUCTION")
                        .font(.system(.subheadline, design: .monospaced, weight: .black))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isMemoryFull {
                            Color.white.opacity(0.06)
                        } else {
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .foregroundColor(isMemoryFull ? .white.opacity(0.3) : .black)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(
                    color: isMemoryFull ? .clear : Theme.accent.opacity(0.45),
                    radius: 12, x: 0, y: 6
                )
            }
            .disabled(isMemoryFull)
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isMemoryFull)

            Text(isMemoryFull ? "[ ERROR 0x03: MEMORY BANK FULL — DELETE A RULE ]" : " ")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: isMemoryFull)
        }
    }
}
