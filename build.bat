@echo off
set "JAVA_HOME=C:\Users\Namikaz\scoop\apps\openjdk17\current"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "ANDROID_HOME=C:\Users\Namikaz\AppData\Local\Android\Sdk"
set "ANDROID_SDK_ROOT=C:\Users\Namikaz\AppData\Local\Android\Sdk"
cd /d "%~dp0"
java -cp "gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain :app:assembleDebug