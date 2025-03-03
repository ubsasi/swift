// RUN: %empty-directory(%t)
// RUN: mkdir -p %t/clang-module-cache

// Run the scanner once, emitting the serialized scanner cache
// RUN: %target-swift-frontend -scan-dependencies -Rdependency-scan-cache -serialize-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/clang-module-cache %s -o %t/deps_initial.json -I %S/Inputs/CHeaders -I %S/Inputs/Swift -import-objc-header %S/Inputs/CHeaders/Bridging.h -swift-version 4 2>&1 | %FileCheck %s -check-prefix CHECK-REMARK-SAVE

// Run the scanner again, but now re-using previously-serialized cache
// RUN: %target-swift-frontend -scan-dependencies -Rdependency-scan-cache -load-dependency-scan-cache -dependency-scan-cache-path %t/cache.moddepcache -module-cache-path %t/clang-module-cache %s -o %t/deps.json -I %S/Inputs/CHeaders -I %S/Inputs/Swift -import-objc-header %S/Inputs/CHeaders/Bridging.h -swift-version 4 2>&1 | %FileCheck %s -check-prefix CHECK-REMARK-LOAD

// Check the contents of the JSON output
// RUN: %FileCheck %s < %t/deps.json

// REQUIRES: executable_test
// REQUIRES: objc_interop

import C
import E
import G
import SubE

// CHECK-REMARK-SAVE: remark: Serializing module scanning dependency cache to:
// CHECK-REMARK-LOAD: remark: Re-using serialized module scanning dependency cache from:

// CHECK: "mainModuleName": "deps"

/// --------Main module
// CHECK-LABEL: "modulePath": "deps.swiftmodule",
// CHECK-NEXT: sourceFiles
// CHECK-NEXT: module_deps_cache_reuse.swift
// CHECK-NEXT: ],
// CHECK-NEXT: "directDependencies": [
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "A"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "clang": "C"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "E"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "F"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "G"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "SubE"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "Swift"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "SwiftOnoneSupport"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "_Concurrency"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "_StringProcessing"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "_cross_import_E"
// CHECK-NEXT:   }
// CHECK-NEXT: ],

// CHECK:      "extraPcmArgs": [
// CHECK-NEXT:    "-Xcc",
// CHECK-NEXT:    "-target",
// CHECK-NEXT:    "-Xcc",
// CHECK:         "-fapinotes-swift-version=4"
// CHECK-NOT: "error: cannot open Swift placeholder dependency module map from"
// CHECK: "bridgingHeader":
// CHECK-NEXT: "path":
// CHECK-SAME: Bridging.h

// CHECK-NEXT: "sourceFiles":
// CHECK-NEXT: Bridging.h
// CHECK-NEXT: BridgingOther.h

// CHECK: "moduleDependencies": [
// CHECK-NEXT: "F"
// CHECK-NEXT: ]

/// --------Swift module A
// CHECK-LABEL: "modulePath": "A.swiftmodule",

// CHECK: directDependencies
// CHECK-NEXT: {
// CHECK-NEXT:   "clang": "A"
// CHECK-NEXT: }
// CHECK-NEXT: {
// CHECK-NEXT:   "swift": "Swift"
// CHECK-NEXT: },

/// --------Clang module C
// CHECK-LABEL: "modulePath": "C.pcm",

// CHECK: "sourceFiles": [
// CHECK-DAG: module.modulemap
// CHECK-DAG: C.h

// CHECK: directDependencies
// CHECK-NEXT: {
// CHECK-NEXT: "clang": "B"

// CHECK: "moduleMapPath"
// CHECK-SAME: module.modulemap

// CHECK: "contextHash"
// CHECK-SAME: "{{.*}}"

// CHECK: "commandLine": [
// CHECK-NEXT: "-frontend"
// CHECK-NEXT: "-only-use-extra-clang-opts
// CHECK-NOT: "BUILD_DIR/bin/clang"
// CHECK-NEXT: "-Xcc"
// CHECK-NEXT: "-fsyntax-only",
// CHECK:      "-fsystem-module",
// CHECK-NEXT: "-emit-pcm",
// CHECK-NEXT: "-module-name",
// CHECK-NEXT: "C"

/// --------Swift module E
// CHECK: "swift": "E"
// CHECK-LABEL: modulePath": "E.swiftmodule"
// CHECK: "directDependencies"
// CHECK-NEXT: {
// CHECK-NEXT: "swift": "Swift"

// CHECK: "moduleInterfacePath"
// CHECK-SAME: E.swiftinterface

/// --------Swift module F
// CHECK:      "modulePath": "F.swiftmodule",
// CHECK-NEXT: "sourceFiles": [
// CHECK-NEXT: ],
// CHECK-NEXT: "directDependencies": [
// CHECK-NEXT:   {
// CHECK-NEXT:     "clang": "F"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "Swift"
// CHECK-NEXT:   },
// CHECK-NEXT:   {
// CHECK-NEXT:     "swift": "SwiftOnoneSupport"
// CHECK-NEXT:   }
// CHECK-NEXT: ],

/// --------Swift module G
// CHECK-LABEL: "modulePath": "G.swiftmodule"
// CHECK: "directDependencies"
// CHECK-NEXT: {
// CHECK-NEXT:   "clang": "G"
// CHECK-NEXT: },
// CHECK-NEXT: {
// CHECK-NEXT:   "swift": "Swift"
// CHECK-NEXT: },
// CHECK-NEXT: {
// CHECK-NEXT:   "swift": "SwiftOnoneSupport"
// CHECK-NEXT: }
// CHECK-NEXT: ],
// CHECK-NEXT: "details": {

// CHECK: "contextHash": "{{.*}}",
// CHECK: "commandLine": [
// CHECK: "-compile-module-from-interface"
// CHECK: "-target"
// CHECK: "-module-name"
// CHECK: "G"
// CHECK: "-swift-version"
// CHECK: "5"
// CHECK: ],
// CHECK" "extraPcmArgs": [
// CHECK"   "-target",
// CHECK"   "-fapinotes-swift-version=5"
// CHECK" ]

/// --------Swift module Swift
// CHECK-LABEL: "modulePath": "Swift.swiftmodule",

// CHECK: directDependencies
// CHECK-NEXT: {
// CHECK-NEXT: "clang": "SwiftShims"

/// --------Clang module B
// CHECK-LABEL: "modulePath": "B.pcm"

// CHECK-NEXT: sourceFiles
// CHECK-DAG: module.modulemap
// CHECK-DAG: B.h

// CHECK: directDependencies
// CHECK-NEXT: {
// CHECK-NEXT: "clang": "A"
// CHECK-NEXT: }

/// --------Clang module SwiftShims
// CHECK-LABEL: "modulePath": "SwiftShims.pcm",
