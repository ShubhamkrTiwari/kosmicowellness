import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// OpenAI API Key (Scan Meal / GPT-4o Vision)
const String OPENAI_API_KEY = 'YOUR_OPENAI_API_KEY';

// Twilio Credentials for Phone OTP
const String TWILIO_ACCOUNT_SID = 'YOUR_TWILIO_ACCOUNT_SID';
const String TWILIO_AUTH_TOKEN = 'YOUR_TWILIO_AUTH_TOKEN';
const String TWILIO_API_KEY_SID = 'YOUR_TWILIO_API_KEY_SID';
const String TWILIO_CLIENT_SECRET = 'YOUR_TWILIO_CLIENT_SECRET';
const String TWILIO_MESSAGING_SERVICE_SID = 'YOUR_TWILIO_MESSAGING_SERVICE_SID';
