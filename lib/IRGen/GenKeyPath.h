//===--- GenBuiltin.h - IR generation for builtin functions -----*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  This file provides the private interface to the emission of KeyPath
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IRGEN_GENKEYPATH_H
#define SWIFT_IRGEN_GENKEYPATH_H

#include "Address.h"
#include "swift/AST/SubstitutionMap.h"
#include "swift/Basic/LLVM.h"
#include "swift/SIL/SILValue.h"
#include "llvm/IR/Value.h"

namespace swift {
  class BuiltinInfo;
  class BuiltinInst;
  class Identifier;
  class KeyPathPattern;

namespace irgen {
  class Explosion;
  class IRGenFunction;
  class StackAddress;

  class KeyPathArgumentEmission {
    IRGenFunction &IGF;
    const KeyPathPattern &pattern;
  public:
    KeyPathArgumentEmission(IRGenFunction &IGF, const KeyPathPattern &pattern)
        : IGF(IGF), pattern(pattern) {}
    llvm::Value *begin(SubstitutionMap subs, ArrayRef<Operand> indiceOperands);
    void emitArgument();
  };
  llvm::Value *getKeyPathInstantiationArgument(
      IRGenFunction &IGF, SubstitutionMap subs,
      ArrayRef<Operand> indiceOperands, const KeyPathPattern *pattern,
      std::function<Address(SILValue)> getLoweredAddress,
      std::function<Explosion(SILValue)> getLoweredExplosion,
      Optional<StackAddress> &dynamicArgsBuf);
} // end namespace irgen
} // end namespace swift

#endif
