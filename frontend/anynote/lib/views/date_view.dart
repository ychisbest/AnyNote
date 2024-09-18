import 'package:anynote/Extension.dart';
import 'package:anynote/MainController.dart';
import 'package:anynote/note_api_service.dart';
import 'package:anynote/views/EditNote.dart';
import 'package:anynote/views/archieve_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class Browser extends StatefulWidget {
  const Browser({super.key});

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  final ScrollController _scrollController = ScrollController();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dates"),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day - 1);
                _focusedDay = DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day - 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day + 1);
                _focusedDay = DateTime(_selectedDay!.year, _selectedDay!.month,
                    _selectedDay!.day + 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () {
              setState(() {
                _calendarFormat = CalendarFormat.week;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                _calendarFormat = CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(child: Obx(() {
        var c = Get.find<MainController>();
        var items = groupMemosByDate(c.notes);
        return Column(
          children: [
            TableCalendar(
              startingDayOfWeek: StartingDayOfWeek.monday,
              firstDay: DateTime.utc(2016, 10, 1),
              lastDay: DateTime.utc(2099, 9, 9),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              daysOfWeekVisible: true,
              rowHeight: 40,
              headerStyle: HeaderStyle(titleTextFormatter: (d, e) {
                return d.toString().split(' ')[0];
              }),
              daysOfWeekHeight: 15,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 10),
                weekendStyle: TextStyle(fontSize: 10, color: Colors.blue),
                // dowTextFormatter: (d,e){
                //   final days = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期天"];
                //   return days[d.weekday - 1];
                // }
              ),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, events) {
                  if (items.any((entry) => isSameDay(entry.key, date))) {
                    return Center(child: Text(date.day.toString()));
                  } else {
                    return Center(
                        child: Text(
                      date.day.toString(),
                      style: const TextStyle(color: Colors.black12),
                    ));
                  }
                },
                outsideBuilder: (context, date, events) {
                  return const SizedBox.shrink();
                },
                todayBuilder: (context, date, events) {
                  return Container(
                    decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20))),
                    height: 45,
                    width: 45,
                    child: Center(child: Text(date.day.toString())),
                  );
                },
              ),
            ),
            Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: const Divider(
                  height: 1,
                )),
            Builder(builder: (context) {
              var memocount = items
                  .firstWhere((entry) => isSameDay(entry.key, _selectedDay),
                      orElse: () => MapEntry(DateTime(0), []))
                  .value
                  .length;
              return memocount == 0
                  ? const Center(child: Text('No memory today! 🚫'))
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: memocount,
                      itemBuilder: (context, index) {
                        var memo = items
                            .firstWhere(
                                (entry) => isSameDay(entry.key, _selectedDay))
                            .value[index];
                        return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: NoteItemWidget(
                                controller: c,
                                item: memo,
                                isArchive: memo.isArchived));
                      },
                    );
            }),
          ],
        );
      })),
    );
  }

  List<MapEntry<DateTime, List<NoteItem>>> groupMemosByDate(
      List<NoteItem> memos) {
    Map<DateTime, List<NoteItem>> memoMap = {};

    for (var memo in memos) {
      // var adjustDate=memo.createTime.add(Duration(hours: -3));
      var adjustDate = memo.createTime;
      DateTime date =
          DateTime(adjustDate.year, adjustDate.month, adjustDate.day);
      if (!memoMap.containsKey(date)) {
        memoMap[date] = [];
      }
      memoMap[date]!.add(memo);
    }

    var sortedEntries = memoMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedEntries;
  }
}
