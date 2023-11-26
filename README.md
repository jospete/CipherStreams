# CipherStreams

iOS Framework with a high-level API for reading and writing large encrypted files

## Why?

iOS does not seem to have a turn-key solution like the AndroidX [EncryptedFile](https://developer.android.com/reference/androidx/security/crypto/EncryptedFile) API for streaming
large files, encrypted, to the local file system.

This module is an attempt to meet pairity with the `EncryptedFile` counterpart
and get a consistent API between both platforms.

## Installation

Install with cocoapods via git url:

```bash
pod 'CipherStreams', :git => 'https://github.com/jospete/CipherStreams.git', :tag => '0.2.0'
```

See the [Podfile API](https://guides.cocoapods.org/using/the-podfile.html#from-a-podspec-in-the-root-of-a-library-repo) for more info

## Usage

The main feature of this framework is the `AESEncryptedFile` class, which aims to be
an iOS counterpart to the AndroidX `EncryptedFile` API to provide a high-level interface
for writing large amounts of encrypted data to disk.

```swift
import Foundation
import CipherStreams

let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
let cipherFilePath = cacheDirectory.appendingPathComponent("cipher-test.xlog")
let encryptedFile = AESEncryptedFile(cipherFilePath)
let outputStream = try encryptedFile.openOutputStream()

// write some data to the encrypted file
outputStream.writeUtf8("The quick brown fox")
outputStream.writeUtf8(" jumps over the lazy dog.")

// make sure you close the stream when you're done,
// otherwise the data can't be read back!
outputStream.close()

// Read the data back later on
let inputStream = try encryptedFile.openInputStream()
let readText = inputStream.readAllText()

// close the stream after you're done with it
inputStream.close()

print(readText) // "The quick brown fox jumps over the lazy dog."
```