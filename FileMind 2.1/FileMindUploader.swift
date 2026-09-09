//
//  Untitled.swift
//  FileMind
//
//  Created by WessoBesso on 2025-06-16.
//

import Foundation

class FileMindUploader {
    let remoteIP = "45.55.134.181"
    let sshKeyPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".ssh/id_ed25519").path
    let remoteBaseDir = "/root/incoming_files"
    let jobID = UUID().uuidString

    func uploadAndRun() {
        let jobRemoteDir = "\(remoteBaseDir)/\(jobID)"
        let fileManager = FileManager.default

        print("📁 Creating remote directory at \(jobRemoteDir)...")
        let mkdirCommand = """
        ssh -i \(sshKeyPath) -o StrictHostKeyChecking=no root@\(remoteIP) 'mkdir -p "\(jobRemoteDir)"'
        """
        guard runShell(mkdirCommand) else {
            print("❌ Failed to create remote job folder")
            return
        }

        print("🔍 Gathering files...")
        let files = gatherFiles()
        if files.isEmpty {
            print("⚠️ No files found to upload")
            return
        }

        print("📝 Writing batch upload script...")
        let tempScriptURL = fileManager.temporaryDirectory.appendingPathComponent("upload_batch_\(jobID).sh")
        var script = "#!/bin/bash\n\n"
        for file in files {
            let escaped = file.path.replacingOccurrences(of: "'", with: "'\\''")
            script += "scp -i '\(sshKeyPath)' -o StrictHostKeyChecking=no '\(escaped)' root@\(remoteIP):'\(jobRemoteDir)/'\n"
        }

        do {
            try script.write(to: tempScriptURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScriptURL.path)
        } catch {
            print("❌ Failed to write upload script:", error)
            return
        }

        print("📤 Uploading files to DO server...")
        guard runShell(tempScriptURL.path) else {
            print("❌ Upload script failed")
            return
        }

        print("🚀 Files uploaded. Starting backend pipeline...")
        let runCommand = """
        ssh -i \(sshKeyPath) -o StrictHostKeyChecking=no root@\(remoteIP) 'python3 /root/run_full_backend_pipeline.py "\(jobID)"'
        """
        guard runShell(runCommand) else {
            print("❌ Failed to start backend pipeline")
            return
        }

        print("✅ Backend processing complete for job ID: \(jobID)")

        try? fileManager.removeItem(at: tempScriptURL)
    }

    private func gatherFiles() -> [URL] {
        let dirs = ["Documents", "Downloads", "Desktop"]
        var allFiles: [URL] = []
        let fm = FileManager.default

        for dir in dirs {
            let base = fm.homeDirectoryForCurrentUser.appendingPathComponent(dir)
            guard let enumerator = fm.enumerator(at: base, includingPropertiesForKeys: nil) else { continue }

            for case let file as URL in enumerator {
                if !file.hasDirectoryPath {
                    allFiles.append(file)
                }
            }
        }

        return allFiles
    }

    @discardableResult
    private func runShell(_ command: String) -> Bool {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            print("❌ Failed to launch process:", error)
            return false
        }

        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if let output = String(data: outputData, encoding: .utf8),
           !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("ℹ️", output)
        }

        if let errorOutput = String(data: errorData, encoding: .utf8),
           !errorOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️", errorOutput)
        }

        return task.terminationStatus == 0
    }
}
