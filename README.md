# HL7v2Template



## 概要

テンプレートクラスにHL7メッセージを記載し、必要な部分に#(..プロパティ)#を指定することで、プロパティにその部分の値が代入されます。
FHIRTemplateと連携できるよう、指定されたインスタンスのプロパティに値を代入できるようにしています。

## テンプレートクラス

テンプレートクラスには以下のクラスが存在します。

+ メッセージテンプレートクラス
+ データタイプテンプレートクラス

### メッセージテンプレートクラス

メッセージテンプレートクラスはHL7v2Template.Baseクラスを継承し、Template XDATAブロックにHL7メッセージを記述します。この時、HL7メッセージはJSON array形式でHL7セグメントごとに文字列として登録します。
値を取得したい部分を#(..プロパティ)#と記述することでプロパティに値を代入できます。
Template XDATAブロックは以下のようになります。

```json:sample
     XData Template [ MimeType = application/json ]
     {
     [
     "MSH|^\~\\&|IRIS|HIS|GW|GW|#(..MsgTime)#||…",
     "EVN||201112202100|||||SEND001",
     "PID|0001||#(..PatientId)#||#(..LastName)#^…",
     "NK1|1|#(..LastName)#^#(..FirstName)#^^^^^L^I~…"
     ]
     }
     Property MsgTime as %TimeStamp;

     Property PatientId as %String;
```

HL7メッセージのメタデータを参照する必要がありますので、以下のパラメータを登録してください。

+ SchemaName ... HL7スキーマ名
+ MessageType ... HL7メッセージタイプ

```javascript
    Parameter SchemaName = "SS-MIX2"; 
```
```ObjectScript:MessageType
    Parameter MessageType = "ADT_A08"; 
```

Templateに埋め込んだ#()#に指定したプロパティを記述します。

```ObjectScript:property
    Property PatientId as %String;

    Property LastName as %String;

    Property FirstName as %String;
```

### データタイプテンプレートクラス

データタイプテンプレートクラスはHL7v2Template.DT.DataTypeクラスを継承し、HL7DataTypeパラメータにHL7のデータ型を指定します。また、Template パラメータにHL7フィールドのフォーマットを記述します。

+ HL7DataType パラメータ ... HL7v2でのデータタイプを表します。
+ Template パラメータ ... 出力するフィールドフォーマットを表します。

例

```
Class HL7v2Template.DT.CQ Extends HL7v2Template.DT.DataType
{

/// HL7データタイプの指定
Parameter HL7DataType = "CQ";

Parameter Template = "#(..Quantity)#^#(..Code)#&#(..Text)#&#(..System)#";

Property Quantity As %Numeric;

Property Code As %String;

Property Text As %String;

```

## テンプレート出力方法

テンプレートクラスを使って、HL7メッセージを出力する手順は以下の通り

1. テンプレートクラスのインスタンスを作成します。
```
  set obj=##class(HL7v2Template.ADTA08).%New()
```
2. プロパティを設定します。
```
  set obj.FirstName="太郎"
  set obj.LastName="山田"
  set obj.Gender="M"
  set obj.DOB="1997-01-25"

```

3. 出力メソッドを実行します。

```
  set ret=obj.OutputToStream(obj,stream)
  set ret=obj.OutputToFile(obj,"export.hl7")
```

## テンプレート記述ルール

テンプレートの記述にはプロパティの受け持つ範囲の違いにより、以下の記述方法があります。
+ セグメントグループ
  セグメントグループから抜けるまでプロパティのテンプレートを使用して値を取得しプロパティに代入します。
  記述方法:

```ObjectScript:property
  "セグメント名 | #(..プロパティ名)#" ````
```

+ セグメント
  指定されたセグメントに対応するプロパティのテンプレートを使用して値を取得し、プロパティに代入します。
  記述方法:

```ObjectScript:property
  "セグメント名 | #(..プロパティ名)#" ````
```
+ フィールド
  指定されたフィールドからHL7データタイプに応じたクラスのテンプレートからプロパティ値を取得します。

```ObjectScript:property
  "セグメント名 |...|#(..プロパティ名)#|..."
```
+ データエレメント
  データタイプの指定された項目からプロパティ値を取得

```ObjectScript:property
  "セグメント名 |...|^^#(..プロパティ名)#^^^|..."
```
## 記述例

記述例は HL7v2Template.Test　パッケージ内を参照してください。

