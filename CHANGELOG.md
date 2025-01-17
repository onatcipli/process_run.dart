# Changelog

## 0.10.3

* now the userEnvironment is used by default in shell. Use platformEnvironment for the raw environment.
* add shell run command to run a command with user loaded vars and paths
* add `userLoadConfigFile` to load any `.yaml` file
* add `getFlutterVersion`

## 0.10.2

* add `shell` binary allowing editing the environment file on MacOS/Windows and Linux

## 0.10.1

* add `userPaths` and `userEnvironment` access and allow overriding for finding executable and passing env variable
to callee

## 0.10.0

* feat: add Shell class and features
* try to resolve single command everywhere

## 0.9.0

* fix: which now returns the full path on linux

## 0.8.0

* Deprecate old commands helper dartCmd, pubCmd... to use constructors instead
  (DartCmd, PubCmd...)
* Add webdev and pbr command 

## 0.7.0

* add flutter command support
* add Windows support
* add which utility

## 0.6.0

* dart2 support

## 0.5.6

* supports `implicit-casts: false`

## 0.5.5

* when using io.stdout and io.stderr, flush them when running a command

## 0.5.4

* Fix handling of stdin

## 0.5.2

* fix dart2js to have a libraryRoot argument
* add dartdevc

## 0.5.1

* fix devRun

## 0.5.0

* deprecated connectStdout and connectStrerr in ProcessCmd
* add stdin, stdout, verbose and commandVerbose parameter for run

## 0.4.0

* add stdin and deprecated buggy connectStdin

## 0.3.3

* add argumentToString to handle basic quote or double quote

## 0.3.2

* fix dartdoc to add --packages argument along with the snapshot

## 0.3.0

* Add runCmd (cmd_run library)

## 0.2.0

* Add ProcessCmd

## 0.1.0

* Initial version, run and dartbin utilities
