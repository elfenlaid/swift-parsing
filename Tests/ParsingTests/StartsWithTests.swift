import Parsing
import XCTest

final class StartsWithTests: XCTestCase {
  func testStartsWith() {
    var str = "Hello, world!"[...].utf8
    XCTAssertNotNil(try StartsWith("Hello".utf8).parse(&str))
    XCTAssertEqual(", world!", Substring(str))
  }
}
