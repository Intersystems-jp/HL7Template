Include %occErrors

Class HL7v2Template.Base Extends %RegisteredObject [ Abstract ]
{

/// 改行コード
Parameter LineTerminator = {$c(13)};

/// HL7 スキーマ名
Parameter SchemaName;

/// メッセージタイプ
Parameter MessageType;

/// キャラクターセット(ISO IR87)
Property CharSet As %String;

Property MsgType As %String;

Property MsgTime As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3)} ];

XData Template [ MimeType = application/json ]
{
[
	"MSH|^~\\&|IRIS|HIS|GW|GW|#(..MsgTime)#||#(..MsgType)#|563233|P|2.5||||||~#(..CharSet)#||ISO 2022-1994"
 
]
}

ClassMethod ParseStream(ByRef obj, stream As %Stream.Object) As %Status
{
	set:..#LineTerminator'="" stream.LineTerminator=..#LineTerminator
	set ret=$$$OK,tokenno=0,msh=1
	set:'$data(obj) obj=..%New()
	while 'stream.AtEnd {
		set line=$replace(stream.ReadLine(),$c(10),"")
		continue:line=""
		set ret=..ParseSegment(.obj,line,.tokenno)
		quit:$$$ISERR(ret)
		if msh {
			set msh=0
			if $piece(line,"|")="MSH"&&(obj.CharSet="ISO IR87") set stream.TranslateTable="JIS"
		}
	}
	quit ret
}

ClassMethod ParseFile(ByRef obj, file As %String) As %Status
{
	set ret=$$$OK
	set stream = ##class(%Stream.FileCharacter).%New()
	set ret=stream.LinkToFile(file)
	quit:$$$ISERR(ret) ret
	
	quit ..ParseStream(.obj,stream)
}

/// HL7の解析
/// テンプレートから生成
ClassMethod ParseSegment(ByRef obj, segment As %String, ByRef tokenno As %String) As %Status [ CodeMode = objectgenerator ]
{
    // Abstractクラスの場合は生成しない
    if %class.Abstract {
        do %code.WriteLine(" set ret=$$$NotImplemented quit ret")
        quit $$$OK
    }
    
    set ret=$$$OK,lineno=0
    try {
        set %debug=$get(%debug,0)
	    // スキーマ名、メッセージタイプのチェック
	    set schema=%parameter("SchemaName")
	    if schema=""||('$data(^EnsHL7.Schema(schema))) {
		    set ret=$$$ERROR(5001,"スキーマ名が誤っています SchemaName="_schema)
		    quit
	    }
	    set msgtyp=%parameter("MessageType"),map=""
	    set:msgtyp["." map=$piece(msgtyp,".",2,*),msgtyp=$piece(msgtyp,".")
	    if msgtyp=""||('$data(^EnsHL7.Schema(schema,"MT",msgtyp),msgstr)) {
		    set ret=$$$ERROR(5001,"メッセージタイプが誤っています Schema="_schema_" MessageType="_msgtyp)
			quit
	    }
	    set:msgstr'="" schema=$piece(msgstr,":"),msgtyp=$piece(msgstr,":",2)
	    if '$data(^EnsHL7.Schema(schema,"MS",msgtyp)) {
		    set ret=$$$ERROR(5001,"メッセージ構造データがありません Schema="_schema_" MessageType="_msgtyp)
			quit
	    }
	    set array=""
	    if map'="" {
		    if '$data(^EnsHL7.Schema(schema,"MS",msgtyp,"map",map),mapdata) {
			    set ret=$$$ERROR(5001,"メッセージマップが誤っています MessageMap="_map)
		    	quit
		    }
		    set array=$replace($extract($piece(mapdata,"|"),2,*),",*","")
		    
		    
	    }

        // プロパティとパラメータの一覧を取得
        set generator=##class(HL7v2Template.Generator).%New()
        set ret=generator.GetMemberList(%compiledclass)
        quit:$$$ISERR(ret)

        do %code.WriteLine("	set ret=$$$OK try {")
        // objが定義されていなければインスタンスを作成する
        //do %code.WriteLine(" if '$data(obj)||(obj="""") set obj=..%New()")

		// セグメント名の取得
		do %code.WriteLine(" set segname=$zcvt($piece(segment,""|""),""U"")")

        // OnPreParse()メソッドがあれば呼び出す
        set mdef=##class(%Dictionary.CompiledMethod).%OpenId(%class.Name_"||OnPreParse")
        if $isobject(mdef)&&(mdef.Implementation.Size>0) {
            do %code.WriteLine(" set ret=..OnPreParse(obj) quit:$$$ISERR(ret)")
        }

        // JSONからオブジェクトを作成
        // テンプレートを読み込む
        Set compiledXdata=##class(%Dictionary.CompiledXData).%OpenId(%class.Name_"||Template")
        set tplstm=compiledXdata.Data
        do tplstm.Rewind()
        
        // JSONからオブジェクトを作成
        set tpl={}.%FromJSON(tplstm)
        if 'tpl.%IsA("%DynamicArray") {
            set ret=$$$ERROR(5001,"テンプレートの内容がJSON array形式ではありません")
            quit
        }
        // HL7パーサーの生成
        // **todo: HL7 メッセージの一部を解析できるようにする
        set ret=generator.GenerateParser(schema,msgtyp,map,tpl)
        quit:$$$ISERR(ret)

        do generator.outstream.Rewind()
        while 'generator.outstream.AtEnd {
            set line=generator.outstream.ReadLine()
                do %code.WriteLine(line)
        }

		do %code.WriteLine(" set ret=$$$ERROR(5001,""構文誤り：セグメント""_segname_""は""_$select($data(tokenno(""name""),prevseg):""セグメント""_prevseg_""の後に"",1:""最初に"")_""指定出来ません"")")
        do %code.WriteLine(" } catch err { set ret=err.AsStatus() }")
        do %code.WriteLine(" quit ret")

    } catch err {
        set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
    }
    quit ret
}

