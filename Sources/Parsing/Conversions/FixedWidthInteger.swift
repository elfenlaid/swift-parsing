import Foundation

extension Conversion where Self == Conversions.BinaryFloatingPointToFixedWidthInteger<Double, Int> {
  @inlinable
  public static var int: Self { .init() }
}

extension Conversion where Output == Double {
  @inlinable
  public var double:
    Conversions.Map<
      Self, Conversions.BinaryFloatingPointToFixedWidthInteger<Double, Int>
    >
  { self.map(.int) }
}

extension Conversions {
  public struct BinaryFloatingPointToFixedWidthInteger<
    Input: BinaryFloatingPoint, Output: FixedWidthInteger
  >: Conversion {
    @usableFromInline
    init() {}

    @inlinable
    public func apply(_ input: Input) -> Output {
      .init(input)
    }

    @inlinable
    public func unapply(_ output: Output) -> Input {
      .init(output)
    }
  }
}
