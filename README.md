# FFlyShow

A Flutter plugin for iOS, Android for animation show content.

![The example app running in iOS](https://github.com/PreSwift/FFlyShow/blob/main/doc/ezgif-2-0643cf255401.gif)

[Feedback welcome](https://github.com/PreSwift/FFlyShow/issues) and
[Pull Requests](https://github.com/PreSwift/FFlyShow/pulls) are most welcome!

## Example

```dart
import 'package:ffly_show/ffly_show.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.only(right: 20, top: 20),
        alignment: Alignment.topRight,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        clipBehavior: Clip.hardEdge,
        child: FFLyShow(
          itemWidth: 180,
          itemHeight: 200,
          children: getImageWidgets(),
        ),
      ),
    );
  }

  List<Widget> getImageWidgets() {
    List<Widget> imageWidgets = [];
    for (var i=0;i<colors.length;i++) {
      imageWidgets.add(
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Container(
              color: colors[i],
            ),
          )
      );
    }
    return imageWidgets;
  }
}
```
