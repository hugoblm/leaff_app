// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RssArticleAdapter extends TypeAdapter<RssArticle> {
  @override
  final int typeId = 0;

  @override
  RssArticle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RssArticle(
      title: fields[0] as String,
      imageUrl: fields[1] as String,
      category: fields[2] as String,
      date: fields[3] as DateTime,
      description: fields[4] as String,
      link: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RssArticle obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.imageUrl)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.link);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
