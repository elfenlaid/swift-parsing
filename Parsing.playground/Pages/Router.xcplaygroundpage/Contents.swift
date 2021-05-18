import Foundation
import Parsing

public struct Request: Appendable, Equatable, Hashable {
  public struct QueryItem: Equatable, Hashable {
    public var name: String
    public var value: String

    public init(
      name: String,
      value: String
    ) {
      self.name = name
      self.value = value
    }
  }

  public struct Header: Equatable, Hashable {
    public var name: String
    public var value: String

    public init(
      name: String,
      value: String
    ) {
      self.name = name
      self.value = value
    }
  }

  public var method: String? = nil
  public var path: [Substring] = []
  public var query: [QueryItem] = []
  public var headers: [Header] = []
  public var body: Data = .init()

  public init(
    method: String? = nil,
    path: [Substring] = [],
    query: [QueryItem] = [],
    headers: [Header] = [],
    body: Data = .init()
  ) {
    self.method = method
    self.path = path
    self.query = query
    self.headers = headers
    self.body = body
  }

  public init() {}

  public mutating func append(contentsOf other: Request) {
    self.method = self.method ?? other.method
    self.path = self.path + other.path
    self.query = self.query + other.query
    self.headers = self.headers + other.headers
    self.body = self.body + other.body
  }
}

public struct Method: Parser {
  public static let get = OneOfMany(Self("GET"), Self("HEAD"))
  public static let post = Self("POST")
  public static let put = Self("PUT")
  public static let patch = Self("PATCH")
  public static let delete = Self("DELETE")

  public let name: String

  public init(_ name: String) {
    self.name = name
  }

  public func parse(_ input: inout Request) -> Void? {
    guard (input.method ?? "GET").caseInsensitiveCompare(self.name) == .orderedSame
    else { return nil }
    input.method = nil
    return ()
  }
}

extension Method: ParserPrinter {
  public func print(_ output: ()) -> Request? {
    Request(method: self.name)
  }
}

public struct PathComponent<Upstream>: Parser where Upstream: Parser, Upstream.Input == Substring {
  public let upstream: Upstream

  public init(_ upstream: Upstream) {
    self.upstream = upstream
  }

  public func parse(_ input: inout Request) -> Upstream.Output? {
    guard
      var component = input.path.first,
      let output = self.upstream.parse(&component),
      component.isEmpty
    else { return nil }
    input.path.removeFirst()
    return output
  }
}

extension PathComponent: ParserPrinter where Upstream: ParserPrinter {
  public func print(_ output: Upstream.Output) -> Request? {
    guard let component = self.upstream.print(output)
    else { return nil }
    return Request(path: component.isEmpty ? [] : [component])
  }
}

public struct PathEnd: Parser {
  public init() {}

  public func parse(_ input: inout Request) -> Void? {
    input.path.isEmpty ? () : nil
  }
}

extension PathEnd: ParserPrinter {
  public func print(_ output: Void) -> Request? {
    .init(path: [])
  }
}

public struct QueryItem<Upstream>: Parser where Upstream: Parser, Upstream.Input == Substring {
  public let name: String
  public let upstream: Upstream

  public init(_ name: String, _ upstream: Upstream) {
    self.name = name
    self.upstream = upstream
  }

  public func parse(_ input: inout Request) -> Upstream.Output? {
    guard
      let index = input.query.firstIndex(where: { $0.name == self.name })
    else { return nil }
    var substring = input.query[index].value[...]
    guard
      let output = self.upstream.parse(&substring),
      substring.isEmpty
    else { return nil }
    input.query.remove(at: index)
    return output
  }
}

extension QueryItem: ParserPrinter where Upstream: ParserPrinter {
  public func print(_ output: Upstream.Output) -> Request? {
    guard let input = self.upstream.print(output)
    else { return nil }
    return Request(query: [.init(name: self.name, value: String(input))])
  }
}

