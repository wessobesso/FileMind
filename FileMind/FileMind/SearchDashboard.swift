//
//  SearchDashboard.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-24.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

struct SearchDashboard: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ContentViewModel()
    @State private var isDraggingOver = false
    @State private var isDeepSearchEnabled = false
    @State private var showingDeepSearchSettings = false
    @State private var showCommandSuggestions = false
    @State private var commandSuggestions = ["/find"]
    @State private var selectedCommand: String? = nil
    @FocusState private var isTextFieldFocused: Bool
    @State private var isFindModeActive = false
    @State private var lastSearchText: String = ""
    @State private var aiSearchResults: [FileSearchResult] = []

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                if viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isFindCommandActive {
                    welcomeView
                }
                mainContentView
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: isDraggingOver ? 2 : 0)
            .opacity(isDraggingOver ? 0.5 : 1)

            if isDraggingOver {
                dragOverlay
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            handleDrop(providers: providers)
            return true
        }
        .sheet(isPresented: $showingDeepSearchSettings) {
            FolderPickerView(
                folders: viewModel.allTopLevelFolders,
                excludedFolders: Binding(
                    get: { viewModel.excludedDeepSearchFolders },
                    set: { viewModel.excludedDeepSearchFolders = $0 }
                )
            )
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Text("Welcome to FileMind!")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            commandHelpBox
                .frame(maxWidth: 400)
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 16) {
            if !viewModel.uploadedFiles.isEmpty { uploadedFilesView }

            if !viewModel.isFindCommandActive {
                deepSearchToggle
            } else {
                Text("Press Enter to search")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            searchBar

            if !viewModel.isFindCommandActive {
                loadingOrNoResultsView
            }

            if viewModel.isFindCommandActive {
                searchResultsView(for: aiSearchResults)
            } else if !viewModel.searchResults.isEmpty {
                searchResultsView(for: viewModel.searchResults)
            }
        }
        .padding(.horizontal)
    }

    private var uploadedFilesView: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.uploadedFiles, id: \.self) { file in
                uploadedFileRow(file: file)
            }
        }
    }

    private func uploadedFileRow(file: URL) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pink)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "doc.text.fill").foregroundColor(.white).font(.title2))
                VStack(alignment: .leading) {
                    Text(file.lastPathComponent).font(.headline)
                    Text(file.pathExtension.uppercased()).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.4)))
            .frame(maxWidth: 500)

            Button(action: {
                if let index = viewModel.uploadedFiles.firstIndex(of: file) {
                    let removedFile = viewModel.uploadedFiles.remove(at: index)
                    revokeAccess(to: removedFile)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .background(Color.white.opacity(0.01))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .offset(x: 8, y: -8)
        }
    }

    private var deepSearchToggle: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button(action: {
                    isDeepSearchEnabled.toggle()
                    viewModel.isDeepSearchEnabled = isDeepSearchEnabled

                    if isDeepSearchEnabled {
                        viewModel.selectedDeepSearchFolders = []
                        print("DeepSearch enabled — will search entire disk")
                    } else {
                        viewModel.selectedDeepSearchFolders = []
                        viewModel.excludedDeepSearchFolders = []
                        viewModel.clearSearchState()
                        print("DeepSearch disabled — back to prioritized folders")
                    }

                    viewModel.triggerSearchManually()

                }) {
                    HStack {
                        Image(systemName: isDeepSearchEnabled ? "checkmark.square.fill" : "square")
                        Text("DeepSearch")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isDeepSearchEnabled ? Color.orange.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showingDeepSearchSettings = true }) {
                    Image(systemName: "gearshape").foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if isDeepSearchEnabled {
                HStack(spacing: 6) {
                    Text("⚠️ Note that DeepSearch can be very RAM consuming ⚠️")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(10)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)

                    HoverTooltip(
                        symbol: "questionmark.circle",
                        tooltip: """
                        The DeepSearch function searches through your FULL DISK, and may potentially crash the app.
                        We advise to use the settings to minimize the search pool by deselecting folders.
                        """
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .transition(.opacity)
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                if isFindModeActive {
                    HStack(spacing: 4) {
                        Text("/find prompt")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)

                        Text("[")
                            .foregroundColor(.gray)

                        BackspaceCatcherTextField(text: $viewModel.searchText) {
                            if lastSearchText.isEmpty {
                                selectedCommand = nil
                                isFindModeActive = false
                                viewModel.isFindCommandActive = false
                            }
                        }
                        .focused($isTextFieldFocused)
                        .onChange(of: viewModel.searchText) { _, newText in
                            showCommandSuggestions = false
                            viewModel.isFindCommandActive = true
                            lastSearchText = newText
                        }
                        .focused($isTextFieldFocused)
                        .onChange(of: viewModel.searchText) { _, text in
                            showCommandSuggestions = false
                            viewModel.isFindCommandActive = true

                            if text.isEmpty && isFindModeActive && selectedCommand == nil {
                                // User typed nothing after slash manually — exit command mode
                                isFindModeActive = false
                                viewModel.isFindCommandActive = false
                            }
                        }
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .frame(minWidth: 10)

                        Text("]")
                            .foregroundColor(.gray)
                    }
                } else {
                    TextField("Search, ask, or drop a file...", text: $viewModel.searchText)
                        .focused($isTextFieldFocused)
                        .onChange(of: viewModel.searchText) {
                            // Show suggestions if user types /
                            if viewModel.searchText.hasPrefix("/") {
                                showCommandSuggestions = commandSuggestions.contains { $0.hasPrefix(viewModel.searchText) }
                            } else {
                                showCommandSuggestions = false
                                selectedCommand = nil
                                viewModel.isFindCommandActive = false
                            }

                            if viewModel.searchText.isEmpty {
                                isFindModeActive = false
                                viewModel.isFindCommandActive = false
                            }

                            // Autocomplete ONLY when user presses space after typing the full command
                            if viewModel.searchText.hasSuffix(" ") {
                                let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespaces)
                                if trimmed == "/find" {
                                    selectedCommand = "/find"
                                    isFindModeActive = true
                                    viewModel.isFindCommandActive = true
                                    showCommandSuggestions = false
                                    viewModel.searchText = "" // Clear to prompt input
                                    isTextFieldFocused = true
                                }
                            }
                        }
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .frame(minWidth: 10)
                }

                Spacer()

                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.begin { response in
                        if response == .OK, let url = panel.url {
                            viewModel.uploadedFiles.append(url)
                            print("Picked file:", url.path)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(nsColor: NSColor.quaternaryLabelColor).opacity(1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .frame(maxWidth: 500)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(nsColor: NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color(nsColor: NSColor.separatorColor), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

            if showCommandSuggestions {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(commandSuggestions.filter { $0.hasPrefix(viewModel.searchText) || viewModel.searchText == "/" }, id: \.self) { command in
                        Button(action: {
                            selectedCommand = command
                            isFindModeActive = true
                            viewModel.isFindCommandActive = true
                            showCommandSuggestions = false

                            // 💡 Reset searchText so previous "/f" doesn't get reused
                            viewModel.searchText = ""

                            // Refocus input
                            isTextFieldFocused = true
                        }) {
                            HStack {
                                Text(command).bold()
                                Text("prompt[]")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
                .frame(maxWidth: 500)
            }
        }
    }

    private var loadingOrNoResultsView: some View {
        Group {
            if viewModel.isSearching {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            } else if viewModel.noResultsFound {
                Text("No results found")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
            }
        }
        .frame(maxWidth: 500)
    }

    private func searchResultsView(for results: [FileSearchResult]) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(results, id: \.url) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.url.lastPathComponent).font(.headline)
                        Text(result.url.path).font(.caption).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: NSColor.windowBackgroundColor)))
                    .onTapGesture {
                        NSWorkspace.shared.activateFileViewerSelecting([result.url])
                    }
                }
            }
            .padding(.vertical)
            .frame(maxWidth: 500)
        }
        .transition(.opacity)
    }

    private var dragOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
                Text("Drop files to upload").font(.headline).foregroundColor(.white)
            }
            .transition(.opacity)
        }
    }

    var commandHelpBox: some View {
        VStack(alignment: .center, spacing: 5) {
            commandLine("/search", "search for the specific file")
            commandLine("/find", "use ai to find a file")
            commandLine("/ask", "ask ai about a specific file")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: NSColor.windowBackgroundColor))
        )
        .frame(maxWidth: 248)
    }

    func commandLine(_ command: String, _ description: String) -> some View {
        HStack {
            Text(command).bold()
            Text(description).italic().foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil) as URL? {
                    DispatchQueue.main.async {
                        if !viewModel.uploadedFiles.contains(url) {
                            viewModel.uploadedFiles.append(url)
                            print("File dropped: \(url.lastPathComponent)")
                        }
                    }
                }
            }
        }
    }

    private func handleFile(url: URL) {
        if !viewModel.uploadedFiles.contains(url) {
            viewModel.uploadedFiles.append(url)
        }
    }

    func revokeAccess(to file: URL) {
        print("Access revoked for file: \(file.path)")
    }
}

