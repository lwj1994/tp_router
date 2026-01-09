import 'package:example/routes/nav_keys.dart';
import 'package:example/routes/route.gr.dart';
import 'package:example/widgets/location_display.dart';
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

/// Details page demonstrating custom page transitions and deep linking.
@TpRoute(
  path: '/details',
  transition: TpSlideTransition(),
  transitionDuration: Duration(milliseconds: 500),
  reverseTransitionDuration: Duration(milliseconds: 300),
  parentNavigatorKey: MainHomeNavKey,
)
class DetailsPage extends StatelessWidget {
  final String title;

  @Query()
  final int level;

  const DetailsPage({
    this.title = 'Details',
    this.level = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LocationDisplay(
      navigatorKey: MainNavKey(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('$title (L$level)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => TpRouter.instance.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Level $level',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      DetailsRoute(
                        title: title,
                        level: level + 1,
                      ).tp();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Push Next Level'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      TpRouter.instance.pop(result: 'Result from Level $level');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Pop w/ Result'),
                  ),
                  if (level > 1)
                    ElevatedButton.icon(
                      onPressed: () {
                        TpRouter.instance.popToInitial();
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Pop Until Root'),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This page uses a custom slide transition!\n\n'
                  '• Enter: 500ms with easeInOutQuart curve\n'
                  '• Exit: 300ms with easeOutBack curve (bounce)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
