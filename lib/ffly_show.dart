library ffly_show;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FFlyMoveModel {

  FFlyMoveModel({
    @required this.widget,
    @required this.animationController,
    this.offsetAnimation,
    this.scaleAnimation,
    this.rotationZAnimation,
    this.offset : const Offset(0.0, 0.0),
    this.scale : 1.0,
    this.rotationZ : 0.0,
  });

  final Widget widget;

  AnimationController animationController;
  Animation<Offset> offsetAnimation;
  Animation<double> scaleAnimation;
  Animation<double> rotationZAnimation;
  Offset offset;
  double scale;
  double rotationZ;

  // 计算角度用
  Point tempPoint;
  double tempRota;
  bool isBack;

  void reloadRotationZ() {
    if (rotationZ == 0.0) {
      return;
    }
    while (rotationZ.abs() >= pi * 2) {
      rotationZ = (rotationZ.abs() / rotationZ) * (rotationZ.abs() - pi);
    }
    if (rotationZ.abs() > pi) {
      rotationZ = -(rotationZ.abs() / rotationZ) * (pi * 2 - rotationZ.abs());
    }
  }

}

class FFLyShow extends StatefulWidget {

  const FFLyShow({
    Key key,
    @required this.itemWidth,
    @required this.itemHeight,
    @required this.children,
    this.offsetH = 7,
    this.offsetV = 7,
  }) :  assert(itemWidth != null && itemHeight != null),
        assert(children != null && children.length >= 2),
        assert(offsetH != null && ((children.length - 1) * 2 * offsetH) < itemWidth),
        assert(offsetV != null && ((children.length - 1) * 2 * offsetV) < itemHeight),
        super(key: key);

  final double itemWidth;
  final double itemHeight;
  final double offsetH;
  final double offsetV;
  final List<Widget> children;

  @override
  State<StatefulWidget> createState() {
    return FFlyShowState();
  }
}

class FFlyShowState extends State<FFLyShow> with TickerProviderStateMixin {

  final _duration = Duration(milliseconds: 200);

  int itemCount;
  List<FFlyMoveModel> _currentChildren = [];
  List<FFlyMoveModel> _addChildren = [];
  List<FFlyMoveModel> _removeChildren = [];

