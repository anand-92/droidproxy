import XCTest
@testable import CLIProxyMenuBar

final class GrokEndFeatureRunRepairTests: XCTestCase {
    func testInsertsStubHandoffAndCoercesDirtyValidatorsPassed() throws {
        let arguments: [String: Any] = [
            "successState": "success",
            "returnToOrchestrator": false,
            "featureId": "m1-migration-runner-and-lint-baseline",
            "commitId": "2c86843",
            "repoPath": "/Users/josefchen/Projects/panopticon",
            "validatorsPassed": "true persistence_required=true? No that's not a param. Just call it."
        ]

        let repaired = GrokEndFeatureRunRepair.repair(
            name: "EndFeatureRun",
            arguments: arguments,
            assistantText: "Migration runner is in place and verified. Handing off the completed feature."
        )

        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["validatorsPassed"] as? Bool, true)
        let handoff = try XCTUnwrap(repaired.arguments["handoff"] as? [String: Any])
        XCTAssertEqual(
            handoff["salientSummary"] as? String,
            "Migration runner is in place and verified. Handing off the completed feature."
        )
        XCTAssertNotNil(handoff["discoveredIssues"])
    }

    func testInsertsHandoffWhenValidatorsPassedAlreadyBool() throws {
        let arguments: [String: Any] = [
            "successState": "success",
            "returnToOrchestrator": false,
            "featureId": "m1-migration-runner-and-lint-baseline",
            "validatorsPassed": true
        ]

        let repaired = GrokEndFeatureRunRepair.repair(name: "EndFeatureRun", arguments: arguments)
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["validatorsPassed"] as? Bool, true)
        XCTAssertNotNil(repaired.arguments["handoff"] as? [String: Any])
    }

    func testDefaultsMissingValidatorsPassedOnSuccess() {
        let arguments: [String: Any] = [
            "successState": "success",
            "returnToOrchestrator": false,
            "handoff": ["salientSummary": "done"]
        ]
        let repaired = GrokEndFeatureRunRepair.repair(name: "EndFeatureRun", arguments: arguments)
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["validatorsPassed"] as? Bool, true)
    }

    func testLeavesCompletePayloadUnchanged() {
        let arguments: [String: Any] = [
            "successState": "success",
            "returnToOrchestrator": true,
            "featureId": "m1-migration-runner-and-lint-baseline",
            "validatorsPassed": true,
            "handoff": [
                "salientSummary": "done",
                "whatWasImplemented": "runner",
                "whatWasLeftUndone": "",
                "discoveredIssues": [] as [Any]
            ]
        ]
        let repaired = GrokEndFeatureRunRepair.repair(name: "EndFeatureRun", arguments: arguments)
        XCTAssertFalse(repaired.changed)
    }

    func testLeavesCompleteExecuteUnchanged() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: ["command": "ls"]
        )
        XCTAssertFalse(repaired.changed)
    }

    func testRemapsExecuteCmdAliasToCommand() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: ["cmd": "pwd", "summary": "Print working directory"]
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["command"] as? String, "pwd")
        XCTAssertEqual(repaired.arguments["summary"] as? String, "Print working directory")
    }

    func testExtractsCommandEmbeddedInSummary() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: [
                "summary": "Probe HexDB landing relations\ncommand\nnpx dotenv -e .env.local -- node /tmp/panopticon-probe-landing.mjs"
            ]
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(
            repaired.arguments["command"] as? String,
            "npx dotenv -e .env.local -- node /tmp/panopticon-probe-landing.mjs"
        )
    }

    func testPromotesShellLikeSummaryToCommand() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: ["summary": "pwd"]
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["command"] as? String, "pwd")
    }

    func testDoesNotInventCommandFromEnglishSummary() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: ["summary": "List current directory contents"]
        )
        XCTAssertFalse(repaired.changed)
        XCTAssertNil(repaired.arguments["command"])
    }

    func testExtractsFencedCommandFromAssistantText() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Execute",
            arguments: ["summary": "Probe HexDB for 23 landing relations"],
            assistantText: """
            Run this exact command:

            ```
            npx dotenv -e .env.local -- node /tmp/panopticon-probe-landing.mjs
            ```
            """
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(
            repaired.arguments["command"] as? String,
            "npx dotenv -e .env.local -- node /tmp/panopticon-probe-landing.mjs"
        )
    }

    func testRemapsReadPathAlias() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Read",
            arguments: ["path": "/tmp/a.swift"]
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["file_path"] as? String, "/tmp/a.swift")
    }

    func testRemapsGrepRegexAlias() {
        let repaired = GrokEndFeatureRunRepair.repair(
            name: "Grep",
            arguments: ["regex": "uppercase"]
        )
        XCTAssertTrue(repaired.changed)
        XCTAssertEqual(repaired.arguments["pattern"] as? String, "uppercase")
    }

    func testRepairsExecuteInResponsesAPIFunctionCall() throws {
        let body = """
        {"output":[{"type":"function_call","name":"Execute","arguments":"{\\"summary\\":\\"Print working directory\\",\\"cmd\\":\\"pwd\\"}"}]}
        """
        let rewritten = try XCTUnwrap(GrokEndFeatureRunRepair.repairJSONBody(body))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(rewritten.utf8)) as? [String: Any])
        let output = try XCTUnwrap(root["output"] as? [[String: Any]])
        let argsJSON = try XCTUnwrap(output[0]["arguments"] as? String)
        let args = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(argsJSON.utf8)) as? [String: Any])
        XCTAssertEqual(args["command"] as? String, "pwd")
    }

    func testRepairsResponsesAPIFunctionCall() throws {
        let body = """
        {"output":[{"type":"function_call","name":"EndFeatureRun","arguments":"{\\"successState\\":\\"success\\",\\"featureId\\":\\"m1-migration-runner-and-lint-baseline\\",\\"validatorsPassed\\":true}"}]}
        """
        let rewritten = try XCTUnwrap(GrokEndFeatureRunRepair.repairJSONBody(body))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(rewritten.utf8)) as? [String: Any])
        let output = try XCTUnwrap(root["output"] as? [[String: Any]])
        let argsJSON = try XCTUnwrap(output[0]["arguments"] as? String)
        let args = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(argsJSON.utf8)) as? [String: Any])
        XCTAssertNotNil(args["handoff"] as? [String: Any])
        XCTAssertEqual(args["validatorsPassed"] as? Bool, true)
    }

    func testRepairsChatCompletionToolCall() throws {
        let body = """
        {"choices":[{"message":{"role":"assistant","content":"Handing off.","tool_calls":[{"id":"call_1","type":"function","function":{"name":"EndFeatureRun","arguments":"{\\"successState\\":\\"success\\",\\"validatorsPassed\\":true}"}}]}}]}
        """
        let rewritten = try XCTUnwrap(GrokEndFeatureRunRepair.repairJSONBody(body))
        XCTAssertTrue(rewritten.contains("handoff"))
        XCTAssertTrue(rewritten.contains("salientSummary"))
    }

    func testRepairsResponsesSSEDoneEvent() throws {
        let sse = """
        event: response.function_call_arguments.delta
        data: {"delta":"{\\"successState\\":"}

        event: response.function_call_arguments.done
        data: {"arguments":"{\\"successState\\":\\"success\\",\\"featureId\\":\\"m1-x\\",\\"validatorsPassed\\":true}"}

        """
        let rewritten = try XCTUnwrap(GrokEndFeatureRunRepair.repairSSE(sse))
        XCTAssertFalse(rewritten.contains("function_call_arguments.delta"))
        XCTAssertTrue(rewritten.contains("handoff"))
    }
}
