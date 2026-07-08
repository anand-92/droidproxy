import XCTest
@testable import CLIProxyMenuBar

final class GrokAuthTests: XCTestCase {
    func testParseDeviceAuthorizationAcceptsIntegerExpiresIn() throws {
        let json = """
        {"device_code":"dc","user_code":"ABCD-EFGH","verification_uri_complete":"https://auth.x.ai/device","interval":5,"expires_in":900}
        """.data(using: .utf8)!

        let auth = try XCTUnwrap(GrokAuth.parseDeviceAuthorization(json))
        XCTAssertEqual(auth.deviceCode, "dc")
        XCTAssertEqual(auth.userCode, "ABCD-EFGH")
        XCTAssertEqual(auth.interval, 5)
        XCTAssertEqual(auth.expiresIn, 900)
    }

    func testParseTokenResponseSuccess() throws {
        // id_token payload: {"email":"u@x.ai"} as base64url
        let json = """
        {"access_token":"access","refresh_token":"refresh","expires_in":3600,"id_token":"hdr.eyJlbWFpbCI6InVAeC5haSJ9.sig"}
        """.data(using: .utf8)!
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = GrokAuth.parseTokenResponse(json, statusCode: 200, now: now)
        guard case .success(let creds) = result else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(creds.access, "access")
        XCTAssertEqual(creds.refresh, "refresh")
        XCTAssertEqual(creds.email, "u@x.ai")
        XCTAssertEqual(creds.expiresAtMs, now.timeIntervalSince1970 * 1000 + 3600 * 1000 - GrokAuth.refreshSkewMs)
    }

    func testParseTokenResponseAuthorizationPending() {
        let json = #"{"error":"authorization_pending"}"#.data(using: .utf8)!
        let result = GrokAuth.parseTokenResponse(json, statusCode: 400, now: Date())
        guard case .failure(.authorizationPending) = result else {
            return XCTFail("expected authorizationPending")
        }
    }

    func testCredentialsRoundTrip() throws {
        let creds = GrokAuth.Credentials(access: "a", refresh: "r", expiresAtMs: 123, email: "u@x.ai")
        let json = GrokAuth.credentialsJSON(creds)
        XCTAssertEqual(json["type"] as? String, "grok-cli")
        let parsed = try XCTUnwrap(GrokAuth.credentials(from: json))
        XCTAssertEqual(parsed.access, "a")
        XCTAssertEqual(parsed.refresh, "r")
        XCTAssertEqual(parsed.expiresAtMs, 123)
        XCTAssertEqual(parsed.email, "u@x.ai")
    }

    func testApiHostIsPublicXAI() {
        XCTAssertEqual(GrokAuth.apiHost, "api.x.ai")
    }
}
