import Foundation
import UIKit

/*
 사용법 - 개인 블로그 참고
 https://jiseobkim.github.io/swift/2021/07/18/swift-Property-Wrapper-(feat.-Codable-코드-정리).html
 */
typealias JWEmptyString = JSDecodeJSONWrapper.EmptyString
typealias JWTrue = JSDecodeJSONWrapper.True
typealias JWFalse = JSDecodeJSONWrapper.False
typealias JWIntZero = JSDecodeJSONWrapper.IntZero
typealias JWDoubleZero = JSDecodeJSONWrapper.DoubleZero
typealias JWFloatZero = JSDecodeJSONWrapper.FloatZero
typealias JWCGFloatZero = JSDecodeJSONWrapper.CGFloatZero
typealias JWStringFalse = JSDecodeJSONWrapper.StringFalse
typealias JWStringTrue = JSDecodeJSONWrapper.StringTrue
typealias JWEmptyList = JSDecodeJSONWrapper.EmptyList
typealias JWEmptyDict = JSDecodeJSONWrapper.EmptyDict
typealias JWTimestampToDate = JSDecodeJSONWrapper.TimestampToOptionalDate

protocol JSONDecodeWrapperAvailable {
    associatedtype ValueType: Decodable, Hashable
    static var defaultValue: ValueType { get }
}

protocol JSONStringConverterAvailable {
    static var defaultValue: Bool { get }
}


enum JSDecodeJSONWrapper {
    typealias EmptyString = Wrapper<JSDecodeJSONWrapper.TypeCase.EmptyString>
    typealias True = Wrapper<JSDecodeJSONWrapper.TypeCase.True>
    typealias False = Wrapper<JSDecodeJSONWrapper.TypeCase.False>
    typealias IntZero = Wrapper<JSDecodeJSONWrapper.TypeCase.Zero<Int>>
    typealias DoubleZero = Wrapper<JSDecodeJSONWrapper.TypeCase.Zero<Double>>
    typealias FloatZero = Wrapper<JSDecodeJSONWrapper.TypeCase.Zero<Float>>
    typealias CGFloatZero = Wrapper<JSDecodeJSONWrapper.TypeCase.Zero<CGFloat>>
    typealias StringFalse = StringConverterWrapper<JSDecodeJSONWrapper.TypeCase.StringFalse>
    typealias StringTrue = StringConverterWrapper<JSDecodeJSONWrapper.TypeCase.StringTrue>
    typealias EmptyList<T: Decodable & ExpressibleByArrayLiteral & Hashable> = Wrapper<JSDecodeJSONWrapper.TypeCase.List<T>>
    typealias EmptyDict<T: Decodable & ExpressibleByDictionaryLiteral & Hashable> = Wrapper<JSDecodeJSONWrapper.TypeCase.Dict<T>>
    
    // Property Wrapper - Optional Type to Type
    @propertyWrapper
    struct Wrapper<T: JSONDecodeWrapperAvailable> {
        typealias ValueType = T.ValueType

        var wrappedValue: ValueType

        init() {
        wrappedValue = T.defaultValue
        }
    }
    
    // Property Wrapper - Optional String To Bool
    @propertyWrapper
    struct StringConverterWrapper<T: JSONStringConverterAvailable> {
        var wrappedValue: Bool = T.defaultValue
    }
    
    // Property Wrapper - Optional Timestamp to Optinoal Date
    @propertyWrapper
    struct TimestampToOptionalDate {
        var wrappedValue: Date?
    }
    
    @propertyWrapper
    struct TrueByStringToBool {
        var wrappedValue: Bool = true
    }
    
    @propertyWrapper
    struct FalseByStringToBool {
        var wrappedValue: Bool = false
    }
    

    enum TypeCase {
        // Type Enums
        enum True: JSONDecodeWrapperAvailable {
            // 기본값 - true
            static var defaultValue: Bool { true }
        }

        enum False: JSONDecodeWrapperAvailable {
            // 기본값 - false
            static var defaultValue: Bool { false }
        }

        enum EmptyString: JSONDecodeWrapperAvailable {
            // 기본값 - ""
            static var defaultValue: String { "" }
        }
        
        enum Zero<T: Decodable & Hashable>: JSONDecodeWrapperAvailable where T: Numeric {
            // 기본값 - 0
            static var defaultValue: T { 0 }
        }
        
        enum StringFalse: JSONStringConverterAvailable {
            // 기본값 - false
            static var defaultValue: Bool { false }
        }
        
        enum StringTrue: JSONStringConverterAvailable {
            // 기본값 - false
            static var defaultValue: Bool { true }
        }
        
        enum List<T: Decodable & ExpressibleByArrayLiteral & Hashable>: JSONDecodeWrapperAvailable {
            // 기본값 - []
            static var defaultValue: T { [] }
        }
        
        enum Dict<T: Decodable & ExpressibleByDictionaryLiteral & Hashable>: JSONDecodeWrapperAvailable {
            // 기본값 - [:]
            static var defaultValue: T { [:] }
        }
    }
}

extension JSDecodeJSONWrapper.Wrapper: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(ValueType.self)
    }
}

extension JSDecodeJSONWrapper.StringConverterWrapper: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try container.decode(String.self)) == "Y"
    }
}

extension JSDecodeJSONWrapper.TimestampToOptionalDate: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        guard let timestamp = try? container.decode(Double.self) else {
            self.wrappedValue = nil
            return
        }
        let date = Date.init(timeIntervalSince1970: timestamp)
        self.wrappedValue = date
    }
}

extension KeyedDecodingContainer {
    func decode<T: JSONDecodeWrapperAvailable>(_ type: JSDecodeJSONWrapper.Wrapper<T>.Type, forKey key: Key) throws -> JSDecodeJSONWrapper.Wrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
    func decode<T: JSONStringConverterAvailable>(_ type: JSDecodeJSONWrapper.StringConverterWrapper<T>.Type, forKey key: Key) throws -> JSDecodeJSONWrapper.StringConverterWrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
    func decode(_ type: JSDecodeJSONWrapper.TimestampToOptionalDate.Type, forKey key: Key) throws -> JSDecodeJSONWrapper.TimestampToOptionalDate {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
}
