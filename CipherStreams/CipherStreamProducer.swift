//
//  CipherStreamProducer.swift
//  CipherStreams
//
//  Created by Josh Noel on 11/27/23.
//

import Foundation
import IDZSwiftCommonCrypto

public class CipherStreamProducer {
    public enum Error : Swift.Error {
        case headerWriteFailure, headerReadFailure
    }

    private let algorithm: Cryptor.Algorithm
    private let key: Array<UInt8>
    private let mode: Cryptor.Mode
    private let padding: Cryptor.Padding
    
    public init(
        key: Array<UInt8>, 
        algorithm: Cryptor.Algorithm,
        mode: Cryptor.Mode,
        padding: Cryptor.Padding
    ) {
        self.key = key
        self.algorithm = algorithm
        self.mode = mode
        self.padding = padding
    }
    
    public static func usingAES(key: Array<UInt8>) -> CipherStreamProducer {
        return CipherStreamProducer(
            key: key, 
            algorithm: .aes,
            mode: .CBC,
            padding: .PKCS7Padding
        )
    }
    
    public func createCryptor(operation: Cryptor.Operation, iv: Array<UInt8>) -> StreamCryptor {
        return StreamCryptor(
            operation: operation,
            algorithm: self.algorithm,
            mode: self.mode,
            padding: self.padding,
            key: self.key,
            iv: iv
        )
    }
    
    // NOTE: assumes the source stream is already open
    public func createInputStream(
        source innerStream: InputStreamLike,
        operation: Cryptor.Operation,
        iv: Array<UInt8>,
        withCapacity: Int? = nil
    ) -> CipherInputStream {
        let cryptor = self.createCryptor(operation: operation, iv: iv)
        let capacity = withCapacity ?? CIPHER_STREAM_DEFAULT_BLOCK_SIZE
        
        return CipherInputStream(
            cryptor,
            forStream: innerStream,
            initialCapacity: capacity
        )
    }
    
    // NOTE: assumes the source stream is already open
    public func createOutputStream(
        source innerStream: OutputStreamLike,
        operation: Cryptor.Operation,
        iv: Array<UInt8>,
        withCapacity: Int? = nil
    ) -> CipherOutputStream {
        let cryptor = self.createCryptor(operation: operation, iv: iv)
        let capacity = withCapacity ?? CIPHER_STREAM_DEFAULT_BLOCK_SIZE
        
        return CipherOutputStream(
            cryptor,
            forStream: innerStream,
            initialCapacity: capacity
        )
    }
    
    public func openInputStreamDecryptor(
        source innerStream: InputStreamLike,
        withCapacity: Int? = nil
    ) throws -> CipherInputStream {
        
        innerStream.open()
        
        let blockSize = self.algorithm.blockSize()
        
        // slice off the IV from the start of the stream
        var iv = Array<UInt8>(repeating: 0, count: blockSize)
        let bytesRead = innerStream.read(&iv, maxLength: iv.count)
        
        if bytesRead != iv.count {
            innerStream.close()
            throw Error.headerReadFailure
        }
        
        return self.createInputStream(
            source: innerStream,
            operation: .decrypt,
            iv: iv,
            withCapacity: withCapacity
        )
    }
    
    public func openOutputStreamEncryptor(
        source innerStream: OutputStreamLike,
        withCapacity: Int? = nil
    ) throws -> CipherOutputStream {
        
        let blockSize = self.algorithm.blockSize()
        let iv = try Random.generateBytes(byteCount: blockSize)
        
        innerStream.open()
        
        // write IV as the header of the stream so we can decrypt it later
        let bytesWritten = innerStream.writeBytes(iv)
        
        if bytesWritten != iv.count {
            innerStream.close()
            throw Error.headerWriteFailure
        }
        
        return self.createOutputStream(
            source: innerStream,
            operation: .encrypt,
            iv: iv,
            withCapacity: withCapacity
        )
    }
}
