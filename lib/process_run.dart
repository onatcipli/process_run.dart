///
/// Helper to run a process and connect the input/output for verbosity
///
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:process_run/src/shell_utils.dart' as utils;
import 'package:process_run/src/user_config.dart';

import 'src/common/import.dart';

export 'src/dev_process_run.dart';

/// Helper to run a process and connect the input/output for verbosity
///

/// Helper to run a process and connect the input/output for verbosity
///

///
/// Returns `true` if [rune] represents a whitespace character.
///
/// The definition of whitespace matches that used in [String.trim] which is
/// based on Unicode 6.2. This maybe be a different set of characters than the
/// environment's [RegExp] definition for whitespace, which is given by the
/// ECMAScript standard: http://ecma-international.org/ecma-262/5.1/#sec-15.10
///
/// from quiver
///
bool _isWhitespace(int rune) => ((rune >= 0x0009 && rune <= 0x000D) ||
    rune == 0x0020 ||
    rune == 0x0085 ||
    rune == 0x00A0 ||
    rune == 0x1680 ||
    rune == 0x180E ||
    (rune >= 0x2000 && rune <= 0x200A) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202F ||
    rune == 0x205F ||
    rune == 0x3000 ||
    rune == 0xFEFF);

/// Use to safely enclose an argument if needed
///
/// argument must not be null
String argumentToString(String argument) {
  bool hasWhitespace = false;
  int singleQuoteCount = 0;
  int doubleQuoteCount = 0;
  if (argument.isEmpty) {
    return '""';
  }
  for (int rune in argument.runes) {
    if ((!hasWhitespace) && (_isWhitespace(rune))) {
      hasWhitespace = true;
    } else if (rune == 0x0027) {
      // '
      singleQuoteCount++;
    } else if (rune == 0x0022) {
      // "
      doubleQuoteCount++;
    }
  }
  if (singleQuoteCount > 0) {
    if (doubleQuoteCount > 0) {
      // simply escape all double quotes
      argument = '"${argument.replaceAll('"', '\\"')}"';
    } else {
      argument = '"$argument"';
    }
  } else if (doubleQuoteCount > 0) {
    argument = "'$argument'";
  } else if (hasWhitespace) {
    argument = '"$argument"';
  }
  return argument;
}

/// Convert multiple arguments to string than can be used in a terminal
String argumentsToString(List<String> arguments) {
  List<String> argumentStrings = [];
  for (String argument in arguments) {
    argumentStrings.add(argumentToString(argument));
  }
  return argumentStrings.join(' ');
}

/// Convenient way to display a command
String executableArgumentsToString(String executable, List<String> arguments) {
  StringBuffer sb = StringBuffer();
  if (Platform.isWindows) {
    var ext = extension(executable);
    switch (ext) {
      case '.exe':
      case '.bat':
      case '.cmd':
      case '.com':
        executable = executable.substring(0, executable.length - 4);
    }
  }
  sb.write(executable);
  if (arguments is List && arguments.isNotEmpty) {
    sb.write(" ${argumentsToString(arguments)}");
  }
  return sb.toString();
}

///
/// if [commmandVerbose] or [verbose] is true, display the command.
/// if [verbose] is true, stream stdout & stdin
Future<ProcessResult> run(String executable, List<String> arguments,
    {String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
    Stream<List<int>> stdin,
    StreamSink<List<int>> stdout,
    StreamSink<List<int>> stderr,
    bool verbose,
    bool commandVerbose}) async {
  // enforce default
  includeParentEnvironment ??= true;
  //stdoutEncoding ??= SYSTEM_ENCODING;
  //stderrEncoding ??= SYSTEM_ENCODING;

  if (verbose == true) {
    commandVerbose = true;
    stdout ??= io.stdout;
    stderr ??= io.stderr;
  }

  if (commandVerbose == true) {
    utils.streamSinkWriteln(stdout ?? io.stdout,
        "\$ ${executableArgumentsToString(executable, arguments)}");
  }

  // Filter out environment
  // to remove vm_services
  if (includeParentEnvironment != false) {
    if (environment == null) {
      environment = userEnvironment;
    }
    includeParentEnvironment = false;
  }

  // Fix runInShell on windows
  runInShell = utils.fixRunInShell(runInShell, executable);

  // Default is the full command
  String executableShortName = executable;
  // Find executable if needed, i.e. if it is only a name
  if (basename(executable) == executable) {
    executableShortName = executable;
    // Try to find it in path or use it as is
    executable = utils.findExecutableSync(executable, userPaths) ?? executable;
  }

  Process process;
  try {
    process = await Process.start(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell);
  } catch (e) {
    if (verbose == true) {
      io.stderr.writeln(e);
      io.stderr.writeln(
          "\$ ${executableArgumentsToString(executableShortName, arguments)}");
      io.stderr.writeln("workingDirectory: $workingDirectory");
    }
    rethrow;
  }

  StreamController<List<int>> outCtlr = StreamController(sync: true);
  StreamController<List<int>> errCtlr = StreamController(sync: true);

  // Connected stdin
  // Buggy!
  if (stdin != null) {
    //stdin.pipe(process.stdin); // this closes the stream...
    stdin.listen((List<int> data) {
      process.stdin.add(data);
    })
      ..onDone(() {
        process.stdin.close();
      });
    // OLD 2: process.stdin.addStream(stdin);
  } else {
    // Close the input sync, we want this not interractive
    //process.stdin.close();
  }

  Future<dynamic> streamToResult(
      Stream<List<int>> stream, Encoding encoding) async {
    List<int> list = [];
    await for (List<int> data in stream) {
      //devPrint('s: ${data}');
      list.addAll(data);
    }
    if (encoding != null) {
      return encoding.decode(list);
    }
    return list;
  }

  var out = streamToResult(outCtlr.stream, stdoutEncoding);
  var err = streamToResult(errCtlr.stream, stderrEncoding);

  process.stdout.listen((List<int> d) {
    if (stdout != null) {
      stdout.add(d);
    }
    outCtlr.add(d);
  }, onDone: () {
    outCtlr.close();
  });

  process.stderr.listen((List<int> d) async {
    if (stderr != null) {
      stderr.add(d);
    }
    errCtlr.add(d);
  }, onDone: () {
    errCtlr.close();
  });

  int exitCode = await process.exitCode;

  // Notice that exitCode can complete before all of the lines of output have been
  // processed. Also note that we do not explicitly close the process. In order
  // to not leak resources we have to drain both the stderr and the stdout streams.
  // To do that we set a listener (using await for) to drain the stderr stream.
  //await process.stdout.drain();
  //await process.stderr.drain();

  ProcessResult result =
      ProcessResult(process.pid, exitCode, await out, await err);

  if (stdin != null) {
    //process.stdin.close();
  }

  // flush for consistency
  if (stdout == io.stdout) {
    await io.stdout.flush();
  }
  if (stderr == io.stderr) {
    await io.stderr.flush();
  }

  return result;
}
