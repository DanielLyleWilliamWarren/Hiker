import 'package:flutter/material.dart';
import 'package:hiker/map/map_screen.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryEarth),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Hiker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Define your different screens/pages
  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    MapScreen(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryEarth,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Home Tab - Your original counter screen
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryEarth,
        foregroundColor: AppColors.primaryWhite,
        title: const Text('Hiker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.hiking, size: 80, color: AppColors.primaryStone),
            const SizedBox(height: 20),
            Text(
              'Welcome to Hiker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryEarth,
              ),
            ),
            // const SizedBox(height: 40),
            // const Text('You have pushed the button this many times:'),
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            //     color: AppColors.primaryEarth,
            //   ),
            // ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   backgroundColor: AppColors.secondaryGrass,
      //   foregroundColor: AppColors.primaryWhite,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

// Profile Tab - Placeholder
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryEarth,
        foregroundColor: AppColors.primaryWhite,
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 100, color: AppColors.monoGrey3),
            const SizedBox(height: 20),
            Text(
              'Profile Page',
              style: TextStyle(fontSize: 24, color: AppColors.primaryEarth),
            ),
            const SizedBox(height: 10),
            Text(
              'Coming soon...',
              style: TextStyle(fontSize: 16, color: AppColors.monoGrey4),
            ),
          ],
        ),
      ),
    );
  }
}
