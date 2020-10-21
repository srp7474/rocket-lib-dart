%echo off
echo uses rocket_lib dartdoc to generate the documentation package
set flutter_root=D:\pgms\flutter-1-20\flutter
call %flutter_root%\bin\cache\dart-sdk\bin\dartdoc --no-link-to-remote --enable-experiment no-extension-methods

rem call %flutter_root%\bin\cache\dart-sdk\bin\dartdoc
echo ***** copying files *********
xcopy doc\api H:\data\gael-home\war\docs\rocket-lib\api /SY
