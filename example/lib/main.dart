import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_browser/photo_browser.dart';
import 'package:flt_hc_hud/flt_hc_hud.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/big_1.jpg
  String domain =
      'https://gitee.com/hongchenchen/test_photos_lib/raw/master/pic/';
  List<String> _bigPhotos = <String>[];
  List<String> _thumPhotos = <String>[];
  List<String> _heroTags = <String>[];
  PhotoBrowerController _browerController = PhotoBrowerController();
  bool _showTip = true;
  int? _initIndex;
  int? _curIndex;

  @override
  void initState() {
    for (int i = 1; i <= 6; i++) {
      String bigPhoto = domain + 'big_$i.jpg';
      _bigPhotos.add(bigPhoto);
      String thumPhoto = domain + 'thum_$i.jpg';
      _thumPhotos.add(thumPhoto);
      _heroTags.add(thumPhoto);
    }
    super.initState();
  }

  @override
  void dispose() {
    _browerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Photo browser example'),
          ),
          body: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              return Container(
                margin: EdgeInsets.all(5),
                child: GridView.builder(
                  itemCount: _thumPhotos.length,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 1),
                  itemBuilder: (BuildContext context, int index) {
                    return _buildCell(context, index);
                  },
                ),
              );
            },
          )),
    );
  }

  Widget _buildCell(BuildContext context, int cellIndex) {
    return GestureDetector(
      onTap: () {
        PhotoBrowser photoBrowser = PhotoBrowser(
          itemCount: _bigPhotos.length,
          initIndex: cellIndex,
          controller: _browerController,
          allowTapToPop: true,
          allowSwipeDownToPop: true,
          // If allowPullDownToPop is true, the allowTapToPop setting is invalid.
          allowPullDownToPop: true,
          // If heroTagBuilder is null, the pop animation is a general push animation.
          heroTagBuilder: (int index) {
            return _heroTags[index];
          },
          // Images setting.
          // If you want the displayed image to be cached to disk at the same time,
          // you can set the imageProviderBuilder property instead imageUrlBuilder,
          // then set it with imageProvider with disk caching function.
          imageUrlBuilder: (int index) {
            return _bigPhotos[index];
          },
          // Thumbnails setting.
          // If you want the displayed thumbnail to be cached to disk at the same time,
          // you can set the thumImageProviderBuilder property instead thumImageUrlBuilder,
          // then set it with imageProvider with disk caching function.
          thumImageUrlBuilder: (int index) {
            return _thumPhotos[index];
          },
          // Through the positionsBuilder property，
          // you can create widgets on the photo browser,
          // such as close button and save button.
          positionsBuilder: _positionsBuilder,
          loadFailedChild: _failedChild(),
          onPageChanged: (int index) {
            _curIndex = index;
          },
        );

        // You can push directly.
        // photoBrowser.push(context);

        // If necessary, it can also be wrapped in a widget
        // Here it is wrapped with HCHud (a toast plugin)
        photoBrowser
            .push(context, page: HCHud(child: photoBrowser))
            .then((value) {
          setState(() {});
          Future.delayed(Duration(milliseconds: 600), () {
            _initIndex = null;
            _curIndex = null;
            setState(() {});
          });
          print('PhotoBrowser poped');
        });

        setState(() {
          _initIndex = cellIndex;
        });
      },
      child: _initIndex == cellIndex || _curIndex == cellIndex
          ? Stack(
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  top: 0,
                  child: Image.network(
                    _thumPhotos[cellIndex],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    top: 0,
                    child: Hero(
                      tag: _heroTags[cellIndex],
                      child: Image.network(
                        _thumPhotos[cellIndex],
                        fit: BoxFit.cover,
                      ),
                    )),
              ],
            )
          : Hero(
              tag: _heroTags[cellIndex],
              child: Image.network(
                _thumPhotos[cellIndex],
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  List<Positioned> _positionsBuilder(
      BuildContext context, int curIndex, int totalNum) {
    return <Positioned>[
      _buildCloseBtn(context, curIndex, totalNum),
      _buildSaveImageBtn(context, curIndex, totalNum),
      _buildGuide(context, curIndex, totalNum),
    ];
  }

  // close button
  Positioned _buildCloseBtn(BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).padding.top,
      child: GestureDetector(
        onTap: () {
          // Pop through controller
          _browerController.pop();
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          height: 44,
          child: Text(
            '关闭',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha(230),
              decoration: TextDecoration.none,
              shadows: <Shadow>[
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 3.0,
                  color: Colors.black,
                ),
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 8.0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // save image button
  Positioned _buildSaveImageBtn(
      BuildContext context, int curIndex, int totalNum) {
    return Positioned(
      left: 20,
      bottom: 20,
      child: GestureDetector(
        onTap: () async {
          var status = await Permission.photos.request();
          if (status.isDenied) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('提示'),
                  content: Text('需要授权使用相册才能保存，去授权？'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('去授权'),
                      onPressed: () {
                        openAppSettings();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }

          // Obtain image data through the controller
          ImageInfo? imageInfo;
          if (_browerController.imageInfos[curIndex] != null) {
            imageInfo = _browerController.imageInfos[curIndex];
          } else if (_browerController.thumImageInfos[curIndex] != null) {
            imageInfo = _browerController.thumImageInfos[curIndex];
          }
          if (imageInfo == null) {
            HCHud.of(context)?.showErrorAndDismiss(text: '没有发现图片');
            return;
          }

          HCHud.of(context)?.showLoading(text: '正在保存...');

          // Save image to album
          var byteData =
              await imageInfo.image.toByteData(format: ImageByteFormat.png);
          if (byteData != null) {
            Uint8List uint8list = byteData.buffer.asUint8List();
            var result = await ImageGallerySaver.saveImage(
                Uint8List.fromList(uint8list));
            if (result != null) {
              HCHud.of(context)?.showSuccessAndDismiss(text: '保存成功');
            } else {
              HCHud.of(context)?.showErrorAndDismiss(text: '保存失败');
            }
          }
        },
        child: Text(
          '保存图片',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(230),
            decoration: TextDecoration.none,
            shadows: <Shadow>[
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 8.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gesture guidance interface
  Positioned _buildGuide(BuildContext context, int curIndex, int totalNum) {
    return _showTip
        ? Positioned(
            left: 0,
            bottom: 0,
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                _showTip = false;
                // Refresh the photoBrowser through the controller
                _browerController.setState(() {});
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                alignment: Alignment.center,
                child: Text(
                  '温馨提示😊：\n单击或向下轻扫关闭图片浏览器',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(230),
                    decoration: TextDecoration.none,
                    shadows: <Shadow>[
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 8.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Positioned(
            child: Container(),
          );
  }

  Widget _failedChild() {
    return Center(
      child: Material(
        child: Container(
          child: Text(
            '加载图片失败',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
