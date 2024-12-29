import ProjectDescription

let project = Project(
    name: "투두팡",
    organizationName: "team1os",
    packages: [
        .remote(
            url: "https://github.com/dkk/WrappingHStack",
            requirement: .upToNextMajor(from: "2.0.0")),
        .remote(
            url: "https://github.com/evgenyneu/keychain-swift",
            requirement: .branch("master")),
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk",
            requirement: .upToNextMajor(from: "11.6.0")),
        .remote(
            url: "https://github.com/google/GoogleSignIn-iOS",
            requirement: .upToNextMajor(from: "8.0.0"))
    ],
    targets: [
        Target(
            name: "투두팡",
            platform: .iOS,
            product: .app,
            bundleId: "com.team1os.teamplan",
            deploymentTarget: .iOS(targetVersion: "16.0", devices: .iphone),
            infoPlist: "teamplan/Info.plist",
            sources: ["teamplan/Sources/**"],
            resources: ["teamplan/Resources/**"],
            scripts: [
                .pre(script: "${PROJECT_DIR}/teamplan/Tools/swiftgen config run --config \"${PROJECT_DIR}/teamplan/Resources/swiftgen.yml\"", name: "Gen")
            ],
            dependencies: [
                .package(product: "WrappingHStack"),
                .package(product: "KeychainSwift"),
                .package(product: "FirebaseAuth"),
                .package(product: "FirebaseAnalytics"),
                .package(product: "GoogleSignIn"),
                .package(product: "GoogleSignInSwift")
            ]
        ),
    ]
)
