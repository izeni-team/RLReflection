//
//  ReflectionErrorTests.swift
//  RetroluxReflector
//
//  Created by Christopher Bryan Henderson on 10/17/16.
//  Copyright © 2016 Christopher Bryan Henderson. All rights reserved.
//

import XCTest
import RetroluxReflector

class ReflectionErrorTests: XCTestCase {
    func testRLObjectReflectorError_UnsupportedBaseClass() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
        }
        
        class Object2: Object1 {}
        
        // Inheriting object 1 should fail
        do {
            _ = try Reflector().reflect(Object2())
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.unsupportedBaseClass(let type) {
            // TODO: Return enum values instead of strings
            XCTAssert(type == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
        
        // Inheriting from Reflection should succeed
        class Object3: Reflection {}
        class Object4: Object3 {}
        do {
            _ = try Reflector().reflect(Object4())
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let ignoredProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotIgnoreNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotIgnoreErrorsForNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let ignoreErrorsForProperties = ["does_not_exist"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotIgnoreErrorsForNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapAndIgnoreProperty() {
        class Object1: NSObject, Reflectable {
            var someProperty = false
            
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["someProperty": "someProperty"]
            static let ignoredProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotMapAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "someProperty")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotTransformAndIgnoreProperty() {
        struct DummyTransformer: RetroluxReflector.ValueTransformer {
            func supports(targetType: Any.Type) -> Bool {
                return true
            }
            func supports(value: Any, targetType: Any.Type, direction: ValueTransformerDirection) -> Bool {
                return true
            }
            
            func transform(_ value: Any, targetType: Any.Type, direction: ValueTransformerDirection) throws -> Any {
                return value
            }
        }
        
        class Object1: NSObject, Reflectable {
            var someProperty = false
            
            required override init() {
                super.init()
            }
            
            // TODO: The type has to be explicitly set because DummyTransformer.self != ValueTransformer.Type
            static let transformedProperties: [String: RetroluxReflector.ValueTransformer] = ["someProperty": DummyTransformer()]
            static let ignoredProperties = ["someProperty"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotTransformAndIgnoreProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "someProperty")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotMapNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let mappedProperties = ["does_not_exist": "something_else"]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotMapNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectorError_CannotTransformNonExistantProperty() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
            
            static let transformedProperties: [String: RetroluxReflector.ValueTransformer] = ["does_not_exist": ReflectableTransformer(reflector: Reflector())]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.cannotTransformNonExistantProperty(propertyName: let propertyName, forClass: let classType) {
            XCTAssert(propertyName == "does_not_exist")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_MappedPropertyConflict() {
        class Object1: NSObject, Reflectable {
            var test1 = ""
            var test2: [Any] = []
            required override init() {
                super.init()
            }
            
            static let mappedProperties = [
                "test1": "conflict_test",
                "test2": "conflict_test"
            ]
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.mappedPropertyConflict(properties: let properties, conflictKey: let conflict, forClass: let classType) {
            XCTAssert(Set(properties) == Set(["test1", "test2"]))
            XCTAssert(conflict == "conflict_test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_UnsupportedPropertyValueType() {
        class Object1: NSObject, Reflectable {
            var test = Data()
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.unsupportedPropertyValueType(property: let property, valueType: let valueType, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(valueType is Data.Type)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_OptionalPrimitiveNumberNotBridgable() {
        class Object1: NSObject, Reflectable {
            var test: Int? = nil
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.optionalPrimitiveNumberNotBridgable(property: let property, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_PropertyNotBridgable() {
        class Object1: NSObject, Reflectable {
            @nonobjc var test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.propertyNotBridgable(property: let property, valueType: let valueType, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(valueType == Bool.self)
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testRLObjectReflectionError_ReadOnlyProperty() {
        class Object1: NSObject, Reflectable {
            let test = false
            
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            _ = try Reflector().reflect(object)
            XCTFail("Operation should not have succeeded.")
        } catch ReflectionError.readOnlyProperty(property: let property, forClass: let classType) {
            XCTAssert(property == "test")
            XCTAssert(classType == Object1.self)
        } catch let error {
            XCTFail("\(error)")
        }
    }
    
    func testNoProperties() {
        class Object1: NSObject, Reflectable {
            required override init() {
                super.init()
            }
        }
        
        let object = Object1()
        do {
            let properties = try Reflector().reflect(object)
            XCTAssert(properties.isEmpty)
        } catch {
            XCTFail("Reading list of properties on empty class should not fail. Failed with error: \(error)")
        }
    }
}
