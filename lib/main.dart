import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: 'ToDo List',
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _inputTextToDoTasksController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastTaskRemoved;
  int _lastTaskRemovedIndex;

  void _addNewTask() {
    if(_inputTextToDoTasksController.text.length > 0) {
      setState(() {
        Map<String, dynamic> newTask = Map();
        newTask['done'] = false;
        newTask['title'] = _inputTextToDoTasksController.text;
        _toDoList.add(newTask);
        _inputTextToDoTasksController.text = '';
        _sortTasksList(0);
        _saveFile(); // TODO: Work on fails context (Exceptions)
      });
    }
  }

  void _removeTask(index) {
    setState(() {
      _lastTaskRemoved = Map.from(_toDoList[index]);
      _lastTaskRemovedIndex = index;
      _toDoList.removeAt(index);
      _saveFile();
    });
  }

  @override
  void initState() {
    super.initState();

    _readTasks().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo List'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _inputTextToDoTasksController,
                    decoration: InputDecoration(
                        labelText: 'New Task',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                  child: Text('ADD'),
                  onPressed: _addNewTask,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: toDoTasksItemBuilder,
                ),
                onRefresh: () => _sortTasksList(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget toDoTasksItemBuilder(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      child: toDoTaskItem(index),
      onDismissed: (direction) {
        _removeTask(index);

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(removedTaskSnackBar());
      },
    );
  }

  Widget toDoTaskItem(int index) {
    return CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['done'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['done'] ? Icons.check : Icons.error),
        ),
        onChanged: (bool value) {
          setState(() {
            _toDoList[index]['done'] = value;
            _sortTasksList(0);
            _saveFile();
          });
        });
  }

  Widget removedTaskSnackBar() {
    return SnackBar(
      duration: Duration(seconds: 2),
      content: Text('Task \'${_lastTaskRemoved["title"]}\' removed!'),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          setState(() {
            _toDoList.insert(_lastTaskRemovedIndex, _lastTaskRemoved);
            _saveFile();
          });
        },
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks.json');
  }

  Future<File> _saveFile() async {
    String tasks = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(tasks);
  }

  Future<String> _readTasks() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _sortTasksList(int delay) async {
    if(delay > 0) await Future.delayed(Duration(seconds: delay));

    setState(() {
      _toDoList.sort((a, b) {
        if(a['done'] && !b['done']) return 1;
        else if(!a['done'] && b['done']) return -1;
        else return 0;
      });
    });
  }
}
