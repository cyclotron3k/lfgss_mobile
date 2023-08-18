import 'package:flutter/material.dart';

enum DarkMode { system, light, dark }

enum Download { always, wifi, manual }

enum Layout { horizontalSmall, horizontalLarge, vertical }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lights = false;

  DarkMode _theme = DarkMode.system;
  Layout _layout = Layout.horizontalSmall;
  Download _downloadImages = Download.always;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SettingsSectionTitle(title: "Theme"),
          PopupMenuButton(
            initialValue: _theme,
            onSelected: (DarkMode item) {
              setState(() {
                _theme = item;
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
              subtitle: Text(_theme.toString()),
              leading: const Icon(Icons.lightbulb_outline),
            ),
          ),
          PopupMenuButton(
            initialValue: _layout,
            onSelected: (Layout item) {
              setState(() {
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
              subtitle: Text(_layout.toString()),
              leading: const Icon(Icons.dashboard),
            ),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Data"),
          PopupMenuButton(
            initialValue: _downloadImages,
            onSelected: (Download item) {
              setState(() {
                _downloadImages = item;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Download>>[
              const PopupMenuItem<Download>(
                value: Download.always,
                child: Text('Wifi & cellular data'),
              ),
              const PopupMenuItem<Download>(
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
              subtitle: Text(_downloadImages.toString()),
              leading: const Icon(Icons.image),
            ),
          ),
          SwitchListTile(
            title: const Text('Shrink large images'),
            subtitle: const Text(
              'Upload smaller files',
            ),
            value: true,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.photo_size_select_large),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Security & Privacy"),
          SwitchListTile(
            title: const Text('Sanitize images'),
            subtitle: const Text(
              'Strip all EXIF data from uploaded images, including GPS coordinates',
            ),
            value: true,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.hide_image),
          ),
          SwitchListTile(
            title: const Text('Auto download 3rd party data'),
            subtitle: const Text(
              'E.g. Hotlinked images',
            ),
            value: _lights,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.download_for_offline),
          ),
          SwitchListTile(
            title: const Text('Enable Youtube links'),
            value: _lights,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.question_mark),
          ),
          SwitchListTile(
            title: const Text('Embed Twitter links'),
            value: _lights,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.question_mark),
          ),
          const Divider(),
          const SettingsSectionTitle(title: "Notifications"),
          SwitchListTile(
            title: const Text('New comments'),
            subtitle: const Text("in a followed conversation"),
            value: false,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.chat_bubble),
          ),
          SwitchListTile(
            title: const Text('New conversations'),
            subtitle: const Text("in a followed microcosm"),
            value: false,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.forum),
          ),
          SwitchListTile(
            title: const Text('Replies'),
            value: true,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.reply),
          ),
          SwitchListTile(
            title: const Text('Mentions'),
            value: true,
            onChanged: (bool value) {
              setState(() {
                _lights = value;
              });
            },
            secondary: const Icon(Icons.alternate_email),
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
