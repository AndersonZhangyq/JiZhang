import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/widget/ocr/batchAddTransactions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 自定义类来存储识别结果和位置
class RecognizedTextElement {
  final String text;
  Rect boundingBox;
  bool isDate = false;
  DateTime? date;
  bool isAmount = false;
  double? amount;

  RecognizedTextElement({required this.text, required this.boundingBox}) {
    print('process text: $text');
    // 判断是否为日期，形如 xx月xx日
    final dateRegexWechat = RegExp(r'^\d{1,2}月\d{1,2}日');
    // 判断是否为日期，形如 xx-xx
    final dateRegexZhiFuBao = RegExp(r'^\d{1,2}-\d{1,2}');
    // 判断是否为金额，形如 xx.xx，可能有正负号，位数不定
    final amountRegex = RegExp(r'^[-+]?\d+(\.\d+)?$');
    if (dateRegexWechat.hasMatch(text)) {
      final matchedPart = dateRegexWechat.firstMatch(text)!.group(0)!;
      final month = int.parse(matchedPart.split('月')[0]);
      final day = int.parse(matchedPart.split('日')[0].split('月')[1]);
      if (month > 0 && month <= 12 && day > 0 && day <= 31) {
        isDate = true;
        date = DateTime.now().copyWith(month: month, day: day);
        print('date: ${date!.format("MM-dd")}');
      }
    } else if (dateRegexZhiFuBao.hasMatch(text)) {
      final matchedPart = dateRegexZhiFuBao.firstMatch(text)!.group(0)!;
      final month = int.parse(matchedPart.split('-')[0]);
      final day = int.parse(matchedPart.split('-')[1]);
      if (month > 0 && month <= 12 && day > 0 && day <= 31) {
        isDate = true;
        date = DateTime.now().copyWith(month: month, day: day);
        print('date: ${date!.format("MM-dd")}');
      }
    } else if (amountRegex.hasMatch(text)) {
      isAmount = true;
      amount = double.parse(text);
      print('amount: $amount');
    }
  }
}

class TextRecognitionWidget extends StatefulWidget {
  const TextRecognitionWidget({super.key});

  @override
  State<TextRecognitionWidget> createState() => _TextRecognitionWidgetState();
}

class _TextRecognitionWidgetState extends State<TextRecognitionWidget> {
  XFile? _image;
  List<RecognizedTextElement> _recognizedTextElements = [];
  final ImagePicker _picker = ImagePicker();
  double rawImageHeight = 0;
  double showImageHeight = 0;
  double imgScale = 1;
  ValueNotifier<List<bool>> _isSelectedNotifier = ValueNotifier([false, false]);
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _isSelectedNotifier.value = [false, false];
      _isSelectedNotifier.notifyListeners();
      setState(() {
        _recognizedTextElements = [];
        _image = image;
      });
      _recognizeText(image);
    }
  }

  Future<void> _recognizeText(XFile image) async {
    final InputImage inputImage = InputImage.fromFilePath(image.path);
    final textDetector = TextRecognizer(script: TextRecognitionScript.chinese);
    final RecognizedText recognizedText =
        await textDetector.processImage(inputImage);
    _imageBytes = await image.readAsBytes();
    var decodedImage = await decodeImageFromList(_imageBytes!);
    rawImageHeight = decodedImage.height * 1.0;
    imgScale = showImageHeight / rawImageHeight;
    print(
        'rawImageHeight: $rawImageHeight, showImageHeight: $showImageHeight, imgScale: $imgScale');
    setState(() {
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement element in line.elements) {
            _recognizedTextElements.add(RecognizedTextElement(
                text: element.text, boundingBox: element.boundingBox));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.textRecognition_Title),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(
                    AppLocalizations.of(context)!.textRecognition_PickImage),
              ),
              if (_image != null)
                Expanded(child: _buildImageWithRecognizedText()),
              if (_image != null)
                ValueListenableBuilder(
                  valueListenable: _isSelectedNotifier,
                  builder: (context, isSelected, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          height: 36,
                          child: ToggleButtons(
                            fillColor: Colors.blueGrey,
                            selectedColor: Colors.white,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            isSelected: isSelected,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .textRecognition_WeChat,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .textRecognition_ZhiFuBao,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                            onPressed: (index) {
                              _isSelectedNotifier.value = [false, false];
                              _isSelectedNotifier.value[index] = true;
                              _isSelectedNotifier.notifyListeners();
                            },
                          ),
                        ),
                        TextButton(
                          child: Text(AppLocalizations.of(context)!
                              .textRecognition_GenerateTransactions),
                          onPressed: _recognizedTextElements.isEmpty ||
                                  _isSelectedNotifier.value
                                      .every((ele) => ele == false)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            BatchAddTransactions(
                                              recognizedTextElements:
                                                  _recognizedTextElements,
                                              originalImageBytes: _imageBytes!,
                                              type: _isSelectedNotifier
                                                          .value[0] ==
                                                      true
                                                  ? 'wechat'
                                                  : 'zhifubao',
                                            )),
                                  );
                                },
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ));
  }

  Widget _buildImageWithRecognizedText() {
    return Stack(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          showImageHeight = constraints.maxHeight;
          return Image.file(File(_image!.path));
        }),
        ..._recognizedTextElements.map((element) {
          final rect = element.boundingBox;
          var left = rect.left * imgScale;
          var top = rect.top * imgScale;
          var width = rect.width * imgScale;
          var height = rect.height * imgScale;
          return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Container(
                width: width,
                height: height,
                color: Colors.blue.withOpacity(0.6),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    element.text,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ));
        }).toList(),
      ],
    );
  }
}
