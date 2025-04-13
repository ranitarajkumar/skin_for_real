import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FaceApiService {
  static const String _endpoint = 'https://skinforreal-api.cognitiveservices.azure.com';
  static const String _subscriptionKey = '2gIV6jTR3zD75b95zwCaWZWDiDbewiwLQRcWYaVZpgo2FFrQf0FlJQQJ99BDACYeBjFXJ3w3AAAKACOG73nB';

  static Future<Map<String, dynamic>> analyzeFaceFromImage(File imageFile) async {
    final uri = Uri.parse('$_endpoint/face/v1.0/detect?returnFaceAttributes=blur,exposure,noise,occlusion,glasses,headPose');
    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['faceAttributes'] != null) {
        return data[0]['faceAttributes'];
      } else {
        return {'error': 'No face detected'};
      }
    } else {
      throw Exception('Azure error: ${response.body}');
    }
  }

  static String estimateSkinColorLabel(Map<String, dynamic> attr) {
    final exposure = attr['exposure']?['value'] ?? 0.0;
    if (exposure >= 0.75) return 'Light';
    if (exposure >= 0.55) return 'Medium';
    if (exposure >= 0.35) return 'Tan/Olive';
    if (exposure >= 0.2) return 'Brown';
    return 'Deep/Dark';
  }

  static String detectSkinType(Map<String, dynamic> attr) {
    final blur = attr['blur']?['blurLevel'] ?? 'low';
    final noise = attr['noise']?['value'] ?? 0.0;
    final exposure = attr['exposure']?['value'] ?? 0.0;

    if (noise > 0.5 && blur == 'high') return 'Acne-prone';
    if (exposure > 0.6 && noise < 0.3) return 'Oily';
    if (exposure < 0.3 && noise < 0.3) return 'Dry';
    return 'Combination/Normal';
  }

  static String skincareTips(String type, String tone) {
    final baseTips = {
      'Acne-prone': '''
🔍 Acne-Prone Skin Tips:
- Use salicylic acid or benzoyl peroxide.
- Avoid pore-clogging oils.
- Stick to non-comedogenic products.
🇺🇸 CeraVe Acne Foaming Cleanser, Paula’s Choice BHA
🇪🇺 La Roche-Posay Effaclar Duo+
🇰🇷 COSRX Acne Pimple Master Patches
''',
      'Oily': '''
💧 Oily Skin Tips:
- Use gel-based moisturizers.
- Try niacinamide to reduce oil.
- Don’t over-cleanse.
🇺🇸 Neutrogena Hydro Boost Water Gel
🇪🇺 Bioderma Sébium Mat
🇰🇷 Beauty of Joseon Calming Serum
''',
      'Dry': '''
🌿 Dry Skin Tips:
- Use ceramides and hyaluronic acid.
- Avoid harsh exfoliants.
- Moisturize on damp skin.
🇺🇸 CeraVe Moisturizing Cream
🇪🇺 Eucerin Advanced Repair
🇰🇷 Etude House SoonJung Barrier Cream
''',
      'Combination/Normal': '''
🔄 Combination/Normal Skin Tips:
- Balance hydration and oil control.
- Use gentle cleanser and light moisturizer.
🇺🇸 Vanicream Gentle Cleanser
🇪🇺 Avene Cleanance Gel
🇰🇷 Klairs Rich Moist Soothing Cream
'''
    };

    final toneExtras = {
      'Light': '''
☀️ Sunscreen: Use mineral SPF 30+ for sensitivity.
✨ Retinoids: Start 2–3x/week.
🧼 Avoid harsh scrubs.
''',
      'Medium': '''
☀️ Use gel/hybrid SPF to avoid white cast.
💧 Balance hydration and oil control.
🧴 Try niacinamide or vitamin C.
''',
      'Tan/Olive': '''
☀️ No-cast/tinted sunscreen formulas preferred.
✨ Use alpha arbutin for pigmentation.
🌿 Centella asiatica or green tea-based serums help soothe.
''',
      'Brown': '''
☀️ SPF daily to prevent dark marks.
🎯 Brighten with vitamin C or peptides.
🧴 Rebuild barrier with ceramides.
''',
      'Deep/Dark': '''
☀️ Broad-spectrum SPF: prevent post-acne marks.
💊 Avoid scarring: be gentle.
🧼 Clean towels daily. Avoid over-exfoliating.
'''
    };

    final treatment = '''
⚙️ Advanced Routine:
- OTC: Retinol (0.25–1.0%)
- Rx: Adapalene, Tretinoin
- Severe acne: Doxycycline or Minocycline
⚠️ Accutane only under supervision
☀️ SPF 30+ every morning
🧴 Clean towels & patch test products
''';

    return '${baseTips[type] ?? ''}\n${toneExtras[tone] ?? ''}\n$treatment';
  }

  static String customizedRoutine(String type, String tone) {
    final cleanser = {
      'Dry': 'CeraVe Hydrating Cleanser',
      'Oily': 'La Roche-Posay Effaclar Gel',
      'Acne-prone': 'CeraVe Acne Foaming Cleanser',
      'Combination/Normal': 'Vanicream Gentle Cleanser'
    };

    final moisturizer = {
      'Dry': 'Eucerin Advanced Repair',
      'Oily': 'Neutrogena Hydro Boost',
      'Acne-prone': 'Differin Gel or CeraVe PM',
      'Combination/Normal': 'Aveeno Calm + Restore'
    };

    final sunscreen = {
      'Deep/Dark': 'Beauty of Joseon Relief Sun',
      'Brown': 'Etude House Sunprise SPF 50+',
      'Tan/Olive': 'Skin Aqua UV Super Moisture Gel',
      'Medium': 'Round Lab Birch Juice SPF',
      'Light': 'EltaMD UV Clear SPF 46'
    };

    return '''
🧼 Personalized Routine:
Cleanser: ${cleanser[type] ?? 'Gentle Cleanser'}
Moisturizer: ${moisturizer[type] ?? 'Balanced Cream'}
Sunscreen (K-Beauty): ${sunscreen[tone] ?? 'Any SPF 30+ non-irritating'}

💡 Follow tips tailored to your skin type and tone above.
''';
  }

  static String suggestCulprit(String prev, String current) {
    if (prev != 'Acne-prone' && current == 'Acne-prone') {
      return '⚠️ Flare-up detected. Recheck new products or actives. Use fewer steps.';
    }
    if (prev == 'Dry' && current == 'Oily') {
      return '🔁 Could be rebound oil from over-cleansing. Use barrier-repair creams.';
    }
    return '✅ No concerning pattern detected.';
  }

  static Future<String> analyzeTrendsAndSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final logs = <String>[];

    for (int i = 0; i <= 14; i++) {
      final day = now.subtract(Duration(days: i)).toIso8601String().split('T').first;
      final log = prefs.getString('progress_$day');
      if (log != null) logs.add(log);
    }

    final counts = <String, int>{};
    for (final t in logs) {
      counts[t] = (counts[t] ?? 0) + 1;
    }

    if (logs.length >= 7 && counts.values.every((v) => v == 1)) {
      return '⚠️ No consistent pattern in skin state. Consider simplifying your skincare.';
    }

    if ((counts['Acne-prone'] ?? 0) >= 5) {
      return '🚨 Frequent acne results. Check actives or base products like moisturizers or SPF.';
    }

    return '✅ No concerning trends detected.';
  }
}
