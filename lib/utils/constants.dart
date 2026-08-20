import 'package:flutter/material.dart';

// Colors
const Color kLivinkeyGreen = Color(0xFF92C24A);
const Color kLivinkeyBlack = Color(0xFF000000);
const Color kLivinkeyWhite = Color(0xFFFFFFFF);

// API Configuration
const String kApiBaseUrl = 'http://192.168.0.112:5000/api';

// Asset paths
const String kLogoBaseAsset = 'assets/images/livinkey_base_white.png';
const String kLogoKeyAsset = 'assets/images/livinkey_key_white_without_ring.png';
const String kLogoRingDotAsset = 'assets/images/livinkey_key_ringdot_white.png';
const String kGeneralLogo = 'assets/images/general_logo.png';

// Strings
const String kAppName = 'Livinkey';
const String kTagline = 'A COMPLETE HOME';

// WhatsApp
const String kWhatsAppNumber = '919878383497';
const String kWhatsAppUrl = 'https://wa.me/$kWhatsAppNumber';

// Social Media
const String kInstagramUrl = 'https://www.instagram.com/livinkey';
const String kFacebookUrl = 'https://www.facebook.com/livin.key.9';
const String kGoogleUrl = 'https://share.google/ktGKY5w8NCakvEo6u';
const String kEmailUrl = 'mailto:livinkey@gmail.com';

// Animation durations
const Duration kFadeDuration = Duration(milliseconds: 600);
const Duration kSlideDuration = Duration(milliseconds: 700);
const Duration kSnackbarDuration = Duration(seconds: 2);

// Storage keys
const String kStorageToken = 'lk_token';
const String kStorageUser = 'lk_user';
const String kStorageRole = 'lk_role';

// Device type
const String kDeviceType = 'android'; // Will be overridden by platform detection