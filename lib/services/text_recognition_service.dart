import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/business_card.dart';

class TextRecognitionService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<BusinessCard> processImage(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognizedText = await _textRecognizer.processImage(inputImage);

    String name = '';
    String title = '';
    String company = '';
    String phone = '';
    String email = '';
    String website = '';
    String address = '';

    // Convert to a list of lines for easier processing
    List<String> lines = recognizedText.blocks
        .expand((block) => block.lines.map((l) => l.text.trim()))
        .where((text) => text.isNotEmpty)
        .toList();

    // 1. First Pass: Look for specific formats (Phone, Email, Web)
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Email (Very reliable)
      if (email.isEmpty && _isEmail(line)) {
        email = _extractEmail(line);
        lines[i] = ''; // Consume line
        continue;
      }

      // Website (Reliable)
      if (website.isEmpty && _isWebsite(line)) {
        website = _cleanWebsite(line);
        lines[i] = ''; // Consume line
        continue;
      }

      // Phone (Try to catch labeled phones first like "Tel: 555...")
      if (phone.isEmpty && _hasPhoneLabel(line)) {
        phone = _extractPhone(line);
        lines[i] = '';
        continue;
      }
    }

    // 2. Second Pass: Look for loose phones and addresses
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.isEmpty) continue;

      // Loose Phone (without label)
      if (phone.isEmpty && _isPhone(line)) {
        phone = _extractPhone(line);
        lines[i] = '';
        continue;
      }

      // Address Detection (Heuristic: Has numbers + specific words OR resembles City, State Zip)
      if (address.isEmpty && _isAddress(line)) {
        address = line;
        // Try to append next line if it looks like part of address (City/State/Zip)
        if (i + 1 < lines.length && _isAddressContinuation(lines[i+1])) {
          address += ', ${lines[i+1]}';
          lines[i+1] = '';
        }
        lines[i] = '';
        continue;
      }
    }

    // 3. Third Pass: Name, Title, Company
    // Heuristic: Name is often the first non-consumed line, or the largest text (OCR blocks have frames, but here we simplify)
    // We will assume remaining lines at top are Name/Title/Company
    
    List<String> remaining = lines.where((l) => l.isNotEmpty).toList();
    
    if (remaining.isNotEmpty) {
      name = remaining[0]; // First remaining line usually name or company
      
      if (remaining.length > 1) {
        // Check if second line is a job title (contains common title words)
        if (_isJobTitle(remaining[1])) {
           title = remaining[1];
           if (remaining.length > 2) company = remaining[2];
        } else {
           // Maybe first line was Company and second is Name? 
           // Hard to tell without ML, stick to order: Name -> Title -> Company
           if (remaining.length > 2) {
             title = remaining[1];
             company = remaining[2];
           } else {
             // If only 2 lines left, check if line 0 looks like company
             if (_isCompany(remaining[0])) {
               company = remaining[0];
               name = remaining[1];
             } else {
               title = remaining[1];
             }
           }
        }
      }
    }

    return BusinessCard(
      id: const Uuid().v4(),
      name: name,
      title: title,
      company: company,
      phone: phone,
      email: email,
      website: website,
      address: address,
      imagePath: imagePath,
      category: 'Uncategorized',
      scanDate: DateTime.now(),
      isFavorite: false, // Default
      colorIndex: 0, // Could randomize this later
    );
  }

  // --- Helpers ---

  bool _isEmail(String text) {
    return text.contains('@') && text.contains('.');
  }

  String _extractEmail(String text) {
    // Basic extraction to remove "Email: " prefix if present
    final match = RegExp(r"[a-zA-Z0-9._-]+@[a-z]+\.+[a-z]+").firstMatch(text);
    return match?.group(0) ?? text;
  }

  bool _isWebsite(String text) {
    return text.toLowerCase().contains('www.') || 
           text.toLowerCase().startsWith('http') || 
           text.toLowerCase().endsWith('.com') ||
           text.toLowerCase().endsWith('.net') ||
           text.toLowerCase().endsWith('.org');
  }

  String _cleanWebsite(String text) {
    return text.replaceAll(RegExp(r'^.*:\s*'), '').trim();
  }

  bool _hasPhoneLabel(String text) {
    final lower = text.toLowerCase();
    return lower.contains('tel') || lower.contains('mob') || lower.contains('ph') || lower.contains('cell') || lower.contains('fax');
  }

  bool _isPhone(String text) {
    // Counts digits. If line has > 7 digits, likely a phone.
    int digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount >= 7;
  }

  String _extractPhone(String text) {
    // Remove labels like "Tel:"
    // Keep +, digits, space, -, (, )
    return text.replaceAll(RegExp(r'[a-zA-Z:]'), '').trim();
  }

  bool _isAddress(String text) {
    // Look for numbers combined with address keywords
    final lower = text.toLowerCase();
    final hasNumber = RegExp(r'\d').hasMatch(text);
    final keywords = ['st', 'ave', 'rd', 'blvd', 'lane', 'drive', 'street', 'avenue', 'road', 'plaza', 'way', 'sq', 'floor', 'ste', 'suite', 'bldg', 'calle', 'av', 'paseo'];
    
    bool hasKeyword = keywords.any((k) => lower.contains(k) || lower.endsWith(k) || lower.contains('$k.'));
    
    // Also check for Zip Code pattern (5+ digits at end or start)
    bool hasZip = RegExp(r'\b\d{5}\b').hasMatch(text);

    return (hasNumber && hasKeyword) || (hasZip && hasNumber);
  }

  bool _isAddressContinuation(String text) {
    // City State Zip often looks like: "New York, NY 10001"
    return RegExp(r'\b\d{5}\b').hasMatch(text) || // Zip code
           text.contains(',') || // City, State
           text.length < 30; // Usually short line
  }

  bool _isJobTitle(String text) {
    final keywords = ['manager', 'director', 'engineer', 'developer', 'consultant', 'ceo', 'cto', 'cfo', 'president', 'founder', 'specialist', 'analyst', 'designer', 'lead', 'head', 'chief'];
    return keywords.any((k) => text.toLowerCase().contains(k));
  }
  
  bool _isCompany(String text) {
    final keywords = ['inc', 'llc', 'ltd', 'group', 'systems', 'technologies', 'corp', 'solutions'];
    return keywords.any((k) => text.toLowerCase().contains(k));
  }

  void dispose() {
    _textRecognizer.close();
  }
}