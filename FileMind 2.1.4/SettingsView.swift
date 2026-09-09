//
//  SettingsView.swift
//  FileMind
//
//  Created by WessoBesso on 2025-06-28.
//

import SwiftUI
import Foundation
import AppKit

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastColor: Color = .green

    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastColor = .green
        showToast = true
    }
    @AppStorage("lastRunDate") private var lastRunDateStorage: Double = 0 {
        didSet { lastRunDate = Date(timeIntervalSince1970: lastRunDateStorage) }
    }
    @Published var lastRunDate: Date? {
        didSet {
            if let date = lastRunDate {
                lastRunDateStorage = date.timeIntervalSince1970
            }
        }
    }
    func showErrorToast(_ message: String) {
        toastMessage = message
        toastColor = .red
        showToast = true
    }
}


struct SettingsView: View {
    @State private var advancedExpanded = false
    @State private var selectedItems: [URL] = []
    @AppStorage("selectedItemPaths") private var storedPathsData: Data = Data()

    @State private var selectedFileCount: Int = 0
    @State private var totalSelectedSize: Int64 = 0
    @State private var showDuplicateWarning = false
    @State private var showInvalidLocationWarning = false
    @State private var showNetworkVolumeError = false
    @State private var showPermissionHelpModal = false
    @State var showConfirmation = false
    @State private var summarizationJobSubmitted = false
    
    @ObservedObject private var appState = AppState.shared
    
    private let validExtensions: Set<String> = [".jpg", ".jpeg", ".png", ".gif", ".txt", ".pdf", ".docx", ".doc", ".heic"]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("General")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Toggle(isOn: .constant(true)) {
                                Text("Auto-start at login")
                            }
                            .toggleStyle(.checkbox)

