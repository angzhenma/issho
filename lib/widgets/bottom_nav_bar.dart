import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showFAB;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showFAB = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: kBottomNavigationBarHeight,
        child: Row(
          children: [
            // Left side icons
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.people_rounded,
                      color: currentIndex == 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () => onTap(0),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      color: currentIndex == 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () => onTap(1),
                  ),
                ],
              ),
            ),
            // Right side icons
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_rounded,
                      color: currentIndex == 2
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () => onTap(2),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: currentIndex == 3
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () => onTap(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
