import 'package:flutter/material.dart';

enum ShadowObjectType { text, signature, shape, redact }

class ShadowObject {
  final String id;
  final ShadowObjectType type;
  Offset position;
  Size size;
  String content; // Text content or image path/base64
  double fontSize;
  Color color;
  int pageIndex;

  ShadowObject({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.content = '',
    this.fontSize = 14,
    this.color = Colors.black,
    required this.pageIndex,
  });

  ShadowObject copyWith({
    Offset? position,
    Size? size,
    String? content,
    double? fontSize,
    Color? color,
  }) {
    return ShadowObject(
      id: id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      pageIndex: pageIndex,
    );
  }
}
