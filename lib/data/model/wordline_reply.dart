import 'dart:convert';

import 'package:equatable/equatable.dart';

class WordLineReply extends Equatable {
  final String? rucProducer;
  final String? registeredNameProducer;
  final String? productOrigine;
  final String? iceProduct;
  final String? activationDate;
  final String? umCode;
  final String? numberSanityDocument;
  final String? dateSanityDocument;

  const WordLineReply({
    this.rucProducer,
    this.registeredNameProducer,
    this.productOrigine,
    this.iceProduct,
    this.activationDate,
    this.umCode,
    this.numberSanityDocument,
    this.dateSanityDocument,
  });

  WordLineReply copyWith({
    String? rucProducer,
    String? registeredNameProducer,
    String? productOrigine,
    String? iceProduct,
    String? activationDate,
    String? umCode,
    String? numberSanityDocument,
    String? dateSanityDocument,
  }) {
    return WordLineReply(
      rucProducer: rucProducer ?? this.rucProducer,
      registeredNameProducer:
          registeredNameProducer ?? this.registeredNameProducer,
      productOrigine: productOrigine ?? this.productOrigine,
      iceProduct: iceProduct ?? this.iceProduct,
      activationDate: activationDate ?? this.activationDate,
      umCode: umCode ?? this.umCode,
      numberSanityDocument: numberSanityDocument ?? this.numberSanityDocument,
      dateSanityDocument: dateSanityDocument ?? this.dateSanityDocument,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Ruc_Producer': rucProducer,
      'Registered_Name_Producer': registeredNameProducer,
      'Product_Origine': productOrigine,
      'ICE_Product': iceProduct,
      'Activation_Date': activationDate,
      'UM_Code': umCode,
      'Number_Sanity_Document': numberSanityDocument,
      'Date_Sanity_Document': dateSanityDocument,
    };
  }

  factory WordLineReply.fromMap(Map<String, dynamic> map) {
    return WordLineReply(
      rucProducer: map['Ruc_Producer'],
      registeredNameProducer: map['Registered_Name_Producer'],
      productOrigine: map['Product_Origine'],
      iceProduct: map['ICE_Product'],
      activationDate: map['Activation_Date'],
      umCode: map['UM_Code'],
      numberSanityDocument: map['Number_Sanity_Document'],
      dateSanityDocument: map['Date_Sanity_Document'],
    );
  }

  String toJson() => json.encode(toMap());

  factory WordLineReply.fromJson(String source) =>
      WordLineReply.fromMap(json.decode(source));

  @override
  String toString() {
    return 'WordLineReply(rucProducer: $rucProducer, registeredNameProducer: $registeredNameProducer, productOrigine: $productOrigine, iceProduct: $iceProduct, activationDate: $activationDate, umCode: $umCode, numberSanityDocument: $numberSanityDocument, dateSanityDocument: $dateSanityDocument)';
  }

  @override
  List<Object> get props {
    return [
      rucProducer!,
      registeredNameProducer!,
      productOrigine!,
      iceProduct!,
      activationDate!,
      umCode!,
      numberSanityDocument!,
      dateSanityDocument!,
    ];
  }
}
