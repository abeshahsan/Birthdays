import 'dart:collection';

import 'package:birthdays/components.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> showItems = [];
  List<Map<String, dynamic>> allItems = [];
  HashSet<int> selectedItemsIndex = HashSet<int>();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    // print("lol")
    return PopScope(
      canPop: selectedItemsIndex.isEmpty && textEditingController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (selectedItemsIndex.isNotEmpty) {
          setState(() {
            selectedItemsIndex.clear();
          });
        }
        if (textEditingController.text.isNotEmpty) {
          setState(() {
            textEditingController.clear();
            filterItems();
            FocusScope.of(context).requestFocus(FocusNode());
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          appBar: MyAppBar(title: widget.title),
          floatingActionButton: FloatingActionButton(
            shape: CircleBorder(),
            onPressed: () => showBdayDialogForm(),
            child: Icon(Icons.add),
          ),
          body: Column(
            children: [
              getSearchBar(),
              selectedItemsIndex.isEmpty ? Container() : getSelectedItemsBar(),
              Expanded(
                child: showItems.isEmpty
                    ? Center(child: Text("Empty List"))
                    : getBdayListViewBuilder(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController textEditingController = TextEditingController(text: "");

  Widget getSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: textEditingController,
        onChanged: (value) {
          filterItems();
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: "Search",
          prefixIcon: Icon(Icons.search),
          suffixIcon: textEditingController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    setState(() {
                      textEditingController.clear();
                      filterItems();
                      FocusScope.of(context).requestFocus(FocusNode());
                    });
                  },
                  icon: Icon(Icons.clear)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void filterItems() {
    setState(() {
      showItems = allItems
          .where((element) => element['name']
              .toString()
              .toLowerCase()
              .contains(textEditingController.text.toLowerCase()))
          .toList();
    });
  }

  Widget getSelectedItemsBar() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          TextButton(
            onPressed: () async {
              if (selectedItemsIndex.isEmpty) return;

              for (int index in selectedItemsIndex) {
                await _dbHelper.deleteItem(showItems[index]['id']);
              }
              await _loadItems(); // Refresh the list
              filterItems();
            },
            child: Text("Delete Selected"),
          ),
          Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                selectedItemsIndex.clear();
                for (int i = 0; i < showItems.length; i++) {
                  selectedItemsIndex.add(i);
                }
              });
            },
            child: Text("Select All"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadItems() async {
    final data = await _dbHelper.getAllItems();
    setState(() {
      showItems = data.toList();
      //sort them the closest day from today should be the first
      showItems.sort((a, b) {
        final today = DateTime.now();

        DateTime aDate = DateTime(DateTime.now().year, a['month'], a['day']);
        if (aDate.isBefore(today)) {
          aDate = aDate.add(Duration(days: 365));
        }

        DateTime bDate = DateTime(DateTime.now().year, b['month'], b['day']);
        if (bDate.isBefore(today)) {
          bDate = bDate.add(Duration(days: 365));
        }

        return aDate.isBefore(bDate) ? -1 : 1;
      });

      allItems = showItems.toList();
      selectedItemsIndex.clear();
    });
  }

  void showBdayDialogForm([int? index]) {
    final TextEditingController addItemController = TextEditingController(
        text: index != null ? showItems[index]['name'] : null);

    int? localSelectedDay = index != null ? showItems[index]['day'] : null;
    int? localSelectedMonth = index != null ? showItems[index]['month'] : null;

    showDialog(
        context: context,
        builder: (context) {
          return getBdayDialogBuilder(
              addItemController,
              localSelectedDay,
              localSelectedMonth,
              index != null ? showItems[index]['id'] : null);
        }).then((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Widget getBdayListViewBuilder() {
    return ListView.builder(
      itemCount: showItems.length,
      itemBuilder: (context, index) {
        final item = showItems[index];
        return TextButton(
          style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              )),
          onPressed: () {
            if (selectedItemsIndex.isEmpty) return;

            if (selectedItemsIndex.contains(index)) {
              setState(() {
                selectedItemsIndex.remove(index);
              });
            } else {
              setState(() {
                selectedItemsIndex.add(index);
              });
            }
          },
          onLongPress: () {
            setState(() {
              // Navigator.of(context).push();
              selectedItemsIndex.add(index);
            });
          },
          child: ListTile(
            title: Text(item['name']),
            subtitle: Text(
              "${months[item['month'] - 1]} ${item['day']}",
            ),
            trailing: selectedItemsIndex.isEmpty
                ? buildPopupMenu(index)
                : buildCheckbox(index),
          ),
        );
      },
    );
  }

  Widget buildCheckbox(int index) {
    return Checkbox(
      value: selectedItemsIndex.contains(index),
      onChanged: (value) {
        if (selectedItemsIndex.contains(index)) {
          setState(() {
            selectedItemsIndex.remove(index);
          });
        } else {
          setState(() {
            selectedItemsIndex.add(index);
          });
        }
      },
    );
  }

  Widget buildPopupMenu(int index) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "Edit") {
          showBdayDialogForm(index);
        } else if (value == "Delete") {
          await _dbHelper.deleteItem(showItems[index]['id']);
          await _loadItems(); // Refresh the list
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: "Edit", child: Text("Edit")),
        PopupMenuItem(value: "Delete", child: Text("Delete")),
      ],
    );
  }

  Widget getBdayDialogBuilder(
      addItemController, localSelectedDay, localSelectedMonth,
      [id]) {
    return StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text("Add Birthday"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addItemController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    menuMaxHeight: 300,
                    isDense: true,
                    value: localSelectedMonth,
                    items: List.generate(12, (index) => index + 1)
                        .map((month) => DropdownMenuItem<int>(
                              value: month,
                              child: Text(months[month - 1]),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        localSelectedMonth = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Month",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    menuMaxHeight: 300,
                    // isDense: true,
                    value: localSelectedDay,
                    items: List.generate(31, (index) => index + 1)
                        .map((day) => DropdownMenuItem<int>(
                              value: day,
                              child: Text(day.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        localSelectedDay = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Day",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (addItemController.text.isNotEmpty &&
                  localSelectedDay != null &&
                  localSelectedMonth != null &&
                  (localSelectedDay > 0 && localSelectedDay < 32) &&
                  (localSelectedMonth > 0 && localSelectedMonth < 13)) {
                if (id != null) {
                  await _dbHelper.updateItem(
                    id!,
                    addItemController.text,
                    localSelectedDay,
                    localSelectedMonth,
                  );
                } else {
                  await _dbHelper.addItem(
                    addItemController.text,
                    localSelectedDay,
                    localSelectedMonth,
                  );
                }
                await _loadItems(); // Refresh the list
                Navigator.pop(dialogContext);
              }
            },
            child: Text("Save"),
          ),
        ],
      );
    });
  }
}

List<String> months = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];
