import Foundation
import UIKit

public protocol JSONDecoderWrapperAvailable {
    associatedtype ValueType: Decodable
    static var defaultValue: ValueType { get }
}

public protocol JSONStringConverterAvailable {
    static var defaultValue: Bool { get }
}

public enum JSWrapper {
    public typealias EmptyString = Wrapper<JSWrapper.TypeCase.EmptyString>
    public typealias True = Wrapper<JSWrapper.TypeCase.True>
    public typealias False = Wrapper<JSWrapper.TypeCase.False>
    public typealias IntZero = Wrapper<JSWrapper.TypeCase.Zero<Int>>
    public typealias DoubleZero = Wrapper<JSWrapper.TypeCase.Zero<Double>>
    public typealias FloatZero = Wrapper<JSWrapper.TypeCase.Zero<Float>>
    public typealias CGFloatZero = Wrapper<JSWrapper.TypeCase.Zero<CGFloat>>
    public typealias StringFalse = StringConverterWrapper<JSWrapper.TypeCase.StringFalse>
    public typealias StringTrue = StringConverterWrapper<JSWrapper.TypeCase.StringTrue>
    public typealias EmptyList<T: Decodable & ExpressibleByArrayLiteral> = Wrapper<JSWrapper.TypeCase.List<T>>
    public typealias EmptyDict<T: Decodable & ExpressibleByDictionaryLiteral> = Wrapper<JSWrapper.TypeCase.Dict<T>>
    
    // Property Wrapper - Optional Type to Type
    @propertyWrapper
    public struct Wrapper<T: JSONDecoderWrapperAvailable> {
        public typealias ValueType = T.ValueType
        public var wrappedValue: ValueType
        public init() {
            wrappedValue = T.defaultValue
        }
    }
    
    // Property Wrapper - Optional String To Bool
    @propertyWrapper
    public struct StringConverterWrapper<T: JSONStringConverterAvailable> {
        public var wrappedValue: Bool = T.defaultValue
        public init() {
            wrappedValue = T.defaultValue
        }
    }
    
    // Property Wrapper - Optional Timestamp to Optinoal Date
    @propertyWrapper
    public struct TimestampToOptionalDate {
        public var wrappedValue: Date?
        public init() {
            wrappedValue = nil
        }
    }

    public enum TypeCase {
        // Type Enums
        public enum True: JSONDecoderWrapperAvailable {
            // 기본값 - true
            public static var defaultValue: Bool { true }
        }

        public enum False: JSONDecoderWrapperAvailable {
            // 기본값 - false
            public static var defaultValue: Bool { false }
        }

        public enum EmptyString: JSONDecoderWrapperAvailable {
            // 기본값 - ""
            public static var defaultValue: String { "" }
        }
        
        public enum Zero<T: Decodable>: JSONDecoderWrapperAvailable where T: Numeric {
            // 기본값 - 0
            public static var defaultValue: T { 0 }
        }
        
        public enum StringFalse: JSONStringConverterAvailable {
            // 기본값 - false
            public static var defaultValue: Bool { false }
        }
        
        public enum StringTrue: JSONStringConverterAvailable {
            // 기본값 - false
            public static var defaultValue: Bool { true }
        }
        
        public enum List<T: Decodable & ExpressibleByArrayLiteral>: JSONDecoderWrapperAvailable {
            // 기본값 - []
            public static var defaultValue: T { [] }
        }
        
        public enum Dict<T: Decodable & ExpressibleByDictionaryLiteral>: JSONDecoderWrapperAvailable {
            // 기본값 - [:]
            public static var defaultValue: T { [:] }
        }
    }
}

extension JSWrapper.Wrapper: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(ValueType.self)
    }
}

extension JSWrapper.StringConverterWrapper: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try container.decode(String.self)) == "Y"
    }
}

extension JSWrapper.TimestampToOptionalDate: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let timestamp = try container.decode(Double.self)
        let date = Date.init(timeIntervalSince1970: timestamp)
        self.wrappedValue = date
    }
}

extension KeyedDecodingContainer {
    public func decode<T: JSONDecoderWrapperAvailable>(_ type: JSWrapper.Wrapper<T>.Type, forKey key: Key) throws -> JSWrapper.Wrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
    public func decode<T: JSONStringConverterAvailable>(_ type: JSWrapper.StringConverterWrapper<T>.Type, forKey key: Key) throws -> JSWrapper.StringConverterWrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
    public func decode(_ type: JSWrapper.TimestampToOptionalDate.Type, forKey key: Key) throws -> JSWrapper.TimestampToOptionalDate {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
