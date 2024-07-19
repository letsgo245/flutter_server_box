import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:server_box/data/model/app/error.dart';
import 'package:server_box/data/res/store.dart';

import '../../data/model/server/server_private_info.dart';

/// Must put this func out of any Class.
///
/// Because of this function is called by [compute].
///
/// https://stackoverflow.com/questions/51998995/invalid-arguments-illegal-argument-in-isolate-message-object-is-a-closure
List<SSHKeyPair> loadIndentity(String key) {
  return SSHKeyPair.fromPem(key);
}

/// [args] : [key, pwd]
String decyptPem(List<String> args) {
  /// skip when the key is not encrypted, or will throw exception
  if (!SSHKeyPair.isEncryptedPem(args[0])) return args[0];
  final sshKey = SSHKeyPair.fromPem(args[0], args[1]);
  return sshKey.first.toPem();
}

enum GenSSHClientStatus {
  socket,
  key,
  pwd,
}

String getPrivateKey(String id) {
  final pki = Stores.key.get(id);
  if (pki == null) {
    throw SSHErr(
      type: SSHErrType.noPrivateKey,
      message: 'key [$id] not found',
    );
  }
  return pki.key;
}

Future<SSHClient> genClient(
  ServerPrivateInfo spi, {
  void Function(GenSSHClientStatus)? onStatus,

  /// Only pass this param if using multi-threading and key login
  String? privateKey,

  /// Only pass this param if using multi-threading and key login
  String? jumpPrivateKey,
  Duration timeout = const Duration(seconds: 5),

  /// [ServerPrivateInfo] of the jump server
  ///
  /// Must pass this param if using multi-threading and key login
  ServerPrivateInfo? jumpSpi,

  /// Handle keyboard-interactive authentication
  FutureOr<List<String>?> Function(SSHUserInfoRequest)? onKeyboardInteractive,
}) async {
  onStatus?.call(GenSSHClientStatus.socket);

  final socket = await () async {
    // Proxy
    final jumpSpi_ = () {
      // Multi-thread or key login
      if (jumpSpi != null) return jumpSpi;
      // Main thread
      if (spi.jumpId != null) return Stores.server.box.get(spi.jumpId);
    }();
    if (jumpSpi_ != null) {
      final jumpClient = await genClient(
        jumpSpi_,
        privateKey: jumpPrivateKey,
        timeout: timeout,
      );

      return await jumpClient.forwardLocal(
        spi.ip,
        spi.port,
      );
    }

    // Direct
    try {
      return await SSHSocket.connect(
        spi.ip,
        spi.port,
        timeout: timeout,
      );
    } catch (e) {
      if (spi.alterUrl == null) rethrow;
      try {
        final ipPort = spi.fromStringUrl();
        return await SSHSocket.connect(
          ipPort.ip,
          ipPort.port,
          timeout: timeout,
        );
      } catch (e) {
        rethrow;
      }
    }
  }();

  final keyId = spi.keyId;
  if (keyId == null) {
    onStatus?.call(GenSSHClientStatus.pwd);
    return SSHClient(
      socket,
      username: spi.user,
      onPasswordRequest: () => spi.pwd,
      onUserInfoRequest: onKeyboardInteractive,
      // printDebug: debugPrint,
      // printTrace: debugPrint,
    );
  }
  privateKey ??= getPrivateKey(keyId);

  onStatus?.call(GenSSHClientStatus.key);
  return SSHClient(
    socket,
    username: spi.user,
    // Must use [compute] here, instead of [Computer.shared.start]
    identities: await compute(loadIndentity, privateKey),
    onUserInfoRequest: onKeyboardInteractive,
    // printDebug: debugPrint,
    // printTrace: debugPrint,
  );
}
