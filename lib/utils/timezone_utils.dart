import 'package:intl/intl.dart';

/// Utility class for consistent timezone handling across the app
class TimezoneUtils {
  /// Universal method to parse any timestamp and convert to local timezone
  /// This method automatically handles UTC timestamps and converts them to local time
  static DateTime? parseToLocal(dynamic timestamp) {
    if (timestamp == null) return null;
    
    try {
      DateTime parsedDateTime;
      
      if (timestamp is DateTime) {
        // If it's already a DateTime, ensure it's treated as UTC if it doesn't have timezone info
        if (timestamp.isUtc) {
          parsedDateTime = timestamp;
        } else {
          // If it's local time but we expect UTC, convert it
          parsedDateTime = timestamp.toUtc();
        }
      } else if (timestamp is String) {
        String timeString = timestamp.toString().trim();
        
        // Handle different timestamp formats
        if (timeString.endsWith('Z') || timeString.contains('+') || timeString.contains('-')) {
          // Has timezone info - parse directly
          parsedDateTime = DateTime.parse(timeString);
        } else {
          // No timezone info - assume UTC and add Z suffix
          parsedDateTime = DateTime.parse('${timeString}Z');
        }
      } else {
        print('ERROR: Unsupported timestamp type: ${timestamp.runtimeType}');
        return null;
      }
      
      // Convert UTC to local timezone
      final localDateTime = parsedDateTime.toLocal();
      
      // Debug logging can be enabled here if needed
      // print('DEBUG: Parsed timestamp: $timestamp -> UTC: $parsedDateTime -> Local: $localDateTime');
      
      return localDateTime;
    } catch (e) {
      print('ERROR: Failed to parse timestamp: $timestamp, error: $e');
      return null;
    }
  }

  /// Convert UTC DateTime to local timezone for display
  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Convert local DateTime to UTC for storage
  static DateTime toUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Format time for display in 12-hour format with AM/PM
  static String formatTime12Hour(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Format time for display in 24-hour format
  static String formatTime24Hour(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format date for display
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  /// Format date and time for display
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  /// Format time range for display (e.g., "09:00 AM - 05:00 PM")
  static String formatTimeRange(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) return '--:-- - --:--';
    return '${formatTime12Hour(startTime)} - ${formatTime12Hour(endTime)}';
  }

  /// Format time range for display in 24-hour format (e.g., "09:00 - 17:00")
  static String formatTimeRange24Hour(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) return '--:-- - --:--';
    return '${formatTime24Hour(startTime)} - ${formatTime24Hour(endTime)}';
  }

  /// Parse UTC string and convert to local time (legacy method - use parseToLocal instead)
  static DateTime? parseUtcToLocal(String? utcString) {
    return parseToLocal(utcString);
  }

  /// Get current time in UTC
  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Get current time in local timezone
  static DateTime nowLocal() {
    return DateTime.now();
  }

  /// Check if a DateTime is in UTC
  static bool isUtc(DateTime dateTime) {
    return dateTime.isUtc;
  }

  /// Convert timezone-aware string to local DateTime (legacy method - use parseToLocal instead)
  static DateTime? parseTimezoneAware(String? timezoneString) {
    return parseToLocal(timezoneString);
  }

  /// Format duration in hours and minutes
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Calculate duration between two times
  static Duration calculateDuration(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime);
  }

  /// Format duration in decimal hours
  static String formatDurationHours(Duration duration) {
    final hours = duration.inMinutes / 60.0;
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Get current timezone information for debugging
  static Map<String, dynamic> getTimezoneInfo() {
    final now = DateTime.now();
    final utc = now.toUtc();
    final local = now.toLocal();
    
    return {
      'current_local_time': local.toString(),
      'current_utc_time': utc.toString(),
      'timezone_offset': now.timeZoneOffset.toString(),
      'timezone_offset_hours': now.timeZoneOffset.inHours,
      'is_utc': now.isUtc,
    };
  }
}
