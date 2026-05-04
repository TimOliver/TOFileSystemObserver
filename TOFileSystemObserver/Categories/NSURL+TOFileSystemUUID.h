//
//  NSURL+TOFileSystemUUID.h
//
//  Copyright 2019-2022 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A convenience category that wraps the ability
 to assign a specific extended attribute
 to the file, so we can uniquely track it.

 Thanks to NSHipster for highlighting this technique.
 https://nshipster.com/extended-file-attributes/
 */
@interface NSURL (TOFileSystemUUID)

/** Changes the prefix of the key name under which the UUID is saved.*/
+ (void)to_setKeyNamePrefix:(NSString *)prefix;

/** Returns the unique UUID value assigned to this file. */
- (nullable NSString *)to_fileSystemUUID;

/** Sets a predetermined UUID to be the value of the file. Returns YES if the attribute was written. */
- (BOOL)to_setFileSystemUUID:(NSString *)uuid;

/**
 Sets a UUID only if no UUID attribute is currently present on the file.
 Returns YES if this call wrote the attribute. Returns NO if the attribute
 already exists (another writer won the race) or the write failed for any
 other reason. Callers should re-read with `to_fileSystemUUID` on NO to
 see the canonical on-disk value.
 */
- (BOOL)to_setFileSystemUUIDIfAbsent:(NSString *)uuid;

/** Regardless if one exists, generate and save a new UUID. Returns nil if the write failed. */
- (nullable NSString *)to_generateFileSystemUUID;

@end

NS_ASSUME_NONNULL_END
