//
//  Untitled.swift
//  FileMind
//
//  Created by WessoBesso on 2025-07-19.
//


import SwiftUI

// 🔍 Reusable HelpButton with popover
struct HelpButton<Content: View>: View {
    @State private var showPopover = false
    let content: () -> Content

    var body: some View {
        Button(action: { showPopover.toggle() }) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.blue)
                .help("More info")
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showPopover, arrowEdge: .top) {
            content()
                .padding()
                .frame(width: 300)
        }
    }
}

        
struct HoverTooltip: View {
    let symbol: String
    let tooltip: String

    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Main icon (hover detection here)
            Image(systemName: symbol)
                .foregroundColor(.gray)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())

            // Tooltip — drawn separately so it doesn't interfere with hover
            if isHovered {
                VStack {
                    Text(tooltip)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(6)
                        .frame(width: 200)
                        .background(Color(nsColor: NSColor.windowBackgroundColor))
                        .cornerRadius(6)
                }
                .fixedSize()
                .offset(x: 105, y: -65)
                .allowsHitTesting(false) // 👈 prevents tooltip from affecting hover
                .zIndex(1)
            }
        }
        .frame(width: 24, height: 24)
    }
}

struct BackspaceCatcherTextField: NSViewRepresentable {
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: BackspaceCatcherTextField

        init(_ parent: BackspaceCatcherTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.deleteBackward) {
                if parent.text.isEmpty {
                    parent.onBackspaceWhenEmpty()
                    return true
                }
                return false
            }
            return false
        }

        @objc func textFieldDidBecomeFirstResponder(_ sender: Any?) {
            // No longer needed
        }
    }

    @Binding var text: String
    var onBackspaceWhenEmpty: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(string: "")
        textField.stringValue = ""
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.textFieldDidBecomeFirstResponder(_:))
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.focusRingType = .none
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}






struct BackspaceCatcherTextEditor: NSViewRepresentable {
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: BackspaceCatcherTextEditor

        init(_ parent: BackspaceCatcherTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.deleteBackward),
               parent.text.isEmpty {
                parent.onBackspaceWhenEmpty()
                return true
            }
            return false
        }
    }

    @Binding var text: String
    var onBackspaceWhenEmpty: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 14)
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 2, height: 8)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as? NSTextView
        if textView?.string != text {
            textView?.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


