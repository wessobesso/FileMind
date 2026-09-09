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
    let remoteDir = "/root/incoming_files"
    let remoteOutputPath = "/root/filemind_output.json"
    let localOutputPath = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/FileMind/filemind_output.json").path
    let files: [URL]

    init(fileList: [URL]) {
        self.files = fileList
    }

    func uploadAndRun(completion: @escaping (Bool) -> Void) {
        // Create remote directory
        print("Creating remote directory at \(remoteDir)...")
        let mkdirCommand = """
        ssh -i '\(sshKeyPath)' -o StrictHostKeyChecking=no root@\(remoteIP) 'mkdir -p "\(remoteDir)"'
        """
        guard runShell(mkdirCommand) else {
            print("Failed to create remote folder")
            completion(false)
            return
        }

        // Ensure there are files
        guard !files.isEmpty else {
            print("No files found to upload")
            completion(false)
            return
        }

        // Upload using 2 threads
        print("Uploading selected files using 2 threads...")
        let queue = DispatchQueue(label: "upload.queue", attributes: .concurrent)
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 2)

        for file in files {
            group.enter()
            semaphore.wait()

            queue.async {
                let escaped = file.path.replacingOccurrences(of: "'", with: "'\\''")
                print("Uploading file: \(file.lastPathComponent)")

                let uploadCommand = """
                scp -i '\(self.sshKeyPath)' -o StrictHostKeyChecking=no '\(escaped)' root@\(self.remoteIP):'\(self.remoteDir)/'
                """
                let success = self.runShell(uploadCommand)

                if success {
                    print("Uploaded: \(file.lastPathComponent)")
                } else {
                    print("Failed to upload: \(file.lastPathComponent)")
                }

                semaphore.signal()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("All uploads finished. Starting backend pipeline...")

            let runCommand = """
            ssh -i '\(self.sshKeyPath)' -o StrictHostKeyChecking=no root@\(self.remoteIP) 'python3 /root/run_full_backend_pipeline.py'
            """

            DispatchQueue.global(qos: .background).async {
                let success = self.runShell(runCommand)

                DispatchQueue.main.async {
                    if success {
                        print("Backend processing complete")

                        // Create local directory if needed
                        try? FileManager.default.createDirectory(
                            atPath: (self.localOutputPath as NSString).deletingLastPathComponent,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )

                        // Download file
                        let scpDownloadCommand = """
                        scp -i '\(self.sshKeyPath)' -o StrictHostKeyChecking=no root@\(self.remoteIP):\(self.remoteOutputPath) '\(self.localOutputPath)'
                        """

                        if self.runShell(scpDownloadCommand) {
                            print("filemind_output.json downloaded to: \(self.localOutputPath)")
                            completion(true)
                        } else {
                            print("Failed to download filemind_output.json")
                            completion(false)
                        }

                    } else {
                        print("Backend processing failed")
                        completion(false)
                    }
                }
            }
        }
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
            print("Failed to launch process:", error)
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