/// HL7の出力
/// テンプレートからストリームに出力する処理を生成
ClassMethod OutputToStream(obj As %RegisteredObject, stream As %Stream.Object) As %Status [ CodeMode = objectgenerator ]
{
    // Abstractクラスの場合は生成しない
    if %class.Abstract {
        do %code.WriteLine(" set ret=$$$NotImplemented quit ret")
        quit $$$OK
    }
    
    set ret=$$$OK,lineno=0
    try {
        set %debug=$get(%debug,0)
	    // スキーマ名、メッセージタイプのチェック
	    set schema=%parameter("SchemaName")
	    if schema=""||('$data(^EnsHL7.Schema(schema))) {
		    set ret=$$$ERROR(5001,"スキーマ名が誤っています SchemaName="_schema)
		    quit
	    }
	    set msgtyp=%parameter("MessageType"),map=""
	    set:msgtyp["." map=$piece(msgtyp,".",2,*),msgtyp=$piece(msgtyp,".")
	    if msgtyp=""||('$data(^EnsHL7.Schema(schema,"MT",msgtyp),msgstr)) {
		    set ret=$$$ERROR(5001,"メッセージタイプが誤っています Schema="_schema_" MessageType="_msgtyp)
			quit
	    }
	    set:msgstr'="" schema=$piece(msgstr,":"),msgtyp=$piece(msgstr,":",2)
	    if '$data(^EnsHL7.Schema(schema,"MS",msgtyp)) {
		    set ret=$$$ERROR(5001,"メッセージ構造データがありません Schema="_schema_" MessageType="_msgtyp)
			quit
	    }
	    set array=""
	    if map'="" {
		    if '$data(^EnsHL7.Schema(schema,"MS",msgtyp,"map",map),mapdata) {
			    set ret=$$$ERROR(5001,"メッセージマップが誤っています MessageMap="_map)
		    	quit
		    }
		    set array=$replace($extract($piece(mapdata,"|"),2,*),",*","")
		    
		    
	    }

        // プロパティとパラメータの一覧を取得
        set generator=##class(HL7v2Template.Generator).%New()
        set ret=generator.GetMemberList(%compiledclass)
        quit:$$$ISERR(ret)

        do %code.WriteLine(" set ret=$$$OK try {")
		do %code.WriteLine("	set:'($isobject(stream)) stream=##class(%Stream.TmpCharacter).%New()")
		do %code.WriteLine("	set:..#LineTerminator'="""" stream.LineTerminator=..#LineTerminator")

        // OnPreProcess()メソッドがあれば呼び出す
        set mdef=##class(%Dictionary.CompiledMethod).%OpenId(%class.Name_"||OnPreProcess")
        if $isobject(mdef)&&(mdef.Implementation.Size>0) {
            do %code.WriteLine(" set ret=..OnPreProcess(obj) quit:$$$ISERR(ret)")
        }

        // JSONからオブジェクトを作成
        // テンプレートを読み込む
        Set compiledXdata=##class(%Dictionary.CompiledXData).%OpenId(%class.Name_"||Template")
        set tplstm=compiledXdata.Data
        do tplstm.Rewind()
        
        // JSONからオブジェクトを作成
        set tpl={}.%FromJSON(tplstm)
        if 'tpl.%IsA("%DynamicArray") {
            set ret=$$$ERROR(5001,"テンプレートの内容がJSON array形式ではありません")
            quit
        }
        // HL7メッセージの生成
		set generator.outstream=##class(%Stream.TmpCharacter).%New()
        set ret=generator.GenerateMessage(schema,msgtyp,map,tpl)
        quit:$$$ISERR(ret)

		// 出力処理の書き出し
        do generator.outstream.Rewind()
        while 'generator.outstream.AtEnd {
            set line=generator.outstream.ReadLine()
                do %code.WriteLine(line)
        }

        do %code.WriteLine(" } catch err { set ret=err.AsStatus() }")
        do %code.WriteLine(" quit ret")

    } catch err {
        set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
    }
    quit ret
}

/// HL7の出力
/// テンプレートからファイルに出力
/// ストリーム出力を利用
ClassMethod OutputToFile(obj As %RegisteredObject, file As %String) As %Status
{
	set stream=##class(%Stream.FileCharacter).%New()
	set ret=stream.LinkToFile(file,"WNS")
	quit:$$$ISERR(ret) ret
	set ret=..OutputToStream(obj,stream)
	quit ret
}

}