                            Button(action: {
                                NSApplication.shared.terminate(nil)
                            }) {
                                Text("Quit FileMind")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 20)
                        }

                        Text("If selected, FileMind will still launch at login after using the \"Quit FileMind\" button.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .frame(width: 280)
                            .padding(.leading, 23)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Permissions:")
                                .font(.system(size: 13, weight: .semibold))

                            Button(action: {
                                showPermissionHelpModal = true
                            }) {
                                Text("Request Permissions...")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 8)
                        }

                        Text("FileMind requires certain permissions to enable it to automate your Mac. This button will help you enable these permissions.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 16)
                            .padding(.top, 2)
                            .frame(width: 280)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Summarization:")
                                .font(.system(size: 13, weight: .semibold))

                            Button(action: {
                                openFilePanel()
                            }) {
                                Text("Choose Files for Selection...")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 8)
                        }
                        if !lastRunText.isEmpty {
                            Text(lastRunText)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.leading, 12)
                        }

                        Text("Select files and folders ONLY from your Mac's Documents, Downloads, or Desktop to send for summarization and analysis.")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 24)
                            .padding(.top, 2)
                            .frame(width: 280)

                        if selectedFileCount > 0 {
                            VStack(alignment: .center, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.accentColor)
                                    Text("\(selectedFileCount) file(s), \(formatSize(totalSelectedSize)) selected")
                                        .font(.callout)
                                        .foregroundColor(.accentColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)

                                HStack(spacing: 8) {
                                    if selectedFileCount <= 7000 {
                                        Button(action: {
                                            openFilePanel()
                                        }) {
                                            Text("Add More Files/Folders")
                                                .font(.system(size: 12, weight: .semibold))
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }

                                    Button(action: {
                                        selectedItems.removeAll()
                                        selectedFileCount = 0
                                        totalSelectedSize = 0
                                        storeSelectedItems()
                                    }) {
                                        Text("Clear Selection")
                                            .font(.system(size: 12, weight: .semibold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, selectedFileCount > 7000 ? 64 : 12)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }

                                Button(action: {
                                    showConfirmation = true
                                }) {
                                    Text("Confirm Files for Selection")
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 32)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle()) // 👈 ensure consistent styling
                                .alert(isPresented: $showConfirmation) {
                                    Alert(
                                        title: Text("Are you sure?"),
                                        message: Text("Are you sure you want to send the selected files (\(selectedFileCount) files and \(formatSize(totalSelectedSize))) for summarization?"),
                                        primaryButton: .default(Text("Yes"), action: {
                                            showConfirmation = false
                                            DispatchQueue.global(qos: .background).async {
                                                let uploader = FileMindUploader(fileList: selectedItems)
                                                uploader.uploadAndRun { success in
                                                    DispatchQueue.main.async {
                                                        if success {
                                                            summarizationJobSubmitted = true
                                                            appState.showSuccessToast("Summarization complete!")
                                                        } else {
                                                            appState.showErrorToast("Summarization failed")
                                                        }
                                                    }
                                                }
                                            }
                                        }),
                                        secondaryButton: .cancel()
                                    )
                                }

//                                if summarizationJobSubmitted {
//                                    Text("Summarization package submitted")
//                                        .font(.footnote)
//                                        .foregroundColor(.green)
//                                        .padding(6)
//                                        .background(Color.green.opacity(0.1))
//                                        .cornerRadius(6)
//                                        .padding(.top, 4)
//                                }
                                if selectedFileCount > 3000 {
                                    HStack(spacing: 6) {
                                        Text(selectedFileCount > 7000 ?
                                             "❌ Too many files selected — FileMind only supports up to 7,000 files." :
                                             "⚠️ Be cautious when selecting folders ⚠️")
                                            .font(.headline)
                                            .foregroundColor(selectedFileCount > 7000 ? .red : .orange)
                                            .padding(10)
                                            .background((selectedFileCount > 7000 ? Color.red : Color.orange).opacity(0.15))
                                            .cornerRadius(8)

                                        HoverTooltip(
                                            symbol: "questionmark.circle",
                                            tooltip: selectedFileCount > 7000
                                                ? "Please reduce your selection to fewer than 7,000 files to proceed."
                                                : "Selecting large folders with many subfolders/files can defeat the purpose of filtering. We recommend only picking folders with important content."
                                        )
                                        .font(.system(size: 16))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 6)
                                    .padding(.leading, 30)
                                }
                            }
                            .padding(.top, 4)
                            .padding(.leading, 16)
                            .transition(.opacity)
                        }
                    }
                    Divider()

                    HStack {
                        Text("Advanced")
                            .font(.headline)
                        Spacer()
                        Image(systemName: advancedExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            advancedExpanded.toggle()
                        }
                    }

                    if advancedExpanded {
                        HStack(spacing: 16) {
                            Toggle(isOn: .constant(false)) {
                                Text("Verbose logs")
                            }
                            .toggleStyle(.checkbox)

                            Toggle(isOn: .constant(false)) {
                                Text("Developer mode")
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }
                .frame(maxWidth: 400)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()

            if showDuplicateWarning {
                Text("Duplicate file(s)/folder(s) were skipped.")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            if showInvalidLocationWarning {
                Text("Files must be from Documents, Downloads, or Desktop to be processed.")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
            

            
            if appState.showToast {
                HStack(spacing: 8) {
                    Text(appState.toastMessage)
                        .foregroundColor(.white)
                        .font(.footnote)

                    Button(action: {
                        appState.showToast = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .opacity(0.8)
                            .font(.system(size: 14, weight: .heavy)) // Thicker look
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(appState.toastColor)
                .cornerRadius(8)
                .shadow(radius: 5)
                .padding(.bottom, 12) // Push above screen edge
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: appState.showToast)
            }
        }
        .onAppear {
            restoreSelectedItems()
            updateCounts()
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Text("FileMind Version: 2.1.4")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
        )
        .sheet(isPresented: $showPermissionHelpModal) {
            NetworkPermissionHelpView {
                showPermissionHelpModal = false
            }
        }
    }


    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.begin { response in
            if response == .OK {
                let allowedDirectories = [
                    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first,
                    FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
                ].compactMap { $0 }

                let isAllowed: (URL) -> Bool = { url in
                    allowedDirectories.contains(where: { url.path.hasPrefix($0.path) })
                }

                var isDirectory: ObjCBool = false
                var newItems: [URL] = []
                var invalidLocationFound = false
                var duplicateFound = false

                let resolvedSelectedPaths = selectedItems.map { $0.resolvingSymlinksInPath().path }

                func isDuplicate(_ newPath: String) -> Bool {
                    for existing in resolvedSelectedPaths {
                        if newPath == existing || newPath.hasPrefix(existing + "/") || existing.hasPrefix(newPath + "/") {
                            return true
                        }
                    }
                    return false
                }

                for url in panel.urls {
                    guard isAllowed(url) else {
                        invalidLocationFound = true
                        continue
                    }

                    let resolvedPath = url.resolvingSymlinksInPath().path
                    FileManager.default.fileExists(atPath: resolvedPath, isDirectory: &isDirectory)

                    if isDirectory.boolValue {
                        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                            for case let fileURL as URL in enumerator {
                                var isDir: ObjCBool = false
                                if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue,
                                   validExtensions.contains("." + fileURL.pathExtension.lowercased()) {
                                    let path = fileURL.resolvingSymlinksInPath().path
                                    if !isDuplicate(path) {
                                        newItems.append(fileURL)
                                    } else {
                                        duplicateFound = true
                                    }
                                }
                            }
                        }
                    } else if validExtensions.contains("." + url.pathExtension.lowercased()) {
                        if !isDuplicate(resolvedPath) {
                            newItems.append(url)
                        } else {
                            duplicateFound = true
                        }
                    }
                }

                if invalidLocationFound {
                    withAnimation {
                        showInvalidLocationWarning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation {
                            showInvalidLocationWarning = false
                        }
                    }
                }

                if duplicateFound {
                    withAnimation {
                        showDuplicateWarning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showDuplicateWarning = false
                        }
                    }
                }

                selectedItems.append(contentsOf: newItems)
                storeSelectedItems()
                updateCounts()
            }
        }
    }

    private func updateCounts() {
         selectedFileCount = 0
         totalSelectedSize = 0

         for url in selectedItems {
             var isDirectory: ObjCBool = false
             if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
                 if validExtensions.contains("." + url.pathExtension.lowercased()) {
                     selectedFileCount += 1
                     if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                         totalSelectedSize += Int64(size)
                     }
                 }
             }
         }
     }

     private func formatSize(_ size: Int64) -> String {
         let formatter = ByteCountFormatter()
         formatter.countStyle = .file
         return formatter.string(fromByteCount: size)
     }

     private func storeSelectedItems() {
         let paths = selectedItems.map { $0.path }
         if let data = try? JSONEncoder().encode(paths) {
             storedPathsData = data
         }
     }

     private func restoreSelectedItems() {
         if let paths = try? JSONDecoder().decode([String].self, from: storedPathsData) {
             selectedItems = paths.map { URL(fileURLWithPath: $0) }
         }
     }
    var lastRunText: String {
        if let date = appState.lastRunDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last run: \(formatter.string(from: date))"
        }
        return ""
    }
 }

 fileprivate extension String {
     func prepended(by prefix: String) -> String {
         return prefix + self
     }
 }

 struct SettingsView_Previews: PreviewProvider {
     static var previews: some View {
         SettingsView()
             .preferredColorScheme(.dark)
     }
 }





