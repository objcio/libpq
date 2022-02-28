// swift-tools-version:5.0

import PackageDescription

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
	    .systemLibrary(
		    name: "Clibpq",
			pkgConfig: "libpq",
            providers: [
                .brew(["postgresql"]),
                .apt(["libpq-dev"]),
            ]
		),
    ]
)
