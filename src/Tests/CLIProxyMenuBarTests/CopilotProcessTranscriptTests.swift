import XCTest
@testable import CLIProxyMenuBar

final class CopilotProcessTranscriptTests: XCTestCase {
    func testReportsLastMeaningfulLineWithExitCode() {
        let transcript = ProcessTranscript()
        transcript.append("ℹ Logging in with GitHub Copilot\n")
        transcript.append("env: node: No such file or directory\n\n")

        XCTAssertEqual(
            transcript.failureDetail(exitCode: 127),
            "env: node: No such file or directory (exit code 127)"
        )
    }

    func testStripsANSIEscapeSequences() {
        let transcript = ProcessTranscript()
        transcript.append("\u{001B}[31m✖\u{001B}[39m Failed to fetch Copilot token\n")

        XCTAssertEqual(
            transcript.failureDetail(exitCode: 1),
            "✖ Failed to fetch Copilot token (exit code 1)"
        )
    }

    func testFallsBackToExitCodeWhenNoOutputWasCaptured() {
        let transcript = ProcessTranscript()

        XCTAssertEqual(
            transcript.failureDetail(exitCode: 143),
            "the sign-in helper exited with code 143."
        )
    }

    func testAuthenticationFailedErrorIncludesDetail() {
        let withDetail = CopilotGatewayError.authenticationFailed("env: node: not found (exit code 127)")
        XCTAssertEqual(
            withDetail.localizedDescription,
            "GitHub Copilot authentication did not complete: env: node: not found (exit code 127)"
        )

        let withoutDetail = CopilotGatewayError.authenticationFailed(nil)
        XCTAssertEqual(
            withoutDetail.localizedDescription,
            "GitHub Copilot authentication did not complete. Please try again."
        )
    }
}
