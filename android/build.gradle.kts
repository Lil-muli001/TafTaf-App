// Plugins using safeExtGet('compileSdkVersion', 31) in their build.gradle
// read this property and compile against SDK 35 instead of defaulting to 31.
// NOTE: zego_express_engine 3.24.1 hardcodes compileSdkVersion 31 — its
// pub-cache build.gradle must be patched to 35 manually (one-time, per machine):
//   %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\zego_express_engine-3.24.1\android\build.gradle
//   Change: compileSdkVersion 31 → 35, minSdkVersion 16 → 21
extra["compileSdkVersion"] = 35

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
