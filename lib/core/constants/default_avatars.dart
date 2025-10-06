/// Default avatar options with animal theme
/// Using emoji for visual simplicity and universal compatibility
class DefaultAvatars {
  // 20 animal-themed emoji avatars
  static const List<String> animals = [
    '🐻', // Bear - Strong and protective
    '🦊', // Fox - Clever and adaptable
    '🐼', // Panda - Calm and friendly
    '🐨', // Koala - Relaxed and easygoing
    '🦁', // Lion - Bold and courageous
    '🐯', // Tiger - Fierce and confident
    '🐺', // Wolf - Loyal and independent
    '🦝', // Raccoon - Curious and resourceful
    '🐱', // Cat - Graceful and mysterious
    '🐶', // Dog - Friendly and loyal
    '🐰', // Rabbit - Gentle and quick
    '🦌', // Deer - Elegant and peaceful
    '🦘', // Kangaroo - Energetic and adventurous
    '🐧', // Penguin - Social and playful
    '🦉', // Owl - Wise and observant
    '🦅', // Eagle - Visionary and free
    '🦜', // Parrot - Colorful and expressive
    '🐬', // Dolphin - Intelligent and joyful
    '🦋', // Butterfly - Transformative and beautiful
    '🐝', // Bee - Hardworking and community-minded
  ];

  // Get random avatar
  static String getRandomAvatar() {
    return animals[(DateTime.now().millisecondsSinceEpoch % animals.length)];
  }

  // Get avatar by index
  static String getAvatarByIndex(int index) {
    if (index < 0 || index >= animals.length) {
      return animals[0];
    }
    return animals[index];
  }

  // Get avatar count
  static int get count => animals.length;

  // Check if string is an avatar (emoji format)
  static bool isAvatar(String? value) {
    if (value == null) return false;
    if (value.startsWith('avatar:')) {
      final emoji = value.replaceFirst('avatar:', '');
      return animals.contains(emoji);
    }
    return animals.contains(value);
  }

  // Extract emoji from storage format
  static String? extractEmoji(String? photoUrl) {
    if (photoUrl == null) return null;
    if (photoUrl.startsWith('avatar:')) {
      return photoUrl.replaceFirst('avatar:', '');
    }
    if (animals.contains(photoUrl)) {
      return photoUrl;
    }
    return null;
  }
}
