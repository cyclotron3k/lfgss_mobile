import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings.dart';

enum DarkMode { system, light, dark }

enum Download { always, wifi, manual }

enum Layout { horizontalSmall, horizontalLarge, vertical }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DarkMode _darkMode = DarkMode.system;
  Layout _layout = Layout.horizontalSmall;
  Download _downloadImages = Download.always;

  bool _shrinkLargeImages = true;
  bool _sanitizeImages = true;
  bool _previewUrls = false;
  bool _downloadThirdParty = true;
  bool _embedYouTube = true;
  bool _embedTweets = true;
  bool _notifyNewComments = true;
  bool _notifyNewConversations = true;
  bool _notifyReplies = true;
  bool _notifyMentions = true;
  bool _notifyHuddles = true;

  @override
  void initState() {
    super.initState();
    var settings = Provider.of<Settings>(context, listen: false);

    _darkMode = DarkMode.values.byName(
      settings.getString("darkMode") ?? "system",
    );
    _layout = Layout.values.byName(
      settings.getString("layout") ?? "horizontalSmall",
    );

    _downloadImages = Download.values.byName(
      settings.getString("downloadImages") ?? "always",
    );

    _shrinkLargeImages = settings.getBool("shrinkLargeImages") ?? true;
    _sanitizeImages = settings.getBool("sanitizeImages") ?? true;
    _previewUrls = settings.getBool("previewUrls") ?? false;
    _downloadThirdParty = settings.getBool("downloadThirdParty") ?? true;
    _embedYouTube = settings.getBool("embedYouTube") ?? true;
    _embedTweets = settings.getBool("embedTweets") ?? true;
    _notifyNewComments = settings.getBool("notifyNewComments") ?? true;
    _notifyNewConversations =
        settings.getBool("notifyNewConversations") ?? true;
    _notifyReplies = settings.getBool("notifyReplies") ?? true;
    _notifyMentions = settings.getBool("notifyMentions") ?? true;
    _notifyHuddles = settings.getBool("notifyHuddles") ?? true;
  }

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<Settings>(context, listen: false);
    late SwitchListTile scalingSwitch;
    late SwitchListTile exifSwitch;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SettingsSectionTitle(title: "Theme"),
          PopupMenuButton(
            initialValue: _darkMode,
            onSelected: (DarkMode item) {
              setState(() {
                settings.setString("darkMode", item.name).ignore();
                _darkMode = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<DarkMode>>[
              const PopupMenuItem<DarkMode>(
                value: DarkMode.system,
                child: Text('System'),
              ),
              const PopupMenuItem<DarkMode>(
                value: DarkMode.light,
                child: Text('Light'),
              ),
              const PopupMenuItem<DarkMode>(
                value: DarkMode.dark,
                child: Text('Dark'),
              ),
            ],
            child: ListTile(
              title: const Text('Dark mode'),
              subtitle: Text(_darkMode.name),
              leading: const Icon(Icons.lightbulb_outline),
            ),
          ),
          PopupMenuButton(
            initialValue: _layout,
            onSelected: (Layout item) {
              setState(() {
                settings.setString("layout", item.name).ignore();
                _layout = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Layout>>[
              const PopupMenuItem<Layout>(
                value: Layout.horizontalLarge,
                child: Text('Horizontal (large)'),
              ),
              const PopupMenuItem<Layout>(
                value: Layout.horizontalSmall,
                child: Text('Horizontal (small)'),
              ),
              const PopupMenuItem<Layout>(
                value: Layout.vertical,
                child: Text('Vertical'),
              ),
            ],
            child: ListTile(
              title: const Text('Attachment layout'),
              subtitle: Text(_layout.name),
              leading: const Icon(Icons.dashboard),
            ),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Data"),
          PopupMenuButton(
            initialValue: _downloadImages,
            onSelected: (Download item) {
              setState(() {
                settings.setString("downloadImages", item.name).ignore();
                _downloadImages = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Download>>[
              const PopupMenuItem<Download>(
                value: Download.always,
                child: Text('Wifi & cellular data'),
              ),
              const PopupMenuItem<Download>(
                enabled: false, // TODO
                value: Download.wifi,
                child: Text('Wifi only'),
              ),
              const PopupMenuItem<Download>(
                value: Download.manual,
                child: Text('Manual'),
              ),
            ],
            child: ListTile(
              title: const Text('Download images'),
              subtitle: Text(_downloadImages.name),
              leading: const Icon(Icons.image),
            ),
          ),
          scalingSwitch = SwitchListTile(
            title: const Text('Shrink large images'),
            subtitle: const Text(
              'Upload smaller files',
            ),
            value: _shrinkLargeImages,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("shrinkLargeImages", value).ignore();
                _shrinkLargeImages = value;
              });

              if (!value && exifSwitch.value) {
                exifSwitch.onChanged!(false);
              }
            },
            secondary: const Icon(Icons.photo_size_select_large),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Security & Privacy"),
          exifSwitch = SwitchListTile(
            title: const Text('Sanitize images'),
            subtitle: const Text(
              'Strip all metadata from uploaded photos, including GPS coordinates',
            ),
            value: _sanitizeImages,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("sanitizeImages", value).ignore();
                _sanitizeImages = value;

                if (_sanitizeImages && !scalingSwitch.value) {
                  scalingSwitch.onChanged!(true);
                }
              });
            },
            secondary: const Icon(Icons.hide_image),
          ),
          SwitchListTile(
            title: const Text('Preview URLs'),
            subtitle: const Text(
              'Preview URLs before following',
            ),
            value: _previewUrls,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("previewUrls", value).ignore();
                _previewUrls = value;
              });
            },
            secondary: const Icon(Icons.manage_search),
          ),
          SwitchListTile(
            title: const Text('Auto download 3rd party data'),
            subtitle: const Text(
              'E.g. Hotlinked images',
            ),
            value: _downloadThirdParty,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("downloadThirdParty", value).ignore();
                _downloadThirdParty = value;
              });
            },
            secondary: const Icon(Icons.download_for_offline),
          ),
          SwitchListTile(
            title: const Text('Embed YouTube videos'),
            value: _embedYouTube,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("embedYouTube", value).ignore();
                _embedYouTube = value;
              });
            },
            secondary: const Icon(Icons.smart_display),
          ),
          SwitchListTile(
            title: const Text('Embed tweets'),
            value: _embedTweets,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("embedTweets", value).ignore();
                _embedTweets = value;
              });
            },
            secondary: const Icon(Icons.chat_bubble),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Notifications"),
          SwitchListTile(
            title: const Text('Direct messages (huddles)'),
            value: _notifyHuddles,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("notifyHuddles", value).ignore();
                _notifyHuddles = value;
              });
            },
            secondary: const Icon(Icons.email),
          ),
          SwitchListTile(
            title: const Text('Replies'),
            value: _notifyReplies,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("notifyReplies", value).ignore();
                _notifyReplies = value;
              });
            },
            secondary: const Icon(Icons.reply),
          ),
          SwitchListTile(
            title: const Text('Mentions'),
            value: _notifyMentions,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("notifyMentions", value).ignore();
                _notifyMentions = value;
              });
            },
            secondary: const Icon(Icons.alternate_email),
          ),
          SwitchListTile(
            title: const Text('New comments'),
            subtitle: const Text("in a followed conversation"),
            value: _notifyNewComments,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("notifyNewComments", value).ignore();
                _notifyNewComments = value;
              });
            },
            secondary: const Icon(Icons.chat_bubble),
          ),
          SwitchListTile(
            title: const Text('New conversations'),
            subtitle: const Text("in a followed microcosm"),
            value: _notifyNewConversations,
            onChanged: (bool value) {
              setState(() {
                settings.setBool("notifyNewConversations", value).ignore();
                _notifyNewConversations = value;
              });
            },
            secondary: const Icon(Icons.forum),
          ),
        ],
      ),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