  @override
  void initState() {
    itemCount = widget.children.length;
    for (var i=0; i<itemCount; i++) {
      FFlyMoveModel model = FFlyMoveModel(widget: widget.children[i], animationController: AnimationController(duration: _duration, vsync: this));
      model.offset = Offset(0, widget.offsetV * (itemCount - 1 - i));
      model.scale = (widget.itemWidth - widget.offsetH * 2 * (itemCount - 1 - i)) / widget.itemWidth;
      model.animationController.addListener(() {
        setState(() {});
      });
      model.animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          model.animationController.reset();
          setState(() {
            reloadLocation();
          });
        }
      });
      _currentChildren.add(model);
    }
    super.initState();
  }

  void reloadLocation() {
    for (int i=0;i<_currentChildren.length;i++) {
      FFlyMoveModel model = _currentChildren[i];
      model.offset = Offset(0, widget.offsetV *  (_currentChildren.length - 1 - i));
      model.scale = (widget.itemWidth - widget.offsetH * 2 * (_currentChildren.length - 1 - i)) / widget.itemWidth;
      model.rotationZ = 0.0;
    }
  }

  @override
  void dispose() {
    for (var i=0; i<_currentChildren.length; i++) {
      _currentChildren[i].animationController.stop();
      _currentChildren[i].animationController.dispose();
    }
    for (var i=0; i<_addChildren.length; i++) {
      _addChildren[i].animationController.stop();
      _addChildren[i].animationController.dispose();
    }
    for (var i=0; i<_removeChildren.length; i++) {
      _removeChildren[i].animationController.stop();
      _removeChildren[i].animationController.dispose();
    }
    super.dispose();
  }

  // 计算三个点形成的角度
  double getAngle(Point pt1, Point pt2, Point pt0, double rate) {
    double maX = pt1.x - pt0.x;
    double maY = pt1.y - pt0.y;
    double mbX = pt2.x - pt0.x;
    double mbY = pt2.y - pt0.y;

    double x = (maX * mbX) + (maY * mbY);
    double y = (maX * mbY - mbX * maY);
    if (y == 0.0) {
      return 0.0;
    }
    return  y.abs() / y * acos(x / sqrt(x*x+y*y)) * rate;
  }

  double getDistanceRate(Point pt1, Point pt2) {
    if (pt1 == pt2) {
      return 1;
    }
    double maX = pt1.x - pt2.x;
    double maY = pt1.y - pt2.y;
    double dis = sqrt(maX * maX + maY * maY);
    double wDis = sqrt(widget.itemWidth * widget.itemWidth + widget.itemHeight * widget.itemHeight);
    return dis / wDis;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        FFlyMoveModel model = _currentChildren.last;
        model.tempPoint = Point(details.localPosition.dx, details.localPosition.dy);
        model.tempRota = getDistanceRate(model.tempPoint, Point(widget.itemWidth / 2, widget.itemHeight / 2));
      },
      onPanUpdate: (details) {
        FFlyMoveModel model = _currentChildren.last;
        if ((model.offset.dx + details.delta.dx).abs() < model.offset.dx.abs() || (model.offset.dy + details.delta.dy).abs() < model.offset.dy.abs()) {
          model.isBack = true;
        } else {
          model.isBack = false;
        }
        setState(() {
          model.offset += details.delta;
          model.rotationZ += getAngle(model.tempPoint, Point(details.localPosition.dx, details.localPosition.dy), Point(widget.itemWidth / 2, widget.itemHeight / 2), model.tempRota);
        });
        model.tempPoint = Point(details.localPosition.dx, details.localPosition.dy);
      },
      onPanEnd: (details) {
        runAnimation(details);
      },
      child: Container(
        padding: EdgeInsets.only(bottom: (widget.children.length - 1) * widget.offsetV),
        child: SizedBox(
          width: widget.itemWidth,
          height: widget.itemHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            overflow: Overflow.clip,
            children: getChildren(context),
          ),
        ),
      ),
    );
  }

  Widget buildTransformWidget(BuildContext context, FFlyMoveModel model) {
    return Transform.translate(
      offset: model.offset - (model.offsetAnimation?.value ?? Offset.zero),
      child: SizedBox(
        width: widget.itemWidth * (model.scale + (model.scaleAnimation?.value ?? 0.0)),
        height: widget.itemHeight * (model.scale + (model.scaleAnimation?.value ?? 0.0)),
        child: Transform.rotate(
          angle: model.rotationZ + (model.rotationZAnimation?.value ?? 0.0),
          child: model.widget,
        ),
      ),
    );
  }

  List<Widget> getChildren(BuildContext context) {
    List<Widget> children = [];
    for (var i=0; i<_addChildren.length; i++) {
      var model = _addChildren[i];
      Widget positionWidget = buildTransformWidget(context, model);
      children.add(
          AnimatedBuilder(
            animation: model.animationController,
            child: positionWidget,
            builder: (BuildContext context, Widget child) {
              return Opacity(opacity: model.animationController.value, child: child,);
            },
          )
      );
    }
    for (var i=0; i<_currentChildren.length; i++) {
      var model = _currentChildren[i];
      Widget positionWidget = buildTransformWidget(context, model);
      children.add(positionWidget);
    }
    for (var i=_removeChildren.length - 1; i>=0; i--) {
      var model = _removeChildren[i];
      Widget positionWidget = buildTransformWidget(context, model);
      children.add(positionWidget);
    }
    return children;
  }

  void runAnimation(DragEndDetails details) {
    FFlyMoveModel model = _currentChildren.last;
    if ((details.velocity.pixelsPerSecond.dx.abs() < 50 && details.velocity.pixelsPerSecond.dy.abs() < 50) || (model.isBack)) {
      // 恢复
      model.offsetAnimation = Tween(begin: Offset.zero, end: model.offset).chain(CurveTween(curve: Curves.easeOutBack)).animate(model.animationController);
      model.reloadRotationZ();
      model.rotationZAnimation = Tween(begin: 0.0, end: -model.rotationZ).chain(CurveTween(curve: Curves.easeOutBack)).animate(model.animationController);
      model.animationController.forward();
    } else {
      // 移除最后一个
      FFlyMoveModel model = _currentChildren.removeLast();
      model.animationController.dispose();

      // 移除动画
      final transX = model.offset.dx, transY = model.offset.dy;
      final transV = sqrt(transX * transX + transY * transY);
      final queryWight =  MediaQuery.of(context).size.width, queryHeight =  MediaQuery.of(context).size.height;
      final queryV = sqrt(queryWight * queryWight + queryHeight * queryHeight);
      final v = queryV / transV;
      final dv = transV * v;
      final velocityX = details.velocity.pixelsPerSecond.dx.abs(), velocityY = details.velocity.pixelsPerSecond.dy.abs();
      final velocityV = sqrt(velocityX * velocityX + velocityY * velocityY);
      double seconds = dv / velocityV;
      seconds = max(seconds, 0.5);
      seconds = min(seconds, 2.0);
      FFlyMoveModel removeModel = FFlyMoveModel(widget: model.widget, offset: model.offset, animationController: AnimationController(duration: Duration(microseconds: (1000 * 1000 * seconds).toInt()), vsync: this));
      removeModel.tempRota = model.tempRota;
      removeModel.tempPoint = model.tempPoint;
      removeModel.rotationZ = model.rotationZ;
      removeModel.reloadRotationZ();
      removeModel.animationController.addListener(() {
        setState(() {});
      });
      removeModel.animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _removeChildren.remove(removeModel);
            removeModel.animationController.dispose();
          });
        }
      });
      removeModel.offsetAnimation = Tween(begin: Offset.zero, end: model.offset - Offset(transX * v, transY * v)).animate(removeModel.animationController);
      double targetRota = min(model.rotationZ.abs() * 10, pi * 4);
      final velocityRota = velocityV * targetRota / queryV;
      final rotationT = (model.rotationZ.abs() / model.rotationZ) * velocityRota * seconds;
      removeModel.rotationZAnimation = Tween(begin: 0.0, end: rotationT).animate(removeModel.animationController);
      _removeChildren.insert(0, removeModel);
      removeModel.animationController?.forward();

      // 上升动画
      for (int i=0; i<_currentChildren.length; i++) {
        FFlyMoveModel currentModel = _currentChildren[i];
        currentModel.offsetAnimation = Tween(begin: Offset.zero, end: Offset(0, widget.offsetV)).animate(currentModel.animationController);
        currentModel.scaleAnimation = Tween(begin: 0.0, end: widget.offsetH * 2 / widget.itemWidth).animate(currentModel.animationController);
        currentModel.animationController.forward();
      }

      // 添加动画
      FFlyMoveModel addModel = FFlyMoveModel(widget: model.widget, animationController: AnimationController(duration: _duration, vsync: this));
      addModel.offset = Offset(0, widget.offsetV * (itemCount - 2));
      addModel.scale = (widget.itemWidth - widget.offsetH * 2 * (itemCount - 1)) / widget.itemWidth;
      addModel.animationController.addListener(() {
        setState(() {});
      });
      addModel.animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _addChildren.remove(addModel);
            addModel.animationController.dispose();

            FFlyMoveModel model = FFlyMoveModel(widget: addModel.widget, animationController: AnimationController(duration: _duration, vsync: this));
            model.offset = Offset(0, widget.offsetV * (itemCount - 1));
            model.scale = (widget.itemWidth - widget.offsetH * 2 * (itemCount - 1)) / widget.itemWidth;
            model.animationController.addListener(() {
              setState(() {});
            });
            model.animationController.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                model.animationController.reset();
                setState(() {
                  reloadLocation();
                });
              }
            });
            _currentChildren.insert(0, model);
          });
        }
      });
      addModel.offsetAnimation = Tween(begin: Offset.zero, end: -Offset(0, widget.offsetV)).animate(addModel.animationController);
      _addChildren.insert(0, addModel);
      addModel.animationController?.forward();
    }
  }
}