public struct Body<Upstream>: Parser
where
  Upstream: Parser,
  Upstream.Input == Data
{
  public let upstream: Upstream

  public init(_ upstream: Upstream) {
    self.upstream = upstream
  }

  public func parse(_ input: inout Request) -> Upstream.Output? {
    guard let output = self.upstream.parse(&input.body)
    else { return nil }
    input.body = .init()
    return output
  }
}

extension Body: ParserPrinter where Upstream: ParserPrinter {
  public func print(_ output: Upstream.Output) -> Request? {
    guard let input = self.upstream.print(output)
    else { return nil }
    return Request(body: input)
  }
}

// ...

extension URLRequest {
  public init?(_ request: Request) {
    var urlComponents = URLComponents()
    urlComponents.path = request.path.joined(separator: "/")
    if !request.query.isEmpty {
      urlComponents.queryItems = request.query.map { URLQueryItem(name: $0.name, value: $0.value) }
    }
    guard let url = urlComponents.url else { return nil }
    self.init(url: url)
    self.httpMethod = request.method
    for header in request.headers {
      self.addValue(header.value, forHTTPHeaderField: header.name)
    }
    self.httpBody = request.body
  }
}

extension Request {
  public init(_ request: URLRequest) {
    let urlComponents = request.url
      .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
    self.init(
      method: request.httpMethod,
      path: urlComponents?.path.split(separator: "/") ?? [],
      query: urlComponents?.queryItems?.map { .init(name: $0.name, value: $0.value ?? "") } ?? [],
      headers: request.allHTTPHeaderFields?.map { .init(name: $0, value: $1) } ?? [],
      body: request.httpBody ?? .init()
    )
  }
}

// ...

struct User: Codable {
  let email: String
  let password: String
}

enum Route {
  case home
  case episodes(limit: Int?, offset: Int?)
  case episode(Int)
  case search(String)
  case signUp(User)
}

let home = Method.get
  .skip(PathEnd())
  .map(/Route.home)

let episodes = Method.get
  .skip(PathComponent(StartsWith("episodes")))
  .skip(PathEnd())
  .take(Optional.parser(of: QueryItem("limit", Int.parser(isSigned: false))))
  .take(Optional.parser(of: QueryItem("offset", Int.parser(isSigned: false))))
  .map(/Route.episodes)

let episode = Method.get
  .skip(PathComponent(StartsWith("episodes")))
  .take(PathComponent(Int.parser(isSigned: false)))
  .skip(PathEnd())
  .map(/Route.episode)

let search = Method.get
  .skip(PathComponent(StartsWith("search")))
  .skip(PathEnd())
  .take(QueryItem("q", Rest().map(String.fromSubsequence)))
  .map(/Route.search)

let signUp = Method.post
  .skip(PathComponent(StartsWith("sign-up")))
  .skip(PathEnd())
  .take(Body(User.fromJSON))
  .map(/Route.signUp)

let router = home
  .orElse(episodes)
  .orElse(episode)
  .orElse(search)
  .orElse(signUp)

router.parse(.init(URLRequest(url: URL(string: "/?ga=1")!)))
router.parse(.init(URLRequest(url: URL(string: "/episodes/1?ga=1")!)))
router.parse(.init(URLRequest(url: URL(string: "/episodes?limit=10")!)))
router.parse(.init(URLRequest(url: URL(string: "/episodes")!)))
router.parse(.init(URLRequest(url: URL(string: "/search?ga=1")!)))
router.parse(.init(URLRequest(url: URL(string: "/search?q=point%20free&ga=1")!)))
router.parse(.init(URLRequest(url: URL(string: "/search")!)))
router.parse(.init(URLRequest(url: URL(string: "/search?q=")!)))

var req = URLRequest(url: URL(string: "/sign-up")!)
req.httpMethod = "post"
req.httpBody = Data("""
{"email":"support@pointfree.co","password":"blob8108"}
""".utf8)
router.parse(.init(req))

print(router.print(.search("blob"))!)
print(router.print(.search(""))!)
print(router.print(.episode(42))!)
print(router.print(.episodes(limit: 10, offset: 10))!)
print(router.print(.episodes(limit: 10, offset: nil))!)
print(router.print(.episodes(limit: nil, offset: nil))!)
