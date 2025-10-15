import '../../services/supabase_database_service.dart';
import '../../services/notification_service.dart';
import '../../services/budget_service.dart';
import '../../services/trip_service.dart';
import '../../services/user_service.dart';
import '../../services/destination_service.dart';
import '../../services/community_service.dart';
import '../../services/analytics_service.dart';
import '../../services/chat_service.dart';
import '../../services/gallery_service.dart';
import '../../services/friend_service.dart';
import '../../services/itinerary_service.dart';
import '../../services/review_service.dart';
import '../../services/weather_service.dart';
import '../../services/messaging_service.dart';
import '../../services/ai_service.dart';
import '../../services/indonesia_tourism_service.dart';
import '../interfaces/budget_service_interface.dart';
import '../interfaces/trip_service_interface.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../services/interfaces/i_destination_service.dart';
import '../../services/interfaces/i_analytics_service.dart';
import '../../services/interfaces/i_chat_service.dart';
import '../interfaces/i_gallery_service.dart';
import '../interfaces/i_friend_service.dart';
import '../interfaces/i_itinerary_service.dart';
import '../interfaces/i_review_service.dart';
import '../interfaces/i_weather_service.dart';
import '../interfaces/i_ai_service.dart';
import '../interfaces/i_tourism_service.dart';
import '../interfaces/i_community_service.dart';

/// Simple Service Locator for Dependency Injection
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};

  /// Initialize all services and register them in the service locator
  static Future<void> setup() async {
    // Core services first
    
    // Notification Service (singleton pattern)
    _services[NotificationService] = NotificationService.instance;

    // Register service interfaces with their implementations
    
    // Budget Service
    _services[IBudgetService] = BudgetService();

    // Trip Service - with proper dependencies
    _services[ITripService] = TripService();

    // User Service
    _services[IUserService] = UserService();

    // Destination Service (singleton pattern)
    _services[IDestinationService] = DestinationService.instance;

    // Community Service (interface-based injection pattern with parameter compatibility notes)
    final communityService = CommunityService();
    _services[ICommunityService] = communityService;
    _services[CommunityService] = communityService;

    // Additional services
    
    // Gallery Service (instance pattern with interface)
    final galleryService = GalleryService();
    _services[IGalleryService] = galleryService;
    _services[GalleryService] = galleryService;

    // Friend Service (instance pattern with interface)
    final friendService = FriendService();
    _services[IFriendService] = friendService;
    _services[FriendService] = friendService;

    // Itinerary Service (interface-based injection pattern)
    final itineraryService = ItineraryService();
    _services[IItineraryService] = itineraryService;
    _services[ItineraryService] = itineraryService;

    // Review Service (interface-based injection pattern)
    final reviewService = ReviewService();
    _services[IReviewService] = reviewService;
    _services[ReviewService] = reviewService;

    // Weather Service (interface-based injection pattern)
    final weatherService = WeatherService();
    _services[IWeatherService] = weatherService;
    _services[WeatherService] = weatherService;

    // Messaging Service (interface-based injection pattern)
    final messagingService = MessagingService();
    _services[MessagingService] = messagingService;

    // AI Service (interface-based injection pattern)
    final aiService = AIService();
    _services[IAIService] = aiService;
    _services[AIService] = aiService;

    // Indonesia Tourism Service (interface-based injection pattern)
    final tourismService = IndonesiaTourismService();
    _services[ITourismService] = tourismService;
    _services[IndonesiaTourismService] = tourismService;

    // Static-based services (register instances for consistency)
    final analyticsService = AnalyticsService();
    _services[IAnalyticsService] = analyticsService;
    _services[AnalyticsService] = analyticsService;
    
    final chatService = ChatService();
    _services[IChatService] = chatService;
    _services[ChatService] = chatService;
    
    _services[SupabaseDatabaseService] = SupabaseDatabaseService();
  }

  /// Get service instance by type
  static T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered');
    }
    return service as T;
  }

  /// Check if service is registered
  static bool isRegistered<T>() => _services.containsKey(T);

  /// Reset all services (useful for testing)
  static void reset() {
    _services.clear();
  }

  /// Get BudgetService instance
  static IBudgetService get budgetService => get<IBudgetService>();

  /// Get TripService instance
  static ITripService get tripService => get<ITripService>();

  /// Get UserService instance
  static IUserService get userService => get<IUserService>();

  /// Get DestinationService instance
  static IDestinationService get destinationService => get<IDestinationService>();

  /// Get CommunityService instance
  static CommunityService get communityService => get<CommunityService>();

  /// Get ICommunityService instance
  static ICommunityService get iCommunityService => get<ICommunityService>();

  /// Get SupabaseDatabaseService instance  
  static SupabaseDatabaseService get databaseService => get<SupabaseDatabaseService>();

  /// Get NotificationService instance
  static NotificationService get notificationService => get<NotificationService>();

  /// Get ChatService type (for static access) 
  static ChatService get chatService => get<ChatService>();

  /// Get GalleryService interface
  static IGalleryService get iGalleryService => get<IGalleryService>();

  /// Get GalleryService instance
  static GalleryService get galleryService => get<GalleryService>();

  /// Get FriendService interface
  static IFriendService get iFriendService => get<IFriendService>();

  /// Get FriendService instance
  static FriendService get friendService => get<FriendService>();

  /// Get ItineraryService instance
  static ItineraryService get itineraryService => get<ItineraryService>();

  /// Get IItineraryService instance
  static IItineraryService get iItineraryService => get<IItineraryService>();

  /// Get ReviewService instance
  static ReviewService get reviewService => get<ReviewService>();

  /// Get IReviewService instance
  static IReviewService get iReviewService => get<IReviewService>();

  /// Get WeatherService instance
  static WeatherService get weatherService => get<WeatherService>();

  /// Get IWeatherService instance
  static IWeatherService get iWeatherService => get<IWeatherService>();

  /// Get MessagingService instance
  static MessagingService get messagingService => get<MessagingService>();

  /// Get AIService instance
  static AIService get aiService => get<AIService>();

  /// Get IAIService instance
  static IAIService get iAIService => get<IAIService>();

  /// Get IndonesiaTourismService instance
  static IndonesiaTourismService get tourismService => get<IndonesiaTourismService>();

  /// Get ITourismService instance
  static ITourismService get iTourismService => get<ITourismService>();

  /// Get IAnalyticsService instance
  static IAnalyticsService get analyticsService => get<IAnalyticsService>();

  /// Get IChatService instance
  static IChatService get chatServiceInterface => get<IChatService>();
}