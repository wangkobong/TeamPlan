import ProjectDescription

/*
                +-------------+
                |             |
                |     App     | Contains Tuist App target and Tuist unit-test target
                |             |
         +------+-------------+-------+
         |         depends on         |
         |                            |
 +----v-----+                   +-----v-----+
 |          |                   |           |
 |   Kit    |                   |     UI    |   Two independent frameworks to share code and start modularising your app
 |          |                   |           |
 +----------+                   +-----------+

 */

// MARK: - Project

let project = Project(
    name: "teamplan",
    organizationName: "team1os",
    settings: nil,
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
                .external(name: "GoogleSignIn"),
                .external(name: "GoogleSignInSwift"),
                .external(name: "FirebaseAuth"),
                .external(name: "FirebaseFirestore"),
                .external(name: "FirebaseFirestoreSwift"),
            ]
        ),
    ]
)
