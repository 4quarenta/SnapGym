from pathlib import Path

path = Path("android/app/build.gradle.kts")
text = path.read_text(encoding="utf-8")

text = text.replace(
    'applicationId = "com.snapgym.snapgym"',
    'applicationId = "com.snapgym.app"',
)

marker = "    buildTypes {\n"
flavors = '''    flavorDimensions += "environment"\n\n    productFlavors {\n        create("dev") {\n            dimension = "environment"\n            applicationIdSuffix = ".dev"\n            versionNameSuffix = "-dev"\n        }\n        create("staging") {\n            dimension = "environment"\n            applicationIdSuffix = ".staging"\n            versionNameSuffix = "-staging"\n        }\n        create("prod") {\n            dimension = "environment"\n        }\n    }\n\n'''

if 'flavorDimensions += "environment"' not in text:
    if marker not in text:
        raise RuntimeError("Could not locate Android buildTypes block.")
    text = text.replace(marker, flavors + marker, 1)

path.write_text(text, encoding="utf-8")
