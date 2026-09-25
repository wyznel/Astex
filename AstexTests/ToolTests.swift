import XCTest
import Foundation
import SwiftData
import Darwin
import Ollama
import RapidMLX
@testable import Astex

@MainActor
final class ToolTests: XCTestCase {
    private func store() -> PermissionStore {
        let defaults = UserDefaults(suiteName: "AstexTests.\(UUID().uuidString)")!
        return PermissionStore(defaults: defaults)
    }

    private func request(_ store: PermissionStore, _ name: String, _ capability: ToolCapability = .readFile) -> Task<Bool, Never> {
        Task { await store.requestPermission(tool: name, capability: capability, summary: name) }
    }

    private func waitForRequest(_ store: PermissionStore, named name: String) async throws {
        for _ in 0..<200 {
            if store.pendingRequest?.toolName == name { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("The permission request did not appear: \(name)")
        throw CancellationError()
    }

    func testPermissionQueueAndCancellation() async throws {
        let store = store()
        let first = request(store, "first")
        try await waitForRequest(store, named: "first")
        let firstID = try XCTUnwrap(store.pendingRequest?.id)
        let second = request(store, "second")
        let third = request(store, "third")
        await Task.yield()
        second.cancel()
        let secondAllowed = await second.value
        XCTAssertFalse(secondAllowed)
        XCTAssertEqual(store.pendingRequest?.id, firstID)
        first.cancel()
        let firstAllowed = await first.value
        XCTAssertFalse(firstAllowed)
        try await waitForRequest(store, named: "third")
        store.resolve(.allowOnce, requestID: firstID)
        XCTAssertEqual(store.pendingRequest?.toolName, "third")
        store.resolve(.allowOnce, requestID: try XCTUnwrap(store.pendingRequest?.id))
        let thirdAllowed = await third.value
        XCTAssertTrue(thirdAllowed)
        XCTAssertNil(store.pendingRequest)
    }

    func testQueueAppliesPersistentAndSessionChoices() async throws {
        for choice in [PermissionStore.UserChoice.alwaysAllow, .alwaysDeny, .allowForChat] {
            let store = store()
            let session = NSObject()
            store.currentSessionID = ObjectIdentifier(session)
            let first = request(store, "first")
            try await waitForRequest(store, named: "first")
            let second = request(store, "second")
            await Task.yield()
            store.resolve(choice, requestID: try XCTUnwrap(store.pendingRequest?.id))
            let a = await first.value
            let b = await second.value
            XCTAssertEqual(a, b)
            XCTAssertNil(store.pendingRequest)
            if case .allowForChat = choice {
                XCTAssertTrue(a)
                store.currentSessionID = ObjectIdentifier(NSObject())
                let next = request(store, "new chat")
                try await waitForRequest(store, named: "new chat")
                store.cancelPending()
                let allowed = await next.value
                XCTAssertFalse(allowed)
            }
        }
    }

    func testDispatchChecksPermissionsForBothInputsAndAdapter() async throws {
        let store = store()
        let registry = ToolRegistry(tools: [ReadFile.makeTool()], permissionStore: store)
        let raw = Task { await registry.execute(name: "read_file", jsonString: #"{"path":"/missing"}"#) }
        try await waitForRequest(store, named: "read_file")
        store.resolve(.denyOnce, requestID: try XCTUnwrap(store.pendingRequest?.id))
        let rawResult = await raw.value
        XCTAssertEqual(rawResult.status, .denied)
        let structured = Task { await registry.execute(name: "read_file", arguments: ["path": .string("/missing")]) }
        try await waitForRequest(store, named: "read_file")
        store.resolve(.alwaysDeny, requestID: try XCTUnwrap(store.pendingRequest?.id))
        let structuredResult = await structured.value
        XCTAssertEqual(structuredResult.status, .denied)
        let adapted = try XCTUnwrap(registry.allRapidMLXTools.first as? RapidMLX.Tool<[String: RapidMLX.JSONValue], RapidMLX.JSONValue>)
        let result = try await adapted(["path": .string("/missing")])
        let decoded = try JSONDecoder().decode(ToolExecution.self, from: JSONEncoder().encode(result))
        XCTAssertEqual(decoded.status, .denied)
        XCTAssertFalse(decoded.displayText.contains("completed"))
    }

    func testCompletedAndCancelledDispatch() async throws {
        let store = store()
        let registry = ToolRegistry(tools: [ReadFile.makeTool()], permissionStore: store)
        let file = try temporaryDirectory().appendingPathComponent("text")
        try Data("result".utf8).write(to: file)
        let pending = Task { await registry.execute(name: "read_file", arguments: ["path": .string(file.path)]) }
        try await waitForRequest(store, named: "read_file")
        pending.cancel()
        let cancelled = await pending.value
        XCTAssertEqual(cancelled.status, .cancelled)
        XCTAssertNil(store.pendingRequest)
        store.set(.alwaysAllow, for: .readFile)
        let completed = await registry.execute(name: "read_file", arguments: ["path": .string(file.path)])
        XCTAssertEqual(completed.status, .completed)
        XCTAssertTrue(completed.displayText.contains("completed"))
        let output = try JSONDecoder().decode(ReadFileOutput.self, from: Data(completed.resultJSON.utf8))
        XCTAssertEqual(output.contents, "result")
    }

    func testOnceChoicesLeaveTheNextRequestPending() async throws {
        let store = store()
        let first = request(store, "first")
        try await waitForRequest(store, named: "first")
        let second = request(store, "second")
        await Task.yield()
        store.resolve(.denyOnce, requestID: try XCTUnwrap(store.pendingRequest?.id))
        let denied = await first.value
        XCTAssertFalse(denied)
        try await waitForRequest(store, named: "second")
        store.resolve(.allowOnce, requestID: try XCTUnwrap(store.pendingRequest?.id))
        let allowed = await second.value
        XCTAssertTrue(allowed)
        XCTAssertNil(store.pendingRequest)
    }

    func testErrorsAndSchemas() async throws {
        let store = store()
        store.set(.alwaysAllow, for: .readFile)
        let registry = ToolRegistry(tools: [ReadFile.makeTool()], permissionStore: store)
        for arguments in ["{", "{}", #"{"path":123}"#, #"{"path":"/missing"}"#] {
            let result = await registry.execute(name: "read_file", jsonString: arguments)
            XCTAssertEqual(result.status, .failed)
            XCTAssertNoThrow(try JSONDecoder().decode(ToolExecution.self, from: Data(result.json.utf8)))
        }
        let unknown = await registry.execute(name: "bad\"\nname", jsonString: "{}")
        XCTAssertEqual(unknown.status, .failed)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(unknown.resultJSON.utf8)))
        let rapidSchema = try JSONSerialization.jsonObject(with: JSONEncoder().encode(registry.allRapidMLXTools[0].schema)) as! [String: Any]
        XCTAssertEqual((rapidSchema["function"] as? [String: Any])?["name"] as? String, "read_file")
        let schema = try JSONSerialization.jsonObject(with: JSONEncoder().encode(registry.allToolProtocols[0].schema)) as! [String: Any]
        let function = schema["function"] as! [String: Any]
        let parameters = function["parameters"] as! [String: Any]
        XCTAssertEqual(parameters["required"] as? [String], ["path"])
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func read(_ url: URL) async throws -> ReadFileOutput {
        let result = try await ReadFile.makeTool().execute(arguments: ["path": .string(url.path)])
        return try JSONDecoder().decode(ReadFileOutput.self, from: Data(result.utf8))
    }

    func testFileLimitsUTF8AndSpecialFiles() async throws {
        let directory = try temporaryDirectory()
        let file = directory.appendingPathComponent("text")
        let limit = ReadFile.maximumBytes
        for count in [0, limit - 1, limit, limit + 1, limit * 4] {
            try Data(repeating: 65, count: count).write(to: file)
            let output = try await read(file)
            XCTAssertTrue(output.success)
            XCTAssertEqual(output.contents.utf8.count, min(count, limit))
            XCTAssertEqual(output.truncated, count > limit)
        }
        for offset in 1...3 {
            let prefix = String(repeating: "a", count: limit - offset)
            try Data((prefix + "😀tail").utf8).write(to: file)
            let output = try await read(file)
            XCTAssertTrue(output.success)
            XCTAssertTrue(output.truncated)
            XCTAssertEqual(output.contents, prefix)
        }
        for bytes: [UInt8] in [[0, 65], [255, 254], [0xC3]] {
            try Data(bytes).write(to: file)
            let output = try await read(file)
            XCTAssertFalse(output.success)
        }
        let fifo = directory.appendingPathComponent("pipe")
        XCTAssertEqual(mkfifo(fifo.path, 0o600), 0)
        let output = try await read(fifo)
        XCTAssertFalse(output.success)
        let folder = try await read(directory)
        XCTAssertFalse(folder.success)
    }

    func testDirectoryLimitsAndPaths() async throws {
        let directory = try temporaryDirectory()
        let tool = ListDirectory.makeTool()
        for count in [0, ListDirectory.maximumItems, ListDirectory.maximumItems + 1] {
            if count > 0 {
                for index in 0..<count {
                    FileManager.default.createFile(atPath: directory.appendingPathComponent("file-\(index)").path, contents: Data())
                }
            }
            let json = try await tool.execute(arguments: ["path": .string(directory.path)])
            let output = try JSONDecoder().decode(ListDirectoryOutput.self, from: Data(json.utf8))
            XCTAssertTrue(output.success)
            XCTAssertEqual(output.items.count, min(count, ListDirectory.maximumItems))
            XCTAssertEqual(output.truncated, count > ListDirectory.maximumItems)
            XCTAssertFalse(output.items.contains { $0.name == "." || $0.name == ".." })
        }
        for path in ["", directory.appendingPathComponent("file-0").path, "/missing"] {
            let json = try await tool.execute(arguments: ["path": .string(path)])
            let output = try JSONDecoder().decode(ListDirectoryOutput.self, from: Data(json.utf8))
            XCTAssertFalse(output.success)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertEqual(FileManager.resolveFile(from: "~/a").path, home.appendingPathComponent("a").path)
        XCTAssertEqual(FileManager.resolveFile(from: "a").path, home.appendingPathComponent("a").path)
    }

    func testStoredResultsSurviveReloadAndEnterContext() throws {
        let directory = try temporaryDirectory()
        let url = directory.appendingPathComponent("chat.store")
        let schema = Schema([Chat.self, Message.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        let result = ToolExecution(name: "read_file", argumentsJSON: #"{"path":"/tmp/example"}"#,
                                   resultJSON: #"{"success":true,"contents":"retained answer"}"#, status: .completed)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let chat = Chat(title: "Test")
            context.insert(chat)
            chat.messages.append(Message(toolExecution: result))
            try context.save()
        }
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let message = try XCTUnwrap(context.fetch(FetchDescriptor<Message>()).first)
        XCTAssertEqual(try JSONDecoder().decode(ToolExecution.self, from: Data(try XCTUnwrap(message.toolExecutionJSON).utf8)), result)
        XCTAssertTrue(try XCTUnwrap(message.contextText).contains("retained answer"))
        XCTAssertTrue(try XCTUnwrap(message.contextText).contains("argumentsJSON"))
        XCTAssertTrue(try XCTUnwrap(message.contextText).contains("completed"))
        XCTAssertTrue(message.response.contains("completed"))
        XCTAssertNotNil(Message(type: .llm(.tool), response: "Old tool call").contextText)
        XCTAssertNil(Message(type: .llm(.thinking), response: "private reasoning").contextText)
        XCTAssertEqual(Message(type: .llm(.response), response: "answer").contextText, "answer")
    }
}
