//
//  CipherStreams.swift
//  CipherStreams
//
//  Created by Josh Noel on 11/25/23.
//

import Foundation
import IDZSwiftCommonCrypto

let CIPHER_STREAM_DEFAULT_BLOCK_SIZE: Int = 1024
let CIPHER_STREAM_MAX_BLOCK_SIZE: Int = CIPHER_STREAM_DEFAULT_BLOCK_SIZE * 16
let CIPHER_STREAM_ERROR_RESULT: Int = -1

public enum CipherStreamStatus : Error, Equatable {
    case innerTransferError,
    outerTransferError,
    finalTransferError,
    commonCrypto(Status)
}

public protocol StreamLike {
    func close() -> Void
}

public protocol InputStreamLike : StreamLike {
    var hasBytesAvailable: Bool { get }
    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int
}

public protocol OutputStreamLike : StreamLike {
    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int
}

extension Stream : StreamLike {
}

extension InputStream : InputStreamLike {
}

extension OutputStream : OutputStreamLike {
}

public extension InputStreamLike {
    
    func readText(buffer: Array<UInt8>?, encoding: String.Encoding = .utf8, bufferLength: Int? = nil) -> String? {
        let len = bufferLength ?? CIPHER_STREAM_DEFAULT_BLOCK_SIZE
        var buf = buffer ?? Array<UInt8>(repeating: 0, count: len)
        let readCount = self.read(&buf, maxLength: buf.count)
        return readCount > 0 ? String(bytes: buf[0..<readCount], encoding: encoding) : nil
    }
    
    func readAllText(encoding: String.Encoding = .utf8) -> String {
        let buffer = Array<UInt8>(repeating: 0, count: CIPHER_STREAM_DEFAULT_BLOCK_SIZE)
        var result = ""
        
        while let parsed = self.readText(buffer: buffer) {
            result += parsed
        }
        
        return result
    }
}

public extension OutputStreamLike {
    
    @discardableResult
    func writeBytes(_ bytes: Array<UInt8>) -> Int {
        return self.write(bytes, maxLength: bytes.count)
    }
    
    @discardableResult
    func writeUtf8(_ text: String) -> Int {
        return self.writeBytes(Array(text.utf8))
    }
}

public class CryptoUtility {
    public enum Error : Swift.Error {
        case keyGenerationFailed
    }
    
    public static func deriveStreamPassword(_ input: String) throws -> String {
        let fingerprint = try CryptoUtility.loadLoggerIdentifier()
        return "\(fingerprint)+\(input)"
    }
    
    private static func loadLoggerIdentifier() throws -> String {

        let key = "loggerId"
        
        if let identifier = KeychainUtility.getValue(forKey: key) {
            return identifier
        }
        
        let identifierBytes = try Random.generateBytes(byteCount: 16)
        let identifier = hexString(fromArray: identifierBytes)
        
        if KeychainUtility.addValue(identifier, forKey: key) {
            return identifier
        }
        
        throw Error.keyGenerationFailed
    }
}

public class KeychainUtility {
    
    private static func getCompositeKey(_ key: String) -> String? {
        return if let bundleId = Bundle.main.bundleIdentifier {
            "\(bundleId)+\(key)"
        } else {
            nil
        }
    }
    
    public static func setValue(_ value: String, forKey key: String) -> Bool {
        return if KeychainUtility.getValue(forKey: key) != nil {
            KeychainUtility.updateValue(value, forKey: key)
        } else {
            KeychainUtility.addValue(value, forKey: key)
        }
    }
    
    public static func remove(_ key: String) -> Bool {
        guard let bundleKey = KeychainUtility.getCompositeKey(key) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: bundleKey,
        ]
        
        return SecItemDelete(query as CFDictionary) == noErr
    }
    
    public static func addValue(_ value: String, forKey key: String) -> Bool {
        guard let bundleKey = KeychainUtility.getCompositeKey(key) else {
            return false
        }

        let valueData = value.data(using: .utf8)!

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: bundleKey,
            kSecValueData as String: valueData,
        ]
        
        return SecItemAdd(attributes as CFDictionary, nil) == noErr
    }
    
    public static func updateValue(_ value: String, forKey key: String) -> Bool {
        guard let bundleKey = KeychainUtility.getCompositeKey(key) else {
            return false
        }
        
        let valueData = value.data(using: .utf8)!
        let attributes: [String: Any] = [kSecValueData as String: valueData]
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: bundleKey,
        ]
        
        return SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == noErr
    }
    
    public static func getValue(forKey key: String) -> String? {
        guard let bundleKey = KeychainUtility.getCompositeKey(key) else {
            return nil
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: bundleKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]
        
        var item: CFTypeRef?
        
        if SecItemCopyMatching(query as CFDictionary, &item) != noErr {
            return nil
        }
        
        if let existingItem = item as? [String: Any],
           let extractedBundleKey = existingItem[kSecAttrLabel as String] as? String,
           let valueData = existingItem[kSecValueData as String] as? Data,
           let value = String(data: valueData, encoding: .utf8),
           extractedBundleKey == bundleKey
        {
            return value
        }
        
        return nil
    }
}

