//===--- _SwiftCxxInteroperability.h - C++ Interop support ------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  Defines types and support functions required by C++ bindings generated
//  by the Swift compiler that allow C++ code to call Swift APIs.
//
//===----------------------------------------------------------------------===//
#ifndef SWIFT_CXX_INTEROPERABILITY_H
#define SWIFT_CXX_INTEROPERABILITY_H

#ifdef __cplusplus

#include <cstdint>
#include <stdlib.h>
#if defined(_WIN32)
#include <malloc.h>
#endif

namespace swift {
namespace _impl {

inline void *_Nonnull opaqueAlloc(size_t size, size_t align) noexcept {
#if defined(_WIN32)
  void *r = _aligned_malloc(size, align);
#else
  if (align < sizeof(void *))
    align = sizeof(void *);
  void *r = nullptr;
  int res = posix_memalign(&r, align, size);
  (void)res;
#endif
  return r;
}

inline void opaqueFree(void *_Nonnull p) noexcept {
#if defined(_WIN32)
  _aligned_free(p);
#else
  free(p);
#endif
}

} // namespace _impl

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++17-extensions"

/// True if the given type is a Swift type that can be used in a generic context
/// in Swift.
template <class T>
static inline const constexpr bool isUsableInGenericContext = false;

#pragma clang diagnostic pop

/// Returns the type metadat for the given Swift type T.
template <class T> inline void *_Nonnull getTypeMetadata();

} // namespace swift
#endif

#endif // SWIFT_CXX_INTEROPERABILITY_H
