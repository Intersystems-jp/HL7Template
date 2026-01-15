Include %occErrors

/// MSGデータタイプ
Class HL7v2Template.DT.DataType Extends %RegisteredObject [ Abstract ]
{

/// HL7データタイプの指定
Parameter HL7DataType;

/// データタイプのパーサー用テンプレート
Parameter Template;

/// 指定したデータタイプへの変換
ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	quit HL7value
}

/// 指定したデータをHL7の形式に変換
ClassMethod ConvertToHL7(datatype As %String, value As %String) As %DataType
{
	quit value
}

/// データのパース
/// 変数fieldに入れられたデータを解析する
ClassMethod ParseData(obj, field As %String) As %Status [ CodeMode = objectgenerator ]
{
	// Abstractクラスの場合は生成しない
    if %class.Abstract {
        do %code.WriteLine(" set ret=$$$NotImplemented quit ret")
        quit $$$OK
    }
    
    set ret=$$$OK,lineno=0
    try {
        set %debug=$get(%debug,0)

	    set template=##class(%Dictionary.CompiledParameter).%OpenId(%class.Name_"||Template").Default
	    set datatype=##class(%Dictionary.CompiledParameter).%OpenId(%class.Name_"||HL7DataType").Default

		write:%debug "template:"_template,!
		write:%debug "datatype:"_datatype,!
		
	    if template="" {
    	    do %code.WriteLine(" set ret=$$$NotImplemented quit ret")
        	quit
    	}

        // プロパティとパラメータの一覧を取得
        set generator=##class(HL7v2Template.Generator).%New()
        set ret=generator.GetMemberList(%compiledclass)
        quit:$$$ISERR(ret)

        do %code.WriteLine(" set ret=$$$OK try {")

        // OnPreParse()メソッドがあれば呼び出す
        set mdef=##class(%Dictionary.CompiledMethod).%OpenId(%class.Name_"||OnPreParse")
        if $isobject(mdef)&&(mdef.Implementation.Size>0) {
            do %code.WriteLine(" set ret=..OnPreParse(obj) quit:$$$ISERR(ret)")
        }
        // HL7パーサーの生成
        set generator.pgm=""
        set ret=generator.ParseDataType(datatype,template)
        quit:$$$ISERR(ret)

        do %code.WriteLine("  "_generator.pgm)


        do %code.WriteLine(" } catch err { set ret=err.AsStatus() }")
        do %code.WriteLine(" quit ret")

    } catch err {
        set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
    }
    quit ret
}

/// HL7形式の出力
/// Templateパラメータの内容に従ってメッセージを出力する
ClassMethod GenerateData(obj) As %String [ CodeMode = objectgenerator ]
{
	// Abstractクラスの場合は生成しない
	if %class.Abstract {
		do %code.WriteLine("	quit """"")
		quit $$$OK
	}

	set ret=$$$OK,lineno=0
	try {
		set %debug=$get(%debug,0)

		set template=##class(%Dictionary.CompiledParameter).%OpenId(%class.Name_"||Template").Default
		set datatype=##class(%Dictionary.CompiledParameter).%OpenId(%class.Name_"||HL7DataType").Default

		write:%debug "template:"_template,!
		write:%debug "datatype:"_datatype,!

		if template="" {
			do %code.WriteLine("	quit """"")
			quit
		}

		// プロパティ一覧の取得
		set generator=##class(HL7v2Template.Generator).%New()
		set ret=generator.GetMemberList(%compiledclass)
		quit:$$$ISERR(ret)

		do %code.WriteLine("	set ret=""""")
		do %code.WriteLine("	try {")

		// OnPreProcess()があれば呼び出す
		set mdef=##class(%Dictionary.CompiledMethod).%OpenId(%class.Name_"||OnPreProcess")
		if $isobject(mdef)&&(mdef.Implementation.Size>0) {
			do %code.WriteLine("		set stat=..OnPreProcess(obj)")
			do %code.WriteLine("		if $$$ISERR(stat) quit")
		}
		// HL7データ生成コード
		set generator.pgm=""
		set ret=generator.GenerateDataType(datatype,template,"ret")
		quit:$$$ISERR(ret)

		set line=""
		for i=1:1:$length(generator.pgm,$char(10)) {
			set line=$piece(generator.pgm,$char(10),i)
			do %code.WriteLine(line)
		}

		do %code.WriteLine("	} catch err { set ret="""" }")
		do %code.WriteLine("	quit ret")

	} catch err {
		set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
	}
	quit ret
}

}
