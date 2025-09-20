/// Utility class for handling UTC timestamps consistently across the application
class UtcTimestampHelper {
  /// Get current UTC timestamp in milliseconds since epoch
  static int getCurrentUtcTimestamp() {
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }

  /// Get current UTC DateTime
  static DateTime getCurrentUtcDateTime() {
    return DateTime.now().toUtc();
  }

  /// Parse server timestamp string to UTC DateTime
  /// Handles both ISO string format and milliseconds since epoch
  static DateTime? parseServerTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    try {
      if (timestamp is String) {
        // Try parsing as ISO string first
        if (timestamp.contains('T') || timestamp.contains('Z')) {
          return DateTime.parse(timestamp).toUtc();
        }
        // Try parsing as milliseconds string
        final ms = int.tryParse(timestamp);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms).toUtc();
        }
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc();
      } else if (timestamp is double) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).toUtc();
      }
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
    
    return null;
  }

  /// Parse local timestamp from database (always in milliseconds since epoch)
  static DateTime? parseLocalTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    try {
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc();
      } else if (timestamp is String) {
        final ms = int.tryParse(timestamp);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms).toUtc();
        }
      }
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
    
    return null;
  }

  /// Compare two timestamps and return which is newer
  /// Returns:
  /// - positive if first is newer
  /// - negative if second is newer  
  /// - zero if they are equal
  /// - null if either timestamp is null
  static int? compareTimestamps(DateTime? first, DateTime? second) {
    if (first == null || second == null) return null;
    
    return first.toUtc().compareTo(second.toUtc());
  }

  /// Check if local timestamp is newer than server timestamp
  /// Returns true if local is newer, false if server is newer or equal, null if either is null
  static bool? isLocalNewer(DateTime? localTimestamp, DateTime? serverTimestamp) {
    final comparison = compareTimestamps(localTimestamp, serverTimestamp);
    if (comparison == null) return null;
    return comparison > 0;
  }

  /// Format timestamp for display in UI
  static String formatForDisplay(DateTime? timestamp) {
    if (timestamp == null) return 'Nunca';
    
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Hace menos de un minuto';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${local.day}/${local.month}/${local.year}';
    }
  }

  /// Format timestamp for detailed display (includes time)
  static String formatDetailed(DateTime? timestamp) {
    if (timestamp == null) return 'Nunca';
    
    final local = timestamp.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
           '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Create a UTC timestamp from local components (for testing)
  static DateTime createUtcTimestamp(int year, int month, int day, [int hour = 0, int minute = 0, int second = 0]) {
    return DateTime.utc(year, month, day, hour, minute, second);
  }
}