import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox/core/extension/colorx.dart';
import 'package:toolbox/core/extension/locale.dart';
import 'package:toolbox/core/extension/context.dart';
import 'package:toolbox/core/extension/stringx.dart';
import 'package:toolbox/core/persistant_store.dart';
import 'package:toolbox/core/route.dart';
import 'package:toolbox/data/model/app/net_view.dart';
import 'package:toolbox/view/widget/input_field.dart';
import 'package:toolbox/view/widget/value_notifier.dart';

import '../../../core/utils/misc.dart';
import '../../../core/utils/platform.dart';
import '../../../core/update.dart';
import '../../../core/utils/ui.dart';
import '../../../data/provider/app.dart';
import '../../../data/provider/server.dart';
import '../../../data/res/build_data.dart';
import '../../../data/res/color.dart';
import '../../../data/res/path.dart';
import '../../../data/res/ui.dart';
import '../../../data/store/server.dart';
import '../../../data/store/setting.dart';
import '../../../locator.dart';
import '../../widget/custom_appbar.dart';
import '../../widget/future_widget.dart';
import '../../widget/round_rect_card.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _themeKey = GlobalKey<PopupMenuButtonState<int>>();
  //final _startPageKey = GlobalKey<PopupMenuButtonState<int>>();
  final _updateIntervalKey = GlobalKey<PopupMenuButtonState<int>>();
  final _maxRetryKey = GlobalKey<PopupMenuButtonState<int>>();
  final _localeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _editorThemeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _editorDarkThemeKey = GlobalKey<PopupMenuButtonState<String>>();
  final _keyboardTypeKey = GlobalKey<PopupMenuButtonState<int>>();
  final _rotateQuarterKey = GlobalKey<PopupMenuButtonState<int>>();
  final _netViewTypeKey = GlobalKey<PopupMenuButtonState<NetViewType>>();

  late final SettingStore _setting;
  late final ServerProvider _serverProvider;
  late S _s;
  late SharedPreferences _sp;

  final _selectedColorValue = ValueNotifier(0);
  final _launchPageIdx = ValueNotifier(0);
  final _nightMode = ValueNotifier(0);
  final _maxRetryCount = ValueNotifier(0);
  final _updateInterval = ValueNotifier(0);
  final _termFontSize = ValueNotifier(0.0);
  final _editorFontSize = ValueNotifier(0.0);
  final _localeCode = ValueNotifier('');
  final _editorTheme = ValueNotifier('');
  final _editorDarkTheme = ValueNotifier('');
  final _keyboardType = ValueNotifier(0);
  final _rotateQuarter = ValueNotifier(0);
  final _netViewType = ValueNotifier(NetViewType.speed);

  final _pushToken = ValueNotifier<String?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
    final localeSettingVal = _setting.locale.fetch();
    if (localeSettingVal.isEmpty) {
      _localeCode.value = _s.localeName;
    } else {
      _localeCode.value = localeSettingVal;
    }
  }

  @override
  void initState() {
    super.initState();
    _serverProvider = locator<ServerProvider>();
    _setting = locator<SettingStore>();
    _launchPageIdx.value = _setting.launchPage.fetch();
    _nightMode.value = _setting.themeMode.fetch();
    _updateInterval.value = _setting.serverStatusUpdateInterval.fetch();
    _maxRetryCount.value = _setting.maxRetryCount.fetch();
    _selectedColorValue.value = _setting.primaryColor.fetch();
    _termFontSize.value = _setting.termFontSize.fetch();
    _editorFontSize.value = _setting.editorFontSize.fetch();
    _editorTheme.value = _setting.editorTheme.fetch();
    _editorDarkTheme.value = _setting.editorDarkTheme.fetch();
    _keyboardType.value = _setting.keyboardType.fetch();
    _rotateQuarter.value = _setting.fullScreenRotateQuarter.fetch();
    _netViewType.value = _setting.netViewType.fetch();
    SharedPreferences.getInstance().then((value) => _sp = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(_s.setting),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        children: [
          _buildTitle('App'),
          _buildApp(),
          _buildTitle(_s.server),
          _buildServer(),
          _buildTitle('SSH'),
          _buildSSH(),
          _buildTitle(_s.editor),
          _buildEditor(),
          _buildTitle(_s.fullScreen),
          _buildFullScreen(),
          const SizedBox(height: 37),
        ],
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 23, bottom: 17),
      child: Center(
        child: Text(
          text,
          style: grey,
        ),
      ),
    );
  }

  Widget _buildApp() {
    final children = [
      _buildLocale(),
      _buildThemeMode(),
      _buildAppColor(),
      //_buildLaunchPage(),
      _buildCheckUpdate(),
    ];
    if (isIOS) {
      children.add(_buildPushToken());
      children.add(_buildAutoUpdateHomeWidget());
    }
    if (isAndroid) {
      children.add(_buildBgRun());
      children.add(_buildAndroidWidgetSharedPreference());
    }
    return Column(
      children: children.map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildFullScreen() {
    return Column(
      children: [
        _buildFullScreenSwitch(),
        _buildFullScreenJitter(),
        _buildFulScreenRotateQuarter(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildServer() {
    return Column(
      children: [
        _buildMoveOutServerFuncBtns(),
        _buildServerOrder(),
        _buildServerDetailOrder(),
        _buildNetViewType(),
        _buildUpdateInterval(),
        _buildMaxRetry(),
        _buildDiskIgnorePath(),
        _buildDeleteServers(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildSSH() {
    return Column(
      children: [
        _buildFont(),
        _buildTermFontSize(),
        _buildSSHVirtualKeyAutoOff(),
        // Use hardware keyboard on desktop, so there is no need to set it
        if (isMobile) _buildKeyboardType(),
        _buildSSHVirtKeys(),
        _buildSftpRmrfDir(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        _buildEditorFontSize(),
        _buildEditorTheme(),
        _buildEditorDarkTheme(),
      ].map((e) => RoundRectCard(e)).toList(),
    );
  }

  Widget _buildCheckUpdate() {
    return Consumer<AppProvider>(
      builder: (ctx, app, __) {
        String display;
        if (app.newestBuild != null) {
          if (app.newestBuild! > BuildData.build) {
            display = _s.versionHaveUpdate(app.newestBuild!);
          } else {
            display = _s.versionUpdated(BuildData.build);
          }
        } else {
          display = _s.versionUnknownUpdate(BuildData.build);
        }
        return ListTile(
          title: Text(_s.autoCheckUpdate),
          subtitle: Text(display, style: grey),
          onTap: () => doUpdate(ctx, force: true),
          trailing: buildSwitch(context, _setting.autoCheckAppUpdate),
        );
      },
    );
  }

  Widget _buildUpdateInterval() {
    final items = List.generate(
      10,
      (index) => PopupMenuItem(
        value: index,
        child: Text('$index ${_s.second}'),
      ),
      growable: false,
    ).toList();

    return ListTile(
      title: Text(
        _s.updateServerStatusInterval,
      ),
      subtitle: Text(
        _s.willTakEeffectImmediately,
        style: grey,
      ),
      onTap: () {
        _updateIntervalKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _updateInterval,
        build: () => PopupMenuButton(
          key: _updateIntervalKey,
          itemBuilder: (_) => items,
          initialValue: _updateInterval.value,
          onSelected: (int val) {
            _updateInterval.value = val;
            _setting.serverStatusUpdateInterval.put(val);
            _serverProvider.startAutoRefresh();
            if (val == 0) {
              showSnackBar(context, Text(_s.updateIntervalEqual0));
            }
          },
          child: Text(
            '${_updateInterval.value} ${_s.second}',
            style: textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildAppColor() {
    return ListTile(
      trailing: ClipOval(
        child: Container(
          color: primaryColor,
          height: 27,
          width: 27,
        ),
      ),
      title: Text(_s.primaryColorSeed),
      onTap: () async {
        final ctrl = TextEditingController(text: primaryColor.toHex);
        await showRoundDialog(
          context: context,
          title: Text(_s.primaryColorSeed),
          child: Input(
            autoFocus: true,
            onSubmitted: _onSaveColor,
            controller: ctrl,
            hint: '#8b2252',
            icon: Icons.colorize,
          ),
        );
      },
    );
  }

  void _onSaveColor(String s) {
    final color = s.hexToColor;
    if (color == null) {
      showSnackBar(context, Text(_s.failed));
      return;
    }
    _selectedColorValue.value = color.value;
    _setting.primaryColor.put(_selectedColorValue.value);
    context.pop();
    _showRestartSnackbar();
  }

  // Widget _buildLaunchPage() {
  //   final items = AppTab.values
  //       .map(
  //         (e) => PopupMenuItem(
  //           value: e.index,
  //           child: Text(tabTitleName(context, e)),
  //         ),
  //       )
  //       .toList();

  //   return ListTile(
  //     title: Text(
  //       _s.launchPage,
  //     ),
  //     onTap: () {
  //       _startPageKey.currentState?.showButtonMenu();
  //     },
  //     trailing: ValueBuilder(
  //       listenable: _launchPageIdx,
  //       build: () => PopupMenuButton(
  //         key: _startPageKey,
  //         itemBuilder: (BuildContext context) => items,
  //         initialValue: _launchPageIdx.value,
  //         onSelected: (int idx) {
  //           _launchPageIdx.value = idx;
  //           _setting.launchPage.put(_launchPageIdx.value);
  //         },
  //         child: ConstrainedBox(
  //           constraints: BoxConstraints(maxWidth: _media.size.width * 0.35),
  //           child: Text(
  //             tabTitleName(context, AppTab.values[_launchPageIdx.value]),
  //             textAlign: TextAlign.right,
  //             style: textSize15,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildMaxRetry() {
    final items = List.generate(
      10,
      (index) => PopupMenuItem(
        value: index,
        child: Text('$index ${_s.times}'),
      ),
      growable: false,
    ).toList();
    final help =
        _maxRetryCount.value == 0 ? _s.maxRetryCountEqual0 : _s.canPullRefresh;

    return ListTile(
      title: Text(
        _s.maxRetryCount,
        textAlign: TextAlign.start,
      ),
      subtitle: Text(help, style: grey),
      onTap: () {
        _maxRetryKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        build: () => PopupMenuButton(
          key: _maxRetryKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _maxRetryCount.value,
          onSelected: (int val) {
            _maxRetryCount.value = val;
            _setting.maxRetryCount.put(_maxRetryCount.value);
          },
          child: Text(
            '${_maxRetryCount.value} ${_s.times}',
            style: textSize15,
          ),
        ),
        listenable: _maxRetryCount,
      ),
    );
  }

  Widget _buildThemeMode() {
    final items = ThemeMode.values
        .map(
          (e) => PopupMenuItem(
            value: e.index,
            child: Text(_buildThemeModeStr(e.index)),
          ),
        )
        .toList();
    // Issue #57
    final len = ThemeMode.values.length;
    items.add(PopupMenuItem(value: len, child: Text(_buildThemeModeStr(len))));

    return ListTile(
      title: Text(
        _s.themeMode,
      ),
      onTap: () {
        _themeKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _nightMode,
        build: () => PopupMenuButton(
          key: _themeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _nightMode.value,
          onSelected: (int idx) {
            _nightMode.value = idx;
            _setting.themeMode.put(_nightMode.value);
          },
          child: Text(
            _buildThemeModeStr(_nightMode.value),
            style: textSize15,
          ),
        ),
      ),
    );
  }

  String _buildThemeModeStr(int n) {
    switch (n) {
      case 1:
        return _s.light;
      case 2:
        return _s.dark;
      case 3:
        return 'AMOLED';
      default:
        return _s.auto;
    }
  }

  Widget _buildPushToken() {
    return ListTile(
      title: Text(
        _s.pushToken,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.zero,
        onPressed: () {
          if (_pushToken.value != null) {
            copy2Clipboard(_pushToken.value!);
            showSnackBar(context, Text(_s.success));
          } else {
            showSnackBar(context, Text(_s.getPushTokenFailed));
          }
        },
      ),
      subtitle: FutureWidget<String?>(
        future: getToken(),
        loading: Text(_s.gettingToken),
        error: (error, trace) => Text('${_s.error}: $error'),
        noData: Text(_s.nullToken),
        success: (text) {
          _pushToken.value = text;
          return Text(
            text ?? _s.nullToken,
            style: grey,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        },
      ),
    );
  }

  Widget _buildFont() {
    final fontName = getFileName(_setting.fontPath.fetch());
    return ListTile(
      title: Text(_s.font),
      trailing: Text(
        fontName ?? _s.notSelected,
        style: textSize15,
      ),
      onTap: () {
        showRoundDialog(
          context: context,
          title: Text(_s.font),
          actions: [
            TextButton(
              onPressed: () async => await _pickFontFile(),
              child: Text(_s.pickFile),
            ),
            TextButton(
              onPressed: () {
                _setting.fontPath.delete();
                context.pop();
                _showRestartSnackbar();
              },
              child: Text(_s.clear),
            )
          ],
        );
      },
    );
  }

  Future<void> _pickFontFile() async {
    final path = await pickOneFile();
    if (path != null) {
      // iOS can't copy file to app dir, so we need to use the original path
      if (isIOS) {
        _setting.fontPath.put(path);
      } else {
        final fontDir_ = await fontDir;
        final fontFile = File(path);
        final newPath = '${fontDir_.path}/${path.split('/').last}';
        await fontFile.copy(newPath);
        _setting.fontPath.put(newPath);
      }

      context.pop();
      _showRestartSnackbar();
      return;
    }
    showSnackBar(context, Text(_s.failed));
  }

  void _showRestartSnackbar() {
    showSnackBarWithAction(
      context,
      '${_s.success}\n${_s.needRestart}',
      _s.restart,
      () => rebuildAll(context),
    );
  }

  Widget _buildBgRun() {
    return ListTile(
      title: Text(_s.bgRun),
      trailing: buildSwitch(context, _setting.bgRun),
    );
  }

  Widget _buildTermFontSize() {
    return ValueBuilder(
      listenable: _termFontSize,
      build: () => ListTile(
        title: Text(_s.fontSize),
        trailing: Text(
          _termFontSize.value.toString(),
          style: textSize15,
        ),
        onTap: () => _showFontSizeDialog(_termFontSize, _setting.termFontSize),
      ),
    );
  }

  Widget _buildDiskIgnorePath() {
    final paths = _setting.diskIgnorePath.fetch();
    return ListTile(
      title: Text(_s.diskIgnorePath),
      trailing: Text(_s.edit, style: textSize15),
      onTap: () {
        final ctrller = TextEditingController(text: json.encode(paths));
        void onSubmit() {
          try {
            final list = List<String>.from(json.decode(ctrller.text));
            _setting.diskIgnorePath.put(list);
            context.pop();
            showSnackBar(context, Text(_s.success));
          } catch (e) {
            showSnackBar(context, Text(e.toString()));
          }
        }

        showRoundDialog(
          context: context,
          title: Text(_s.diskIgnorePath),
          child: Input(
            autoFocus: true,
            controller: ctrller,
            label: 'JSON',
            type: TextInputType.visiblePassword,
            maxLines: 3,
            onSubmitted: (_) => onSubmit(),
          ),
          actions: [
            TextButton(onPressed: onSubmit, child: Text(_s.ok)),
          ],
        );
      },
    );
  }

  Widget _buildLocale() {
    final items = S.supportedLocales
        .map(
          (e) => PopupMenuItem<String>(
            value: e.name,
            child: Text(e.name),
          ),
        )
        .toList();
    return ListTile(
      title: Text(_s.language),
      onTap: () {
        _localeKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _localeCode,
        build: () => PopupMenuButton(
          key: _localeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _localeCode.value,
          onSelected: (String idx) {
            _localeCode.value = idx;
            _setting.locale.put(idx);
            _showRestartSnackbar();
          },
          child: Text(
            _s.languageName,
            style: textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildSSHVirtualKeyAutoOff() {
    return ListTile(
      title: Text(_s.sshVirtualKeyAutoOff),
      subtitle: const Text('Ctrl & Alt', style: grey),
      trailing: buildSwitch(context, _setting.sshVirtualKeyAutoOff),
    );
  }

  Widget _buildEditorTheme() {
    final items = themeMap.keys.map(
      (key) {
        return PopupMenuItem<String>(
          value: key,
          child: Text(key),
        );
      },
    ).toList();
    return ListTile(
      title: Text('${_s.light} ${_s.theme.toLowerCase()}'),
      trailing: ValueBuilder(
        listenable: _editorTheme,
        build: () => PopupMenuButton(
          key: _editorThemeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _editorTheme.value,
          onSelected: (String idx) {
            _editorTheme.value = idx;
            _setting.editorTheme.put(idx);
          },
          child: Text(
            _editorTheme.value,
            style: textSize15,
          ),
        ),
      ),
      onTap: () {
        _editorThemeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildEditorDarkTheme() {
    final items = themeMap.keys.map(
      (key) {
        return PopupMenuItem<String>(
          value: key,
          child: Text(key),
        );
      },
    ).toList();
    return ListTile(
      title: Text('${_s.dark} ${_s.theme.toLowerCase()}'),
      trailing: ValueBuilder(
        listenable: _editorDarkTheme,
        build: () => PopupMenuButton(
          key: _editorDarkThemeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _editorDarkTheme.value,
          onSelected: (String idx) {
            _editorDarkTheme.value = idx;
            _setting.editorDarkTheme.put(idx);
          },
          child: Text(
            _editorDarkTheme.value,
            style: textSize15,
          ),
        ),
      ),
      onTap: () {
        _editorDarkThemeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildFullScreenSwitch() {
    return ListTile(
      title: Text(_s.fullScreen),
      trailing: buildSwitch(
        context,
        _setting.fullScreen,
        func: (_) => _showRestartSnackbar(),
      ),
    );
  }

  Widget _buildFullScreenJitter() {
    return ListTile(
      title: Text(_s.fullScreenJitter),
      subtitle: Text(_s.fullScreenJitterHelp, style: grey),
      trailing: buildSwitch(context, _setting.fullScreenJitter),
    );
  }

  Widget _buildFulScreenRotateQuarter() {
    final degrees = List.generate(4, (idx) => '${idx * 90}°').toList();
    final items = List.generate(4, (idx) {
      return PopupMenuItem<int>(
        value: idx,
        child: Text(degrees[idx]),
      );
    }).toList();

    return ListTile(
      title: Text(_s.rotateAngel),
      onTap: () {
        _rotateQuarterKey.currentState?.showButtonMenu();
      },
      trailing: ValueBuilder(
        listenable: _rotateQuarter,
        build: () => PopupMenuButton(
          key: _rotateQuarterKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _rotateQuarter.value,
          onSelected: (int idx) {
            _rotateQuarter.value = idx;
            _setting.fullScreenRotateQuarter.put(idx);
          },
          child: Text(
            degrees[_rotateQuarter.value],
            style: textSize15,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardType() {
    const List<String> names = <String>[
      'text',
      'multiline',
      'number',
      'phone',
      'datetime',
      'emailAddress',
      'url',
      'visiblePassword',
      'name',
      'address',
      'none',
    ];
    if (names.length != TextInputType.values.length) {
      // This notify me to update the code
      throw Exception('names.length != TextInputType.values.length');
    }
    final items = TextInputType.values.map(
      (key) {
        return PopupMenuItem<int>(
          value: key.index,
          child: Text(names[key.index]),
        );
      },
    ).toList();
    return ListTile(
      title: Text(_s.keyboardType),
      subtitle: Text(_s.keyboardCompatibility, style: grey),
      trailing: ValueBuilder(
        listenable: _keyboardType,
        build: () => PopupMenuButton<int>(
          key: _keyboardTypeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _keyboardType.value,
          onSelected: (idx) {
            _keyboardType.value = idx;
            _setting.keyboardType.put(idx);
          },
          child: Text(
            names[_keyboardType.value],
            style: textSize15,
          ),
        ),
      ),
      onTap: () {
        _keyboardTypeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildSSHVirtKeys() {
    return ListTile(
      title: Text(_s.editVirtKeys),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.sshVirtKeySetting().go(context),
    );
  }

  void _saveWidgetSP(String data, Map<String, String> old) {
    context.pop();
    try {
      final map = Map<String, String>.from(json.decode(data));
      final keysDel = old.keys.toSet().difference(map.keys.toSet());
      for (final key in keysDel) {
        _sp.remove(key);
      }
      map.forEach((key, value) {
        _sp.setString(key, value);
      });
      showSnackBar(context, Text(_s.success));
    } catch (e) {
      showSnackBar(context, Text(e.toString()));
    }
  }

  Widget _buildAndroidWidgetSharedPreference() {
    return ListTile(
      title: Text(_s.homeWidgetUrlConfig),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () {
        final data = <String, String>{};
        _sp.getKeys().forEach((key) {
          final val = _sp.getString(key);
          if (val != null) {
            data[key] = val;
          }
        });
        final ctrl = TextEditingController(text: json.encode(data));
        showRoundDialog(
          context: context,
          title: Text(_s.homeWidgetUrlConfig),
          child: Input(
            autoFocus: true,
            controller: ctrl,
            label: 'JSON',
            type: TextInputType.visiblePassword,
            maxLines: 7,
            onSubmitted: (p0) => _saveWidgetSP(p0, data),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _saveWidgetSP(ctrl.text, data);
              },
              child: Text(_s.ok),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetViewType() {
    final items = NetViewType.values
        .map((e) => PopupMenuItem(
              value: e,
              child: Text(e.l10n(_s)),
            ))
        .toList();
    return ListTile(
      title: Text(_s.netViewType),
      trailing: ValueBuilder(
        listenable: _netViewType,
        build: () => PopupMenuButton<NetViewType>(
          key: _netViewTypeKey,
          itemBuilder: (BuildContext context) => items,
          initialValue: _netViewType.value,
          onSelected: (idx) {
            _netViewType.value = idx;
            _setting.netViewType.put(idx);
          },
          child: Text(
            _netViewType.value.l10n(_s),
            style: textSize15,
          ),
        ),
      ),
      onTap: () {
        _netViewTypeKey.currentState?.showButtonMenu();
      },
    );
  }

  Widget _buildAutoUpdateHomeWidget() {
    return ListTile(
      title: Text(_s.autoUpdateHomeWidget),
      subtitle: Text(_s.whenOpenApp, style: grey),
      trailing: buildSwitch(context, _setting.autoUpdateHomeWidget),
    );
  }

  Widget _buildDeleteServers() {
    return ListTile(
      title: Text(_s.deleteServers),
      trailing: const Icon(Icons.delete_forever),
      onTap: () async {
        final all = locator<ServerStore>().box.keys.map(
              (e) => TextButton(
                onPressed: () => showRoundDialog(
                  context: context,
                  title: Text(_s.attention),
                  child: Text(_s.sureDelete(e)),
                  actions: [
                    TextButton(
                      onPressed: () => _serverProvider.delServer(e),
                      child: Text(_s.ok),
                    )
                  ],
                ),
                child: Text(e),
              ),
            );
        showRoundDialog<List<String>>(
          context: context,
          title: Text(_s.choose),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: all.toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoveOutServerFuncBtns() {
    return ListTile(
      title: Text(_s.moveOutServerFuncBtns),
      subtitle: Text(_s.moveOutServerFuncBtnsHelp, style: textSize13Grey),
      trailing: buildSwitch(context, _setting.moveOutServerTabFuncBtns),
    );
  }

  Widget _buildServerOrder() {
    return ListTile(
      title: Text(_s.serverOrder),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.serverOrder().go(context),
    );
  }

  Widget _buildServerDetailOrder() {
    return ListTile(
      title: Text(_s.serverDetailOrder),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => AppRoute.serverDetailOrder().go(context),
    );
  }

  Widget _buildEditorFontSize() {
    return ValueBuilder(
      listenable: _editorFontSize,
      build: () => ListTile(
        title: Text(_s.fontSize),
        trailing: Text(
          _editorFontSize.value.toString(),
          style: textSize15,
        ),
        onTap: () =>
            _showFontSizeDialog(_editorFontSize, _setting.editorFontSize),
      ),
    );
  }

  void _showFontSizeDialog(
    ValueNotifier<double> notifier,
    StorePropertyBase<double> property,
  ) {
    final ctrller = TextEditingController(text: notifier.value.toString());
    void onSave() {
      context.pop();
      final fontSize = double.tryParse(ctrller.text);
      if (fontSize == null) {
        showRoundDialog(
          context: context,
          title: Text(_s.failed),
          child: Text('Parsed failed: ${ctrller.text}'),
        );
        return;
      }
      notifier.value = fontSize;
      property.put(fontSize);
    }

    showRoundDialog(
      context: context,
      title: Text(_s.fontSize),
      child: Input(
        controller: ctrller,
        autoFocus: true,
        type: TextInputType.number,
        icon: Icons.font_download,
        onSubmitted: (_) => onSave(),
      ),
      actions: [
        TextButton(
          onPressed: onSave,
          child: Text(_s.ok),
        ),
      ],
    );
  }

  Widget _buildSftpRmrfDir() {
    return ListTile(
      title: Text(_s.sftpRmrfDir),
      trailing: buildSwitch(context, _setting.sftpRmrfDir),
    );
  }
}