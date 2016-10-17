//
//  PropertyTypeTests.swift
//  RetroluxReflector
//
//  Created by Christopher Bryan Henderson on 10/17/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import RetroluxReflector

class PropertyTypeTests: XCTestCase {
    func testPropertyTypeInference() {
        XCTAssert(PropertyType.from(AnyObject.self) == .anyObject)
        XCTAssert(PropertyType.from(Optional<Int>.self) == .optional(wrapped: .number))
        XCTAssert(PropertyType.from(Bool.self) == .bool)
        XCTAssert(PropertyType.from(Int.self) == .number)
        XCTAssert(PropertyType.from(Double.self) == .number)
        
        let transformer = ReflectableTransformer()
        var matched = false
        XCTAssert(PropertyType.from(Reflection.self, transformer: transformer, transformerMatched: &matched) == .transformable(transformer: transformer, targetType: Reflection.self))
        XCTAssert(matched)
        matched = false
        
        XCTAssert(PropertyType.from([Int?].self) == .array(type: .optional(wrapped: .number)))
        XCTAssert(PropertyType.from([String: Int?].self) == .dictionary(type: .optional(wrapped: .number)))
        XCTAssert(PropertyType.from(NSDictionary.self) == .dictionary(type: .anyObject))
        XCTAssert(PropertyType.from(NSMutableDictionary.self) == .dictionary(type: .anyObject))
        let jsonDictionaryData = "{\"test\": true}".data(using: String.Encoding.utf8)!
        let jsonDictionaryType: Any.Type = try! type(of: (JSONSerialization.jsonObject(with: jsonDictionaryData, options: [])))
        XCTAssert(PropertyType.from(jsonDictionaryType) == .dictionary(type: .anyObject))
        XCTAssert(PropertyType.from(NSArray.self) == .array(type: .anyObject))
        XCTAssert(PropertyType.from(NSMutableArray.self) == .array(type: .anyObject))
        let jsonArrayData = "[1, 2, 3]".data(using: String.Encoding.utf8)!
        let jsonArrayType: Any.Type = try! type(of: (JSONSerialization.jsonObject(with: jsonArrayData, options: [])))
        XCTAssert(PropertyType.from(jsonArrayType) == .array(type: .anyObject))
        
        class Object2: Reflection {}
        
        class Object1: Reflection {
            dynamic var test = ""
            dynamic var test2 = [String: [Int]]()
            dynamic var test3 = [Object2]()
        }
        
        do {
            let properties = try Reflector().reflect(Object1())
            let propertyNames = properties.map({ $0.name })
            XCTAssert(propertyNames == [
                "test",
                "test2",
                "test3"
                ])
            let propertyTypes = properties.map({ $0.type })
            XCTAssert(propertyTypes == [
                PropertyType.string,
                PropertyType.dictionary(type: .array(type: .number)),
                PropertyType.array(type: PropertyType.transformable(transformer: ReflectableTransformer(), targetType: Object2.self))
                ])
        } catch let error {
            XCTFail("\(error)")
        }
    }
}
