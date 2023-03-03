// swift-tools-version:5.0

import PackageDescription

var libPQ: Target {
    #if os(macOS)
    return .systemLibrary(
            name: "Clibpq",
            path: "Sources/CLibpqmac",
            pkgConfig: "libpq",
            providers: [
                .brew(["postgresql", "libpq"]),
            ]
        )
    #else
    return .systemLibrary(
            name: "Clibpq",
            pkgConfig: "libpq",
            providers: [
                .brew(["postgresql", "libpq"]),
                .apt(["libpq-dev"]),
            ]
        )
    #endif
}

let package = Package(
    name: "LibPQ",
    products: [
        .library(name: "Clibpq", targets: ["Clibpq"]),
        .library(name: "LibPQ", targets: ["LibPQ"]),
        .executable(name: "sample", targets: ["sample"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LibPQ",
            dependencies: ["Clibpq"]),
        .target(
            name: "sample",
            dependencies: ["LibPQ"]),
        libPQ,
    ]
)
