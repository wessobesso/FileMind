//
//  ContentViewModel.swift
//  FileMind
//
//  Created by WessoBesso on 2025-05-01.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var debouncedSearchText: String = ""
    @Published var searchResults: [FileSearchResult] = []

    @Published var excludedDeepSearchFolders: Set<URL> = []
    @Published var allTopLevelFolders: [URL] = []
    @Published var isDeepSearchEnabled: Bool = false
    @Published var selectedDeepSearchFolders: [URL] = []

    @Published var isSearching: Bool = false
    @Published var noResultsFound: Bool = false
    @Published var isInCommandMode: Bool = false
    @Published var isFindCommandActive: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let logic = FileSearchLogic()

    init() {
        loadTopLevelFolders()

        $searchText
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] debouncedValue in
                guard let self = self else { return }

                self.debouncedSearchText = debouncedValue
                self.isInCommandMode = debouncedValue.hasPrefix("/")

                if self.isFindCommandActive || self.isInCommandMode {
                    // Do NOT perform search — wait for Enter
                    print("⌨️ Slash command active — waiting for manual trigger")
                    return
                }

                // Perform normal or DeepSearch
                self.performSearch(with: debouncedValue)
            }
            .store(in: &cancellables)

        logic.$searchResults
            .receive(on: RunLoop.main)
            .sink { [weak self] results in
                self?.searchResults = results
                self?.isSearching = false
                self?.noResultsFound = results.isEmpty
            }
            .store(in: &cancellables)
    }

    private func loadTopLevelFolders() {
        let fm = FileManager.default
        let rootPath = "/"

        do {
            let folderNames = try fm.contentsOfDirectory(atPath: rootPath)
            let folderURLs = folderNames.map { URL(fileURLWithPath: rootPath).appendingPathComponent($0) }

            allTopLevelFolders = folderURLs.filter { url in
                var isDir: ObjCBool = false
                return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
            }

            excludedDeepSearchFolders = []
        } catch {
            print("❌ Failed to load top-level folders: \(error.localizedDescription)")
            allTopLevelFolders = []
            excludedDeepSearchFolders = []
        }
    }

    private func performSearch(with query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            logic.stopAndClearQuery()
            self.searchResults = []
            self.noResultsFound = false
            self.isSearching = false
            return
        }

        self.noResultsFound = false
        self.isSearching = true

        if isDeepSearchEnabled {
            logic.searchFiles(for: trimmed, in: [], excluding: excludedDeepSearchFolders, deepSearch: true)
        } else {
            logic.searchFiles(for: trimmed, in: [], deepSearch: false)
        }
    }

    func triggerSearchManually() {
        performSearch(with: searchText)
    }

    func clearSearchState() {
        logic.stopAndClearQuery()
        self.searchResults = []
        self.noResultsFound = false
        self.isSearching = false
    }

    /// Used to inject AI-powered results (bypasses Spotlight)
    func setSearchResultsFromAI(_ urls: [URL]) {
        DispatchQueue.main.async {
            self.searchResults = urls.map { url in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                return FileSearchResult(url: url, isDirectory: isDir.boolValue)
            }
            self.isSearching = false
            self.noResultsFound = urls.isEmpty
        }
    }
}
