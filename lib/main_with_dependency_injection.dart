import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/service_locator.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/trip_provider.dart';
import 'core/providers/budget_provider.dart';
import 'core/providers/destination_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/weather_provider.dart';
import 'core/providers/messaging_provider.dart';
import 'core/providers/review_provider.dart';
import 'core/utils/logger.dart';

/// Main application entry point with proper dependency injection setup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize service locator and all dependencies
    AppLogger.info('Main', 'Setting up dependency injection...');
    await ServiceLocator.setup();
    AppLogger.success('Main', 'All services initialized successfully');
    
    runApp(const RelinkApp());
  } catch (e, stackTrace) {
    AppLogger.error('Main', 'Failed to initialize services', e, stackTrace);
    runApp(const ErrorApp());
  }
}

class RelinkApp extends StatelessWidget {
  const RelinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers with dependency injection
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TripProvider(ServiceLocator.tripService),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(budgetService: ServiceLocator.budgetService),
        ),
        ChangeNotifierProvider(
          create: (_) => DestinationProvider(),
        ),
        
        // Utility providers
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            notificationService: ServiceLocator.notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MessagingProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(),
        ),
        
        // Add other providers as needed
      ],
      child: MaterialApp(
        title: 'Relink',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Error app displayed when dependency injection setup fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relink - Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app or contact support',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Try to reinitialize
                  try {
                    await ServiceLocator.setup();
                    // If successful, navigate to main app (this would need proper navigation)
                  } catch (e) {
                    // Show error again
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home screen that demonstrates provider usage with dependency injection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load initial data using providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final destinationProvider = Provider.of<DestinationProvider>(context, listen: false);
    
    // Load user profile
    userProvider.fetchUserProfile();
    
    // Load user trips
    tripProvider.loadUserTrips();
    
    // Load popular destinations
    destinationProvider.loadPopularDestinations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relink'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<UserProvider, TripProvider, DestinationProvider>(
        builder: (context, userProvider, tripProvider, destinationProvider, child) {
          if (userProvider.isLoading || tripProvider.isLoading || destinationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Welcome Section
                if (userProvider.currentUser != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: userProvider.currentUser!.photoUrl?.isNotEmpty == true
                                ? NetworkImage(userProvider.currentUser!.photoUrl!)
                                : null,
                            child: userProvider.currentUser!.photoUrl?.isEmpty != false
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${userProvider.currentUser!.displayName}!',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  userProvider.currentUser!.email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // My Trips Section
                Text(
                  'My Trips',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (tripProvider.userTrips.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No trips yet. Create your first trip!'),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tripProvider.userTrips.length,
                      itemBuilder: (context, index) {
                        final trip = tripProvider.userTrips[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  trip.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Text(
                                  '${trip.startDate.day}/${trip.startDate.month}/${trip.startDate.year}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Popular Destinations Section
                Text(
                  'Popular Destinations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (destinationProvider.popularDestinations.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No destinations available'),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: destinationProvider.popularDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = destinationProvider.popularDestinations[index];
                        return Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destination.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  destination.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(
                                      destination.rating.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create trip screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Trip feature coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}