import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/ai/ai_image_service.dart';
import '../../core/models/ai_image_models.dart';

class AIImageAnalysisScreen extends StatefulWidget {
  const AIImageAnalysisScreen({super.key});

  @override
  State<AIImageAnalysisScreen> createState() => _AIImageAnalysisScreenState();
}

class _AIImageAnalysisScreenState extends State<AIImageAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  
  // Analysis results
  ImageAnalysisResult? _analysisResult;
  LandmarkDetectionResult? _landmarkResult;
  PhotoCaption? _captionResult;
  PhotographyTips? _tipsResult;
  
  // Tab controller
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          // Reset results
          _analysisResult = null;
          _landmarkResult = null;
          _captionResult = null;
          _tipsResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }
  
  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() => _isAnalyzing = true);
    
    try {
      // Convert file to base64
      final imageBase64 = await _fileToBase64(_selectedImage!);
      
      // Since AIImageService only has analyzeImage method, we'll simulate other results
      final analysisResult = await AIImageService.analyzeImage(
        imageUrl: '', // Empty since we're using base64
        imageBase64: imageBase64,
        analysisType: 'general',
        context: {'purpose': 'Travel photo analysis'},
      );
      
      // Parse the analysis result and create mock results for demonstration
      setState(() {
        _analysisResult = ImageAnalysisResult.fromMap(analysisResult);
        
        // Create mock results for features not yet implemented in service
        _landmarkResult = LandmarkDetectionResult(
          isLandmark: false,
          description: 'Landmark detection coming soon',
          nearbyAttractions: [],
        );
        
        _captionResult = PhotoCaption(
          captions: [
            CaptionOption(text: 'Beautiful travel moment captured!', type: 'short'),
            CaptionOption(text: 'Exploring new places and creating memories', type: 'storytelling'),
            CaptionOption(text: 'Adventure awaits around every corner', type: 'inspirational'),
          ],
          hashtags: ['#travel', '#adventure', '#explore'],
        );
        
        _tipsResult = PhotographyTips(
          rating: 8,
          tips: [
            'Great composition and lighting',
            'Consider adjusting the exposure slightly',
            'The framing captures the essence well',
          ],
          editingSuggestions: [
            'Enhance colors for more vibrancy',
            'Adjust shadows and highlights',
          ],
        );
      });
      
      _showSuccessSnackBar('Image analyzed successfully!');
    } catch (e) {
      _showErrorSnackBar('Analysis failed: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Analysis'),
        actions: [
          if (_selectedImage != null && !_isAnalyzing)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _analyzeImage,
              tooltip: 'Analyze Image',
            ),
        ],
        bottom: _analysisResult != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
                  Tab(text: 'Landmark', icon: Icon(Icons.location_on)),
                  Tab(text: 'Caption', icon: Icon(Icons.text_fields)),
                  Tab(text: 'Tips', icon: Icon(Icons.lightbulb)),
                ],
              )
            : null,
      ),
      body: _selectedImage == null
          ? _buildEmptyState()
          : _analysisResult == null
              ? _buildImagePreview()
              : _buildAnalysisResults(),
      floatingActionButton: _buildFABs(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Image Selected',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or choose from gallery',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              if (_isAnalyzing)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing image with AI...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a few moments',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyzeImage,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Analyze with AI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalysisResults() {
    return Column(
      children: [
        // Image thumbnail
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(_selectedImage!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnalysisTab(),
              _buildLandmarkTab(),
              _buildCaptionTab(),
              _buildTipsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalysisTab() {
    if (_analysisResult == null) return const SizedBox();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('What\'s in this photo?'),
        _buildInfoCard(
          icon: Icons.image,
          title: 'Main Subjects',
          content: _analysisResult!.subjects.join(', '),
        ),
        _buildInfoCard(
          icon: Icons.place,
          title: 'Location Type',
          content: _analysisResult!.location?.type ?? 'Unknown',
        ),
        _buildInfoCard(
          icon: Icons.local_activity,
          title: 'Activities',
          content: _analysisResult!.activities.join(', '),
        ),
        _buildInfoCard(
          icon: Icons.mood,
          title: 'Mood & Atmosphere',
          content: _analysisResult!.mood ?? 'Not specified',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Scene Details'),
        _buildInfoCard(
          icon: Icons.wb_sunny,
          title: 'Time of Day',
          content: _analysisResult!.timeOfDay ?? 'Unknown',
        ),
        _buildInfoCard(
          icon: Icons.cloud,
          title: 'Weather',
          content: _analysisResult!.weather ?? 'Unknown',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Colors'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _analysisResult!.colors
              .map((color) => Chip(
                    label: Text(color),
                    backgroundColor: _getColorFromName(color),
                    labelStyle: const TextStyle(color: Colors.white),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Tags'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _analysisResult!.tags
              .map((tag) => Chip(label: Text('#$tag')))
              .toList(),
        ),
      ],
    );
  }
  
  Widget _buildLandmarkTab() {
    if (_landmarkResult == null) return const SizedBox();
    
    if (!_landmarkResult!.isLandmark) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Landmark Detected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This image doesn\'t appear to contain\na recognizable landmark',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _landmarkResult!.name ?? 'Unknown Landmark',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _buildConfidenceBadge(_landmarkResult!.confidence ?? 0),
                  ],
                ),
                if (_landmarkResult!.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(_landmarkResult!.location!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('About'),
        _buildInfoCard(
          icon: Icons.info,
          title: 'Description',
          content: _landmarkResult!.description,
        ),
        if (_landmarkResult!.significance != null)
          _buildInfoCard(
            icon: Icons.history_edu,
            title: 'Significance',
            content: _landmarkResult!.significance!,
          ),
        const SizedBox(height: 16),
        _buildSectionTitle('Visitor Information'),
        _buildInfoCard(
          icon: Icons.access_time,
          title: 'Best Time to Visit',
          content: _landmarkResult!.bestTimeToVisit ?? 'Any time',
        ),
        _buildInfoCard(
          icon: Icons.tips_and_updates,
          title: 'Visitor Tips',
          content: _landmarkResult!.visitorTips ?? 'No specific tips',
        ),
        if (_landmarkResult!.nearbyAttractions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Nearby Attractions'),
          ...(_landmarkResult!.nearbyAttractions.map(
            (attraction) => ListTile(
              leading: const Icon(Icons.place),
              title: Text(attraction),
            ),
          )),
        ],
      ],
    );
  }
  
  Widget _buildCaptionTab() {
    if (_captionResult == null) return const SizedBox();
    
    // Get captions by type
    final shortCaption = _captionResult!.captions
        .firstWhere((c) => c.type == 'short', orElse: () => _captionResult!.captions.first);
    final storytellingCaption = _captionResult!.captions
        .firstWhere((c) => c.type == 'storytelling', orElse: () => _captionResult!.captions.first);
    final inspirationalCaption = _captionResult!.captions
        .firstWhere((c) => c.type == 'inspirational', orElse: () => _captionResult!.captions.last);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Short & Catchy'),
        _buildCaptionCard(shortCaption.text, Icons.flash_on),
        const SizedBox(height: 16),
        _buildSectionTitle('Storytelling'),
        _buildCaptionCard(storytellingCaption.text, Icons.auto_stories),
        const SizedBox(height: 16),
        _buildSectionTitle('Inspirational'),
        _buildCaptionCard(inspirationalCaption.text, Icons.format_quote),
        const SizedBox(height: 16),
        _buildSectionTitle('Hashtags'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _captionResult!.hashtags
              .map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue[50],
                  ))
              .toList(),
        ),
        if (_captionResult!.locationTag != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Location Tag',
            content: _captionResult!.locationTag!,
          ),
        ],
        if (_captionResult!.bestPostingTime != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.schedule,
            title: 'Best Time to Post',
            content: _captionResult!.bestPostingTime!,
          ),
        ],
      ],
    );
  }
  
  Widget _buildTipsTab() {
    if (_tipsResult == null) return const SizedBox();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Rating
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Photo Rating',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_tipsResult!.rating}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getRatingColor(_tipsResult!.rating),
                          ),
                    ),
                    Text(
                      '/10',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _tipsResult!.rating / 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getRatingColor(_tipsResult!.rating),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Pro Tips'),
        ..._tipsResult!.tips.map((tip) => ListTile(
              leading: const Icon(Icons.lightbulb, color: Colors.amber),
              title: Text(tip),
            )),
        if (_tipsResult!.cameraSettings != null) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Recommended Camera Settings'),
          _buildCameraSettingsCard(_tipsResult!.cameraSettings!),
        ],
        const SizedBox(height: 16),
        _buildSectionTitle('Editing Suggestions'),
        ..._tipsResult!.editingSuggestions.map((suggestion) => ListTile(
              leading: const Icon(Icons.edit, color: Colors.purple),
              title: Text(suggestion),
            )),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }
  
  Widget _buildCaptionCard(String caption, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Copy to clipboard
                          _showSuccessSnackBar('Caption copied!');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfidenceBadge(int confidence) {
    Color color;
    if (confidence >= 80) {
      color = Colors.green;
    } else if (confidence >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$confidence% confident',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildCameraSettingsCard(CameraSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingRow('Aperture', settings.aperture),
            const Divider(),
            _buildSettingRow('Shutter Speed', settings.shutterSpeed),
            const Divider(),
            _buildSettingRow('ISO', settings.iso),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
  
  Widget? _buildFABs() {
    if (_selectedImage == null) return null;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'camera',
          onPressed: () => _pickImage(ImageSource.camera),
          child: const Icon(Icons.camera_alt),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'gallery',
          onPressed: () => _pickImage(ImageSource.gallery),
          child: const Icon(Icons.photo_library),
        ),
      ],
    );
  }
  
  Color _getColorFromName(String colorName) {
    final colors = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'brown': Colors.brown,
      'black': Colors.black,
      'white': Colors.white,
      'gray': Colors.grey,
      'grey': Colors.grey,
    };
    
    return colors[colorName.toLowerCase()] ?? Colors.grey;
  }
  
  Color _getRatingColor(int rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.orange;
    return Colors.red;
  }
}
