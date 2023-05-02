import ProjectDescription

let project = Project(
    name: "teamplan",
    organizationName: "team1os",
    packages: [
        .remote(
            url: "https://github.com/google/GoogleSignIn-iOS",
            requirement: .upToNextMajor(from: "7.0.0")),
        .remote(
            url: "https://github.com/firebase/firebase-ios-sdk",
            requirement: .upToNextMajor(from: "9.0.0"))
    ],
    targets: [
        Target(
            name: "teamplan",
            platform: .iOS,
            product: .app,
            bundleId: "com.team1os.teamplan",
            infoPlist: "teamplan/Info.plist",
            sources: ["teamplan/Sources/**"],
            resources: ["teamplan/Resources/**"],
            dependencies: [
                .package(product: "GoogleSignIn"),
                .package(product: "GoogleSignInSwift"),
                .package(product: "FirebaseAuth"),
                .package(product: "FirebaseFirestore"),
                .package(product: "FirebaseFirestoreSwift"),
            ]
        ),
    ]
)