struct NetworkPermissionHelpView: View {
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Centered explanatory message at the top
            Text("macOS will automatically request the following options the first time they are needed. Use these buttons to review options or if you've declined access in the past.")
                .font(.callout)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

            HStack(alignment: .top) {
                Text("Network Volume Access:")
                    .font(.system(size: 13, weight: .semibold))

                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Open macOS Network Volume Access preferences")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(minWidth: 320, alignment: .center)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
            }

            HStack {
                Spacer().frame(width: 173)
                Text("Allowing Network Volume Access gives FileMind access to the full extent of all the files on your Disk. This is essential if you'd like FileMind to be able to search for your files and use the DeepSearch function.")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Divider()

            HStack {
                Spacer()
                Button(action: {
                    onClose()
                }) {
                    Text("Close")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.4))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 16)
        }
        .padding(20)
        .frame(width: 600)
    }
}



//request access


private var dummyMetadataQuery: NSMetadataQuery?
private var observerToken: NSObjectProtocol?

func requestNetworkVolumeAccess(completion: @escaping (Bool) -> Void) {
    dummyMetadataQuery?.stop()
    dummyMetadataQuery = NSMetadataQuery()
    guard let query = dummyMetadataQuery else {
        completion(false)
        return
    }

    var completed = false

    query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, "skdlnfosksdosdfdsfggosidf")
    query.searchScopes = [
        "/home", "/usr", "/.resolve", "/bin", "/sbin", "/.file", "/etc", "/var",
        "/Library", "/System", "/.VolumeIcon.icns", "/private", "/.vol", "/Users",
        "/Applications", "/opt", "/dev", "/Volumes", "/.nofollow", "/tmp", "/cores"
    ]

    observerToken = NotificationCenter.default.addObserver(
        forName: .NSMetadataQueryDidFinishGathering,
        object: query,
        queue: .main
    ) { _ in
        if completed { return }
        completed = true

        query.stop()
        dummyMetadataQuery = nil

        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }

        completion(true)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        let started = query.start()
        if !started {
            completed = true
            dummyMetadataQuery = nil
            completion(false)
        }
    }

}
