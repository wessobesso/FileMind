////
////  FindFunctionLogic.swift
////  FileMind
////
////  Created by WessoBesso on 2025-07-19.
////
//
//
//import SwiftUI
//import Combine
//
//// This struct is a placeholder. You'll need to define FileSearchResult in your project.
//
//
//struct FindFunctionUI: View {
//    @EnvironmentObject var appState: AppState
//    @ObservedObject var viewModel: ContentViewModel
//    @FocusState var isTextFieldFocused: Bool
//    @Binding var lastSearchText: String
//    @Binding var aiSearchResults: [URL]
//    @Binding var selectedCommand: String?
//    @Binding var isFindModeActive: Bool
//    @Binding var showCommandSuggestions: Bool
//    var commandSuggestions: [String]
//
//    var body: some View {
//        HStack(spacing: 4) {
//            Text("/find prompt")
//                .font(.system(size: 14, weight: .medium, design: .monospaced))
//                .foregroundColor(.white)
//
//            Text("[")
//                .foregroundColor(.gray)
//
//            BackspaceCatcherTextField(text: $viewModel.searchText) {
//                if lastSearchText.isEmpty {
//                    selectedCommand = nil
//                    isFindModeActive = false
//                    viewModel.isFindCommandActive = false
//                }
//            }
//            .focused($isTextFieldFocused)
//            .onChange(of: viewModel.searchText) { _, newText in
//                showCommandSuggestions = false
//                viewModel.isFindCommandActive = true
//                lastSearchText = newText
//            }
//            .focused($isTextFieldFocused)
//            .onChange(of: viewModel.searchText) { _, text in
//                showCommandSuggestions = false
//                viewModel.isFindCommandActive = true
//
//                if text.isEmpty && isFindModeActive && selectedCommand == nil {
//                    isFindModeActive = false
//                    viewModel.isFindCommandActive = false
//                }
//            }
//            .textFieldStyle(PlainTextFieldStyle())
//            .foregroundColor(.white)
//            .frame(minWidth: 10)
//
//            Text("]")
//                .foregroundColor(.gray)
//        }
//    }
//}
//
//extension ContentViewModel {
//    func handleFindCommandAutocomplete(trimmedText: String) {
//        if trimmedText == "/find" {
//            // No longer directly setting isFindCommandActive here
//            // This logic should be handled by the ContentViewModel itself
//            self.searchText = "" // Clear to prompt input
//        }
//    }
//
//    func handleFindCommandSuggestionSelection(command: String) {
//        if command == "/find" {
//            // No longer directly setting isFindCommandActive here
//            // This logic should be handled by the ContentViewModel itself
//            self.searchText = "" // Clear to prompt input
//        }
//    }
//}
