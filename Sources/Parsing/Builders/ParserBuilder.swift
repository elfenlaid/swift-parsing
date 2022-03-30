/// A custom parameter attribute that constructs parsers from closures. The constructed parser
/// runs a number of parsers, one after the other, and accumulates their outputs.
///
/// The ``Parse`` parser acts as an entry point into `@ParserBuilder` syntax, where you can list
/// all of the parsers you want to run. For example, to parse two comma-separated integers:
///
/// ```swift
/// try Parse {
///   Int.parser()
///   ","
///   Int.parser()
/// }
/// .parse("123,456") // (123, 456)
/// ```
@resultBuilder
public enum ParserBuilder<Input> {
  @inlinable
  public static func buildExpression<P: Parser>(_ parser: P) -> P where P.Input == Input {
    parser
  }

  /// Provides support for specifying a parser in ``ParserBuilder`` blocks.
  @inlinable
  public static func buildBlock<P: Parser>(_ parser: P) -> P {
    parser
  }

  /// Provides support for `if`-`else` statements in ``ParserBuilder`` blocks, producing a
  /// conditional parser for the `if` branch.
  ///
  /// ```swift
  /// Parse {
  ///   "Hello"
  ///   if shouldParseComma {
  ///     ", "
  ///   } else {
  ///     " "
  ///   }
  ///   Rest()
  /// }
  /// ```
  @inlinable
  public static func buildEither<TrueParser, FalseParser>(
    first parser: TrueParser
  ) -> Parsers.Conditional<TrueParser, FalseParser> {
    .first(parser)
  }

  /// Provides support for `if`-`else` statements in ``ParserBuilder`` blocks, producing a
  /// conditional parser for the `else` branch.
  ///
  /// ```swift
  /// Parse {
  ///   "Hello"
  ///   if shouldParseComma {
  ///     ", "
  ///   } else {
  ///     " "
  ///   }
  ///   Rest()
  /// }
  /// ```
  @inlinable
  public static func buildEither<TrueParser, FalseParser>(
    second parser: FalseParser
  ) -> Parsers.Conditional<TrueParser, FalseParser> {
    .second(parser)
  }

  /// Provides support for `if` statements in ``ParserBuilder`` blocks, producing an optional
  /// parser.
  @inlinable
  public static func buildIf<P: Parser>(_ parser: P?) -> P? {
    parser
  }

  /// Provides support for `if` statements in ``ParserBuilder`` blocks, producing a void parser for
  /// a given void parser.
  ///
  /// ```swift
  /// Parse {
  ///   "Hello"
  ///   if shouldParseComma {
  ///     ","
  ///   }
  ///   " "
  ///   Rest()
  /// }
  /// ```
  @inlinable
  public static func buildIf<P>(_ parser: P?) -> Parsers.OptionalVoid<P> {
    .init(wrapped: parser)
  }

  /// Provides support for `if #available` statements in ``ParserBuilder`` blocks, producing an
  /// optional parser.
  @inlinable
  public static func buildLimitedAvailability<P: Parser>(_ parser: P?) -> P? {
    parser
  }

  /// Provides support for `if #available` statements in ``ParserBuilder`` blocks, producing a void
  /// parser for a given void parser.
  @inlinable
  public static func buildLimitedAvailability<P>(_ parser: P?) -> Parsers.OptionalVoid<P> {
    .init(wrapped: parser)
  }
}

extension ParserBuilder where Input == Substring {
  @_disfavoredOverload
  @inlinable
  public static func buildExpression<P: Parser>(_ parser: P) -> P where P.Input == Input {
    parser
  }
}

extension ParserBuilder where Input == Substring.UTF8View {
  @_disfavoredOverload
  @inlinable
  public static func buildExpression<P: Parser>(_ parser: P) -> P where P.Input == Input {
    parser
  }
}

//let p0 = Always(())

let p1 = Parse {
  "Caf".utf8
//  FromSubstring {
//    "é"
//  }
  Always(())
  Int.parser()
}


let p2 = Parse {
  "Caf".utf8
//  "Caf".utf8
//  "Caf".utf8
//  "Caf".utf8
//  "Caf".utf8
//  "Caf".utf8
//  FromSubstring { "é" }
  Always(())
  Int.parser()
  Double.parser()
}

let p3 = Parse {
  "Café"
  Always(())
  Int.parser()
}

//let p3 = Parse {
//  Whitespace()
//  //  Int.parser()
//  //  Double.parser()
//}
