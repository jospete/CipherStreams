//
//  AESEncryptedFile.swift
//  CipherStreams
//
//  Created by Josh Noel on 11/25/23.
//

import Foundation
import IDZSwiftCommonCrypto

public class AESEncryptedFile {
    public enum Error : Swift.Error {
        case createStreamFailure
    }
    
    private static let defaultSalt = "nevergonnagiveyouup"
    
    private let filePath: URL
    private let producer: CipherStreamProducer
    
    public convenience init(_ filePath: URL) throws {
        let password = try CryptoUtility.deriveStreamPassword(filePath.lastPathComponent)
        self.init(filePath, password: password)
    }
    
    public convenience init(_ filePath: URL, password: String) {
        self.init(filePath, password: password, salt: AESEncryptedFile.defaultSalt)
    }
    
    public convenience init(_ filePath: URL, password: String, salt: String) {
        let key = CryptoUtility.deriveAes128Key(password, salt: salt)
        self.init(filePath, key: key)
    }
    
    public init(_ filePath: URL, key: Array<UInt8>) {
        self.filePath = filePath
        self.producer = CipherStreamProducer.usingAES(key: key)
    }
    
    public func openInputStream(withCapacity: Int? = nil) throws -> CipherInputStream {
        guard let innerStream = InputStream(url: self.filePath) else {
            throw Error.createStreamFailure
        }
        
        let result = try self.producer.openInputStreamDecryptor(
            source: innerStream,
            withCapacity: withCapacity
        )
        
        return result
    }
    
    public func openOutputStream(withCapacity: Int? = nil) throws -> CipherOutputStream {
        guard let innerStream = OutputStream(url: self.filePath, append: false) else {
            throw Error.createStreamFailure
        }
        
        let result = try self.producer.openOutputStreamEncryptor(
            source: innerStream,
            withCapacity: withCapacity
        )
        
        return result
    }
}
