import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/category_row.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Classic FLauncher grid, wrapped as a standalone page pushed on top of
/// the simple Kiosk home. Reachable from the corner cluster.
class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('All Apps'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Consumer<AppsService>(
          builder: (context, appsService, _) {
            if (!appsService.initialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ContinueWatchingRow(),
                  ..._sections(context, appsService.launcherSections),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, List<LauncherSection> sections) {
    final settings = context.read<SettingsService>();
    final watchNext = context.read<WatchNextService>();
    final continueWatchingActive =
        settings.showContinueWatching && watchNext.programs.isNotEmpty;

    final children = <Widget>[];
    bool firstCategoryFound = continueWatchingActive;

    for (final section in sections) {
      final key = Key(section.id.toString());
      if (section is LauncherSpacer) {
        children.add(SizedBox(key: key, height: section.height.toDouble()));
        continue;
      }
      final category = section as Category;
      final isFirst = !firstCategoryFound;
      if (isFirst) firstCategoryFound = true;

      Widget widget;
      switch (category.type) {
        case CategoryType.row:
          widget = CategoryRow(
            key: key,
            category: category,
            applications: category.applications,
            isFirstSection: isFirst,
          );
          break;
        case CategoryType.grid:
          widget = AppsGrid(
            key: key,
            category: category,
            applications: category.applications,
            isFirstSection: isFirst,
          );
          break;
      }
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: widget,
      ));
    }
    return children;
  }
}
