import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> toDoLists = {};

  @override
  void initState() {
    super.initState();
    loadLists();
  }

  Future<void> loadLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLists = prefs.getString('toDoLists');
    if (storedLists != null) {
      setState(() {
        toDoLists = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(storedLists).map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(
                value.map((task) => Map<String, dynamic>.from(task)),
              ),
            ),
          ),
        );
      });
    }
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int startWeekday(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  List<Widget> generateDays() {
    int totalDays = daysInMonth(selectedDate.year, selectedDate.month);
    int startingWeekday = startWeekday(selectedDate.year, selectedDate.month);
    List<Widget> days = [];

    for (int i = 1; i < startingWeekday; i++) {
      days.add(Container());
    }

    for (int day = 1; day <= totalDays; day++) {
      bool isToday = DateTime.now().day == day &&
          DateTime.now().month == selectedDate.month &&
          DateTime.now().year == selectedDate.year;

      String key = '${selectedDate.year}-${selectedDate.month}-$day';

      bool hasTasks = toDoLists.values.any((tasks) => tasks
          .any((task) => task['date'] != null && task['date'].startsWith(key)));

      days.add(
        GestureDetector(
          onTap: () => showTasksForDate(key, day),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasTasks ? Colors.red : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return days;
  }

  void showTasksForDate(String key, int day) {
    List<Map<String, dynamic>> tasksForDate = [];
    toDoLists.forEach((listName, tasks) {
      tasks.forEach((task) {
        if (task['date'] != null && task['date'].startsWith(key)) {
          tasksForDate.add(task);
        }
      });
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Задачи на $day'),
        content: tasksForDate.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: tasksForDate.map((task) {
                  return ListTile(
                    title: Text(task['task']),
                  );
                }).toList(),
              )
            : Text('Нет задач на этот день'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void resetToCurrentMonth() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  void selectYear() {
    TextEditingController controller = TextEditingController(
      text: selectedDate.year.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выбор года'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Введите год',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              int? year = int.tryParse(controller.text);
              if (year != null && year > 0) {
                setState(() {
                  selectedDate = DateTime(year, selectedDate.month, 1);
                });
              }
              Navigator.pop(context);
            },
            child: Text('Применить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${getMonthName(selectedDate.month)} ${selectedDate.year}'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: resetToCurrentMonth,
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: selectYear,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('ПН'),
              Text('ВТ'),
              Text('СР'),
              Text('ЧТ'),
              Text('ПТ'),
              Text('СБ'),
              Text('ВС'),
            ],
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7, // 7 дней в неделе
              children: generateDays(),
            ),
          ),
        ],
      ),
    );
  }

  String getMonthName(int month) {
    const List<String> monthNames = [
      "Январь",
      "Февраль",
      "Март",
      "Апрель",
      "Май",
      "Июнь",
      "Июль",
      "Август",
      "Сентябрь",
      "Октябрь",
      "Ноябрь",
      "Декабрь"
    ];
    return monthNames[month - 1];
  }
}
