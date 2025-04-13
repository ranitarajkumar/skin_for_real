import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class SkinProgressCalendar extends StatefulWidget {
  const SkinProgressCalendar({super.key});

  @override
  State<SkinProgressCalendar> createState() => _SkinProgressCalendarState();
}

class _SkinProgressCalendarState extends State<SkinProgressCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Map<String, dynamic>> _entries = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('log_'));
    final Map<String, Map<String, dynamic>> data = {};

    for (final key in keys) {
      final date = key.replaceFirst('log_', '');
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          data[date] = jsonDecode(raw);
        } catch (_) {
          data[date] = {'type': 'Unknown', 'tips': 'N/A'};
        }
      }
    }

    setState(() {
      _entries = data;
    });
  }

  void _showEntryDetails(DateTime day) {
    final todayStr = day.toIso8601String().split('T')[0];
    final current = _entries[todayStr];

    if (current == null) {
      _showPopup("No Entry", "There is no skin log for this day.");
      return;
    }

    final prevDay = day.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    final prev = _entries[prevDay];

    String comparison = '📉 No previous day data for comparison.';
    if (prev != null && prev['type'] != null) {
      final prevType = prev['type'];
      final currentType = current['type'];
      if (prevType != currentType) {
        comparison = '🔁 Skin type changed from $prevType to $currentType.';
      } else {
        comparison = '✅ Skin type is consistent with the previous day ($currentType).';
      }
    }

    final String logText = '''
📅 Date: $todayStr
🧬 Skin Type: ${current['type'] ?? 'N/A'}
🎨 Skin Tone: ${current['color'] ?? 'N/A'}

📝 Tips:
${(current['tips'] as String?)?.replaceAll(r'\n', '\n') ?? 'No tips found'}

📊 Comparison:
$comparison
''';

    _showPopup("Skin Log for $todayStr", logText);
  }

  void _showPopup(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _inject14DayLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();

    final simulatedLogs = [
      {
        'type': 'Acne-prone',
        'color': 'Deep/Dark',
        'tips': 'Use salicylic acid and non-comedogenic moisturizer.\nAvoid touching your face.\n🇺🇸 CeraVe Acne Cleanser\n🧴 COSRX Pimple Patches'
      },
      {
        'type': 'Oily',
        'color': 'Tan/Olive',
        'tips': 'Use gel moisturizer with niacinamide.\n🇰🇷 Beauty of Joseon Serum\n🇺🇸 Neutrogena Water Gel'
      },
      {
        'type': 'Dry',
        'color': 'Medium',
        'tips': 'Use hyaluronic acid on damp skin.\n🇺🇸 CeraVe Cream\n🇪🇺 Eucerin Advanced Repair'
      },
      {
        'type': 'Combination/Normal',
        'color': 'Brown',
        'tips': 'Balance hydration + light exfoliation.\n🇺🇸 Vanicream Cleanser\n🇰🇷 Klairs Moist Cream'
      },
      {
        'type': 'Acne-prone',
        'color': 'Light',
        'tips': 'Spot treat with benzoyl peroxide.\n🇪🇺 Effaclar Duo+'
      },
      {
        'type': 'Dry',
        'color': 'Deep/Dark',
        'tips': 'Avoid over-exfoliating. Moisturize immediately after cleansing.\n🇰🇷 Etude House Barrier Cream'
      },
      {
        'type': 'Oily',
        'color': 'Medium',
        'tips': 'Avoid heavy creams. Use blotting paper mid-day.\n🧴 Bioderma Sébium Mat'
      },
      {
        'type': 'Combination/Normal',
        'color': 'Tan/Olive',
        'tips': 'Use low pH cleanser.\n🇺🇸 Vanicream\n🇰🇷 SoonJung Toner'
      },
      {
        'type': 'Dry',
        'color': 'Brown',
        'tips': 'Layer toner + essence + cream.\n🧴 Aveeno Calm & Restore'
      },
      {
        'type': 'Acne-prone',
        'color': 'Tan/Olive',
        'tips': 'Try adapalene 0.1% if breakouts persist.\n🇺🇸 Differin Gel'
      },
      {
        'type': 'Oily',
        'color': 'Deep/Dark',
        'tips': 'Avoid alcohol toners. Use foaming cleanser.\n🇺🇸 La Roche-Posay Gel Cleanser'
      },
      {
        'type': 'Combination/Normal',
        'color': 'Light',
        'tips': 'Use vitamin C in the morning. Avoid layering too many products.\n🇺🇸 Paula’s Choice C15 Booster'
      },
      {
        'type': 'Dry',
        'color': 'Medium',
        'tips': 'Avoid overwashing. Moisturize twice daily.\n🇪🇺 Avene Skin Recovery Cream'
      },
      {
        'type': 'Acne-prone',
        'color': 'Brown',
        'tips': 'Try BHA 2% exfoliation twice a week.\n🇺🇸 Paula’s Choice 2% BHA\n🧴 Zinc SPF'
      },
    ];

    for (int i = 0; i < 14; i++) {
      final day = today.add(Duration(days: i));
      final dateStr = day.toIso8601String().split('T')[0];
      final entry = simulatedLogs[i % simulatedLogs.length];

      await prefs.setString('log_$dateStr', jsonEncode(entry));
      await prefs.setString('progress_$dateStr', entry['type']!);
    }

    _loadLogs();
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) => k.startsWith('log_') || k.startsWith('progress_')).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Skin Progress Calendar"),
        backgroundColor: isDark ? Colors.black : Colors.deepPurple.shade100,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear All Logs?'),
                  content: const Text('This will permanently delete all skin tracking data.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearLogs();
                      },
                      child: const Text('Clear'),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _inject14DayLogs,
            tooltip: 'Inject 14-day Test Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _showEntryDetails(selected);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
              outsideDaysVisible: false,
            ),
          ),
        ],
      ),
    );
  }
}
