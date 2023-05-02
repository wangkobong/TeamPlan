//
//  Dependencies.swift
//  TeamPlan_forkManifests
//
//  Created by 주찬혁 on 2023/05/02.
//

import ProjectDescription

let packages: [Package] = [
    .package(url: "https://github.com/google/GoogleSignIn-iOS", .upToNextMajor(from: "7.0.0")),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", .upToNextMajor(from: "9.0.0"))
]

let dependencies = Dependencies(
    swiftPackageManager: .init(packages),
    platforms: [.iOS]
)
