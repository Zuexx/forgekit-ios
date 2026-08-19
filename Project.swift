import ProjectDescription

// Renaming a generated product happens here and nowhere else. Everything below derives from
// these two lines — which is the whole reason this project is a Swift manifest rather than a
// checked-in .pbxproj, where the same rename means editing dozens of internal references.
let appName = "ForgeKit"
let bundleIdPrefix = "com.zuexx"

let project = Project(
    name: appName,
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundleIdPrefix).\(appName.lowercased())",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": ""],
                "CFBundleDisplayName": .string(appName),
            ]),
            sources: ["Sources/**"],
            resources: []
        ),
        .target(
            name: "\(appName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundleIdPrefix).\(appName.lowercased()).tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: appName)]
        ),
    ]
)
