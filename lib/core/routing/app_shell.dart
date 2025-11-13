import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  /// The navigation shell (provided by StatefulShellRoute)
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is now the navigation shell itself
      body: navigationShell,
      
      bottomNavigationBar: BottomNavigationBar(
        // FIX: Explicitly set the type to 'fixed' to prevent the "invisible"
        // background issue that occurs with 4 or more items.
        type: BottomNavigationBarType.fixed,
        // Get the current index from the shell
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Use the shell's 'goBranch' method to switch tabs
          navigationShell.goBranch(
            index,
            // if clicking the same tab, go to the initial location
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer), // New icon for Focus
            label: 'Focus',
          ),
        ],
      ),
    );
  }
}