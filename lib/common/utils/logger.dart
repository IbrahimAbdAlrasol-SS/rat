import 'dart:developer' as developer;

void logJson(String json) {
  developer.log(json, name: 'NotificationWatcher');
}

void logInfo(String message) {
  developer.log(message, name: 'NotificationWatcher', level: 800);
}

void logError(String message) {
  developer.log(message, name: 'NotificationWatcher', level: 1000);
}
