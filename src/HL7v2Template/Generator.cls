Class HL7v2Template.Generator Extends %RegisteredObject
{

Parameter DataTypePackage = "HL7v2Template.DT";

/// 出力データ
Property outstream As %Stream.TmpCharacter;

/// JSON文字列
Property jsonstring [ MultiDimensional ];

/// プロパティ一覧
/// props(プロパティ名)=$lb(プロパティクラス,クライアントデータタイプ,Requiredかどうか,コレクションかどうか,LogicalToDisplayを使用するかどうか)
Property props [ MultiDimensional ];

/// パラメータ一覧
Property params [ MultiDimensional ];

/// HL7スキーマ名
Property schema As %String;

/// HL7メッセージ構造
Property msgtyp As %String;

///  HL7セグメント位置
Property array [ MultiDimensional ];

/// HL7セグメントソース
Property segment [ MultiDimensional ];

/// データタイプ生成ソース
Property pgm As %String(MAXLEN = "");

/// HL7パーサー生成
/// TemplateのHL7メッセージに#(..プロパティ名)#または#(..#パラメータ名)#を指定することで
/// 読み込んだデータをプロパティにセットします。
/// schema HL7スキーマ名、msgtyp ... メッセージタイプ、map ... セグメントマップ
/// 出力データ：
/// 			..array(セグメント名,トークン番号)=$lb(セグメント定義名,必須項目flg,ループflg,前回トークン番号,最大トークン番号)
///       前回トークン番号: 直前アクセスした必須項目のトークン番号。この番号以降のトークンからの遷移を認める
///       最大トークン番号: この番号以前のトークンからの遷移を求める。
Method GenerateParser(schema As %String, msgtyp As %String, map As %String, template As %DynamicAbstractObject) As %Status
{
	set %debug=0
    set ret=$$$OK
    try {

		// EnsHL7.Schemaからメッセージの定義を取得		
		set msgdef=$listfromstring(^EnsHL7.Schema(schema,"MS",msgtyp),"~")
		set cnt=0,layer=1,ptr=0,req=1,loop=0,lastlayer=0,lastseg=0
		while $listnext(msgdef,ptr,value) {
			set cnt=cnt+1
			if value="[" {
				set layer=layer+1
				if $data(layer(layer)) {
					set req=0
				}
				continue
			}
			if value="]" {
				if $data(layer(layer)) {
					set req=1
					set lastlayer=layer(layer,"lastlayer")
					kill layer(layer)
				}
				set layer=layer-1
				continue
			}
			if value="{" {
				set layer=layer+1
				set loop=1
				continue
			}
			if value="}" {
				if $data(layer(layer)) {
					if layer(layer,"startsegno")'=lastseg {
						set $li(..array(layer(layer,"startsegname"),layer(layer,"startsegno")),5)=lastseg
					}
					set lastlayer=layer(layer,"lastlayer")
					kill layer(layer)
				}
				set layer=layer-1
				continue
			}
			set segname=$select(value[":":$piece(value,":",2),1:value)
			// 開始位置が無い場合、代入
			if '$data(layer(layer)) {
				set layer(layer,"startsegno")=cnt
				set layer(layer,"startsegname")=segname
				set layer(layer,"lastreqseg")=cnt
				set layer(layer,"req")=req
				set layer(layer,"loop")=loop
				set layer(layer,"lastlayer")=lastlayer
			}
			write:%debug !,"seg:",segname," - ",cnt
			set ..array(segname,cnt)=$lb(value,req,loop,$get(layer(lastlayer,"lastreqseg"),0),cnt,layer(layer,"startsegno"))
			set loop=0
			set lastseg=cnt
			set lastlayer=layer
			if $data(layer(layer))&&req {
				set layer(layer,"lastreqseg")=cnt
			}
		}
		
		set ..schema=schema,..msgtyp=msgtyp
		set tokenno=0

        // templateのメンバーを順に取り出す
        set iter=template.%GetIterator()
#if $SYSTEM.Version.GetMajor()>2021
        while iter.%GetNext(.mkey,.value,.mtype) {
#Else
        while iter.%GetNext(.mkey,.value) {
            set mtype=$select($isobject(value):$select(value.%IsA("%DynamicArray"):"array",1:"object"),1:"string")
#Endif
            if mtype="object" {
                // メンバーがオブジェクトの場合
                if value.method'="" {
		            // 実行処理の追加
	    	        set ret=..AddMethod(value.method)
    	            quit:$$$ISERR(ret)
    		        continue
                }
                if value.condition'="" {
                }
             	continue
            } elseif mtype="string" {

	            // セグメント名を取得
		        set segname=$zcvt($piece(value,"|"),"U")

				// 同じセグメント名が複数ある場合、前回のトークン番号から正しいトークン番号を求める		        
		        set segno="" for {
			        set segno=$order(..array(segname,segno),1,data)
			        quit:segno=""

					if tokenno=0||(tokenno>=$lg(data,4)&&(tokenno<=$lg(data,5))) {
						set ret=..ParseSegment($lg(data,1),segno,value)
						quit:$$$ISERR(ret)
					}
			        set tokenno=segno
		        }
		        quit:$$$ISERR(ret)
    	        continue
           } elseif mtype="array" {
				set ret=$$$ERROR(5001,"テンプレートの形式が誤っています")
				quit
           }
#if $SYSTEM.Version.GetMajor()>2021
        }
#else
        }
#endif
		if %debug {
			merge array=..array zw array kill array
			merge segment=..segment zw segment kill segment	
		}
		quit:$$$ISERR(ret)

		// プログラムの出力
		// セグメントグループの処理
		set tokenno="" for {
			set tokenno=$order(..segment("*",tokenno),1,seg)
			quit:tokenno=""
			set def=..array(seg,tokenno)
			do ..outstream.WriteLine(" if (tokenno>="_tokenno_")&&(tokenno<"_$select($lg(def,3):"=",1:"")_$lg(def,5)_") {")
			do ..outstream.WriteLine(" /* "_seg_":"_tokenno_" */")
			do ..outstream.WriteLine(..segment("*",tokenno,"trans"))
			do ..outstream.WriteLine(" quit:ret'="""" }") // 該当処理が無かった場合、このクラスで判定させる
		}
		kill ..segment("*")

		set seg="" for {
			set seg=$order(..array(seg))
			quit:seg=""
			
			set tokenno="" for {
				set tokenno=$order(..array(seg,tokenno),1,def)
				quit:tokenno=""
				
				set def=..array(seg,tokenno)
				do ..outstream.WriteLine(" if segname="""_seg_"""&&(tokenno>="_$lg(def,4)_")&&(tokenno<"_$select($lg(def,3):"=",1:"")_$lg(def,5)_") {")
				do ..outstream.WriteLine(" /* "_seg_":"_tokenno_" */")
	
				// データ解析が必要なセグメント
				if $data(..segment(seg,tokenno),cnt) {
					if cnt>1 {
						// 一意に決まる条件を求める
						set cond="" for {
							set cond=$order(..segment(seg,tokenno,"cond",cond),1,condcnt)
							quit:cond=""
							
							quit:cnt=condcnt
						}
						if cond'="" {
							for seq=1:1:cnt {
								if $data(..segment(seg,tokenno,"cond",cond,"type")) {
									do ..outstream.Write(" if ##class("_..#DataTypePackage_"."_..segment(seg,tokenno,"cond",cond,"type")_").ConvertFromHL7(""%Library.String"",$piece(segment,""|"","_cond_"))")
								} else {
									do ..outstream.Write(" if $piece(segment,""|"","_cond_")")
								}
								do ..outstream.WriteLine("="""_$get(..segment(seg,tokenno,"cond",cond,"seq",seq))_""" {")
								set elem="" for {
									set elem=$order(..segment(seg,tokenno,"trans",elem))
									quit:elem=""
									do:$data(..segment(seg,tokenno,"trans",elem,seq),line) ..outstream.WriteLine("  "_line)
								}
								do ..outstream.WriteLine(" }")
							}
						}
					} else {
						// １レコードしかない場合
						set elem="" for {
							set elem=$order(..segment(seg,tokenno,"trans",elem))
							quit:elem=""
							do ..outstream.WriteLine("  "_..segment(seg,tokenno,"trans",elem,1))
						}
					}
				}
				do ..outstream.WriteLine(" set tokenno="_tokenno_",tokenno(""name"")="""_seg_""" quit }")
			}
		}
    } catch err {
        set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
    }
    quit ret
}

Method AddMethod(name As %String) As %Status
{
	quit $$$OK
}

/// セグメント内の解析処理を生成
/// segname ... スキーマ名 : セグメント名
/// tokenno ... そのセグメントのトークン番号
/// segment ... テンプレートのセグメントデータ
Method ParseSegment(segname As %String, tokenno As %String, segment As %String) As %Status
{
	write:%debug "ParseSegment:"_segname_":"_tokenno,!
	set ret=$$$OK
	set schema=$piece(segname,":"),segname=$piece(segname,":",2)
	set def=^EnsHL7.Schema(schema,"SS",segname)
	set segdata=$listfromstring(segment,"|")
	// セグメント全体を指定している場合
	if $listlength(segdata)=2&&($lg(segdata,2)?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#") {
		// プロパティの取得
		set prop=$piece($piece(segdata,"..",2),")#"),class=""
		if prop["(" {
			set class=$piece($piece(prop,")"),"(",2)
			set prop=$piece(prop,"(")
			set:$extract(class)="." class=%class.Name_class
			set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
		}
		if '$data(..props(prop),propdef) {
			quit $$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
		}
		if class'=""&&('##class(%Dictionary.ClassDefinition).%ExistsId(class)) {
			quit $$$ERROR(5001,"クラス「"_class_"」が存在しません")
		}
			
		//プロパティのデータタイプを取得
		set proptype=$lg(propdef)
		if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
			quit $$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
		}
		// データプロパティの場合はエラーとする
		if $lg(propdef,2)'="" {
			quit $$$ERROR(5001,"プロパティ"_prop_"はデータタイプのため、セグメントに割り当てることは出来ません")
		}
		// プロパティ設定コードを作成
		set colprop=($lg(propdef,4)="list")
		write:%debug "segment prop:"_prop_" colprop:"_colprop,!
		
		if colprop {
			set setpropcode=" set prop=##class("_proptype_").%New()"
		} else {
			set setpropcode=" do:'$isobject(obj."_prop_") obj."_prop_"NewObject()"
		}
		set setpropcode=setpropcode_" set ret=##class("_
			$select(class'="":class,1:proptype)_").ParseSegment("_$select(colprop:"prop",1:"obj."_prop)_",segment,.tokenno) quit:$$$ISERR(ret) "
		// オブジェクトを登録する
		if colprop {
			set setpropcode=setpropcode_ " do obj."_prop_".Insert(prop)"
		} else {
			//set setpropcode=setpropcode_ " set obj."_prop_"=prop"
		}
		set ..segment("*",tokenno)=segname,..segment("*",tokenno,"trans")=setpropcode
		set ..segment(segname,tokenno)=1
		set ..segment(segname,tokenno,"trans",1,1)=setpropcode
		quit ret
	}
	set ptr=0,elem=1,defptr=0
	// セグメント名の取得
	if '$listnext(segdata,ptr,seg) {
		quit $$$ERROR(5001,"セグメント名が取得できませんでした")
	}
	quit:segname'=$zcvt(seg,"U") $$$ERROR(5001,"セグメント名がセグメントデータと異なります")
	if segname="MSH"&&('$listnext(def,defptr,type)) {
		set ret=$$$ERROR(5001,"セグメント情報が誤っています field="_segname)
		quit ret
	}

	/// シーケンス番号を取得
	set seq=$increment(..segment(segname,tokenno))
		
	// セグメントの各エレメントを解析
	while $listnext(segdata,ptr,value) {
	//for ptr=2:1:$listlength(segdata) { set value=$listget(segdata,ptr)
		set elem=elem+1
		if '$listnext(def,defptr,type) {
			set ret=$$$ERROR(5001,"セグメント情報が定義と異なっています segment="_segname_"."_elem)
			quit
		}
		continue:value=""
		if value'["#(" {
			//セグメントの判定条件として使用する
			if value'="" {
				set datatype=$piece($lg(type),":",2)
				// HL7データタイプが定義されていなければdatatypeで変換しない
				set:'##class(%Dictionary.ClassDefinition).%ExistsId(..#DataTypePackage_"."_datatype) datatype=""

				if datatype'="" {
					set value2=$classmethod(..#DataTypePackage_"."_datatype,"ConvertFromHL7","%Library.String",value)
					set:value2'="" value=value2
				}
				if '$data(..segment(segname,tokenno,"cond",elem,"value",value)) {					
					set ..segment(segname,tokenno,"cond",elem,"value",value)=""
					set:datatype'="" ..segment(segname,tokenno,"cond",elem,"type")=datatype // HL7データタイプのConvertFromHL7()を呼び出すために保存
					set dummy=$increment(..segment(segname,tokenno,"cond",elem))
				}
				set ..segment(segname,tokenno,"cond",elem,"seq",seq)=value
			}
			continue
		}
		if value?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#" {
			write:%debug "field:"_segname_"-",elem,!
			// フィールド全体をプロパティにコピーする場合
			set prop=$piece($piece(value,"..",2),")#"),class=""
			if prop["(" {
				set class=$piece($piece(prop,")"),"(",2)
				set prop=$piece(prop,"(")
				set:$extract(class)="." class=%class.Name_class
				set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
			}
			if '$data(..props(prop),propdef) {
                set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
	            quit
			}
			if class'=""&&('##class(%Dictionary.ClassDefinition).%ExistsId(class)) {
                set ret=$$$ERROR(5001,"クラス「"_class_"」が存在しません")
	            quit
			}
			// HL7データタイプの取得
			set datatype=$lg(type),dtschema=$piece(datatype,":"),datatype=$piece(datatype,":",2)
			
			//プロパティのデータタイプを取得
			set proptype=$lg(propdef)
			if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
				set ret=$$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
				quit
			}
			// プロパティ設定コードを作成
			set objprop=($lg(propdef,2)=""),colprop=($lg(propdef,4)="list"),rep=$lg(type,6) // HL7 DataType Repeatable
			write:%debug "prop:"_prop_" colprop:"_colprop,!
			set propvar=$select(colprop:"prop",1:"obj."_prop),fieldsrc="$piece(segment,""|"","_elem_")"
			if colprop {
				if rep {
					set setpropcode=" set field="_fieldsrc_" for f=1:1:$length(field,""~"") { set elem=$piece(field,""~"",f),prop="_$select(objprop:"##class("_proptype_").%New()",1:"""""")
					set fieldsrc="elem"
				} else {
					set setpropcode=" set field="_fieldsrc_",prop="_$select(objprop:"##class("_proptype_").%New()",1:"""""")
				}
			} else {
				set setpropcode=$select(objprop:" do:'$isobject("_propvar_") "_propvar_"NewObject()",1:"")
			}
			set initpropcode=$select(colprop:" set prop="_$select(objprop:"##class("_proptype_").%New()",1:""""""),1:"")
			// パラメータを取得し、HL7データタイプのチェック
			set paramdef=##class(%Dictionary.CompiledParameter).%OpenId(proptype_"||HL7DataType")
			if $isobject(paramdef)&&(paramdef.Default=datatype) {
				set setpropcode=setpropcode_" set ret=##class("_proptype_").ParseData("_propvar_","_fieldsrc_")"
			} else {
				set setpropcode=setpropcode_" set "_propvar_"="_$select(datatype'=""||(class'=""):"##class("_
					$select(class'="":class,1:..#DataTypePackage_"."_datatype)_").ConvertFromHL7("""_$lg(..props(prop))_""",",1:"(")_fieldsrc_")"
			}
			// プロパティがオブジェクトの場合、インスタンスを作成するコードを追加
			if colprop {
				set setpropcode=setpropcode_ " do obj."_prop_".Insert(prop)"_$select(rep:" }",1:"")
			}
			set ..segment(segname,tokenno,"trans",elem,seq)=setpropcode
			continue
		}
		// データタイプの解析
			
		write:%debug "data type:"_segname_"-",elem,!
		set ret=..ParseDataType($lg(type),value,"$piece(segment,""|"","_elem_")")
		quit:$$$ISERR(ret)
		set ..segment(segname,tokenno,"trans",elem,seq)=" set field=$piece(segment,""|"","_elem_")"_..pgm
		continue
		
	}
	quit ret
}

/// データタイプの解析
Method ParseDataType(datatype As %String, template As %String, var As %String) As %Status
{
	set ret=$$$OK
	if template["~" {
		set cond="",trans=""
		// 複数エントリある場合は、テンプレートの固定値でどちらのテンプレートを使用するかを判断する
		set loopcnt=$length(template,"~")
		for loop=1:1:loopcnt {
			set elem=$piece(template,"~",loop)
			set cnt=0
			for f=1:1:$length(elem,"^") {
				set field=$piece(elem,"^",f)
				
				continue:field=""
				
				if field'?1"#(.."1A.AN1")#" {
					set:'$data(cond(f,field)) cond(f,field,loop)=$increment(cond(f)),condx(f,loop)=field
					continue
				}
				set prop=$piece($piece(field,"..",2),")#")
				if '$data(..props(prop),propdef) {
	                set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
		            quit
				}
				set trans(loop)=$select(cnt=0:" set ",1:trans(loop)_",")_"obj."_prop_"=$piece(rec,""^"","_f_")",cnt=cnt+1
			}
			quit:$$$ISERR(ret)
		}
		quit:$$$ISERR(ret) ret
		zw:%debug cond,trans
		
		// 条件に使える固定値を取得
		set f="" for {
			set f=$order(cond(f),1,cnt)
			quit:f=""
			quit:cnt=loopcnt
		}
		
		// 使える固定値があれば、その値を条件式に追加
		if f'="" {
			set ..pgm=" for r=1:1:$length(field,""~"") { set rec=$piece(field,""~"",r)"
			for loop=1:1:loopcnt {
				set:$data(trans(loop)) ..pgm=..pgm_" if $piece(rec,""^"","_f_")="""_condx(f,loop)_""" {"_trans(loop)_" continue }"
			}
			set ..pgm=..pgm_" }"
		} else {
			// 使える固定値がなければ順番で取得
			set ..pgm=""	
			for loop=1:1:loopcnt {
				set:$data(trans(loop)) ..pgm=..pgm_" set rec=$piece(field,""~"","_loop_")"_trans(loop)
			}
		}
		quit $$$OK
	}
	// ループが無い場合
	set ..pgm="",cnt=0
	for f=1:1:$length(template,"^") {
		set field=$piece(template,"^",f)
		
		continue:field=""
		
		if field'?1"#(.."1A.AN1")#" {
			continue
		}
		write:%debug "field:"_f_" "_field,!
						
		set prop=$piece($piece(field,"..",2),")#")
		if '$data(..props(prop),propdef) {
            set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
            quit
		}
		set ..pgm=$select(cnt=0:" set ",1:..pgm_",")_"obj."_prop_"=$piece(field,""^"","_f_")",cnt=cnt+1
	}
	quit ret
}

/// 対象クラスのプロパティ、パラメータの一覧を取得する
/// ..props(プロパティ名)=$lb(プロパティクラス,クライアントデータタイプ,Requiredかどうか,コレクションかどうか,LogicalToDisplayを使用するかどうか)
/// ..params(パラメータ名)=$lb(値)
Method GetMemberList(compiledclass As %Dictionary.CompiledClass) As %Status
{
    set ret=$$$OK
    try {
	    // プロパティの一覧を取得
        set key="" for {
            set pdef=compiledclass.Properties.GetNext(.key)
            quit:key=""
            set tdef=##class(%Dictionary.ClassDefinition).%OpenId(pdef.Type,,.ret)
            //quit:$$$ISERR(ret)
            set display=$select(pdef.Parameters.GetAt("DISPLAYLIST")'=""||(pdef.Parameters.GetAt("FORMAT")'=""):1,1:0)
            set classtype=$select($isobject(tdef)&&(tdef.ClassType="datatype"):tdef.ClientDataType,$extract(pdef.Type)="%":tdef.ClientDataType,1:"")

            set ..props(pdef.Name)=$lb(pdef.Type,classtype,pdef.Required,pdef.Collection,display)
        }
        // パラメータの一覧を取得
        set key="" for {
            set pdef=compiledclass.Parameters.GetNext(.key)
            quit:key=""
            set ..params(pdef.Name)=$lb(pdef.Default)
        }

    } catch err {
        set ret=err.AsStatus()
    }
    quit ret
}

/// HL7メッセージ生成
/// schema HL7スキーマ名、msgtyp ... メッセージタイプ、map ... セグメントマップ
/// template ... メッセージテンプレートオブジェクト
Method GenerateMessage(schema As %String, msgtyp As %String, map As %String, template As %DynamicAbstractObject) As %Status
{
	set ret=$$$OK
	try {

		set ..schema=schema,..msgtyp=msgtyp
		set tokenno=0
		if ('($isobject(..outstream))) set ..outstream=##class(%Stream.TmpCharacter).%New()

		// セグメント一覧を取得
		set msgdef=$listfromstring(^EnsHL7.Schema(schema,"MS",msgtyp),"~")
		for ptr=1:1:$listlength(msgdef) {
			set value=$listget(msgdef,ptr)
			if (value="[")!(value="{")!(value="]")!(value="}") {
				continue
			}
			set segname=$select(value[":":$piece(value,":",2),1:value)
			set segschema=$select(value[":":$piece(value,":"),1:schema)
			set schemalist(segname)=segschema
		}
		// templateのメンバーを順に取り出す
		set iter=template.%GetIterator()
#if $SYSTEM.Version.GetMajor()>2021
		while iter.%GetNext(.mkey,.value,.mtype) {
#Else
		while iter.%GetNext(.mkey,.value) {
			set mtype=$select($isobject(value):$select(value.%IsA("%DynamicArray"):"array",1:"object"),1:"string")
#Endif
			if mtype="object" {
				continue
			} elseif mtype="string" {

				// セグメント名を取得
				set segname=$zcvt($piece(value,"|"),"U")
				write:%debug "segment:"_segname,!
				set ret=..GenerateSegment((schemalist(segname)_":"_segname),value)
				quit:$$$ISERR(ret)
				continue
			} elseif mtype="array" {
				set ret=$$$ERROR(5001,"テンプレートの形式が誤っています")
				quit
			}
#if $SYSTEM.Version.GetMajor()>2021
		}
#else
		}
#endif

	} catch err {
		set ret=$SYSTEM.Status.AppendStatus($$$ERROR(5001,"エラーが発生しました"),err.AsStatus())
	}
	quit ret
}

/// セグメント内の出力処理を生成
/// segment ... テンプレートのセグメントデータ
Method GenerateSegment(segname As %String, segment As %String) As %Status
{
	#define HL7DataType "HL7v2Template.DT.DataType"

	write:%debug "GenerateSegment:"_segname,!
	set ret=$$$OK
	set schema=$piece(segname,":"),segname=$piece(segname,":",2)
	set def=^EnsHL7.Schema(schema,"SS",segname)

	set segdata=$listfromstring(segment,"|")

	// セグメント全体を指定している場合
	if $listlength(segdata)=2&&($lg(segdata,2)?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#") {
		// プロパティの取得
		set prop=$piece($piece(segdata,"..",2),")#"),class=""
		if prop["(" {
			set class=$piece($piece(prop,")"),"(",2)
			set prop=$piece(prop,"(")
			set:$extract(class)="." class=%class.Name_class
			set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
		}
		if '$data(..props(prop),propdef) {
			quit $$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
		}
		if class'=""&&('##class(%Dictionary.ClassDefinition).%ExistsId(class)) {
			quit $$$ERROR(5001,"クラス「"_class_"」が存在しません")
		}

		//プロパティのデータタイプを取得
		set proptype=$lg(propdef)
		if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
			quit $$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
		}
		// オブジェクトプロパティのみ処理を生成させる
		// データプロパティの場合はフィールド指定として扱う
		if $lg(propdef,2)=""&&('$classmethod(proptype,"%Extends",$$$HL7DataType)) {
			set colprop=($lg(propdef,4)="list")
			set tab=$char(9),tab2=(tab_tab)
			if colprop {
				do ..outstream.WriteLine(tab_"set key=""""")
				do ..outstream.WriteLine(tab_"for {")
				do ..outstream.WriteLine(tab2_"set sub=obj."_prop_".GetNext(.key)")
				do ..outstream.WriteLine(tab2_"quit:key=""""")
				do ..outstream.WriteLine(tab2_"set ret=##class("_$select(class'="":class,1:proptype)_").OutputToStream(sub,stream)")
				do ..outstream.WriteLine(tab2_"quit:$$$ISERR(ret)")
				do ..outstream.WriteLine(tab_"}")
			} else {
				do ..outstream.WriteLine(tab_"set sub=obj."_prop)
				do ..outstream.WriteLine(tab_"set ret=##class("_$select(class'="":class,1:proptype)_").OutputToStream(sub,stream)")
				do ..outstream.WriteLine(tab_"quit:$$$ISERR(ret)")
			}
			quit ret
		}
	}
	set ptr=0,elem=1,defptr=0
	// セグメント名の取得
	if '$listnext(segdata,ptr,seg) {
		quit $$$ERROR(5001,"セグメント名が取得できませんでした")
	}
	quit:segname'=$zcvt(seg,"U") $$$ERROR(5001,"セグメント名がセグメントデータと異なります "_segname_":"_$zcvt(seg,"U"))
	if (segname="MSH")&&('$listnext(def,defptr,type)) {
		set ret=$$$ERROR(5001,"セグメント情報が誤っています field="_segname)
		quit ret
	}

	set tab=$char(9),tab2=(tab_tab)
	
	// セグメントの各エレメントを生成
	do ..outstream.WriteLine(tab_"kill field")
	while $listnext(segdata,ptr,value) {
		set elem=elem+1
		if '$listnext(def,defptr,type) {
			set ret=$$$ERROR(5001,"セグメント情報が定義と異なっています segment="_segname_"."_elem)
			quit
		}
		if (value'["#(") {
			continue
		}
		if value?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#" {
			// フィールド全体をプロパティから生成
			set prop=$piece($piece(value,"..",2),")#"),class=""
			if prop["(" {
				set class=$piece($piece(prop,")"),"(",2)
				set prop=$piece(prop,"(")
				set:$extract(class)="." class=%class.Name_class
				set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
			}
			if '$data(..props(prop),propdef) {
				set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
				quit
			}
			if class'=""&&('##class(%Dictionary.ClassDefinition).%ExistsId(class)) {
				set ret=$$$ERROR(5001,"クラス「"_class_"」が存在しません")
				quit
			}
			set datatype=$lg(type),dtschema=$piece(datatype,":"),datatype=$piece(datatype,":",2)
			set proptype=$lg(propdef)
			if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
				set ret=$$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
				quit
			}
			set paramdef=##class(%Dictionary.CompiledParameter).%OpenId(proptype_"||HL7DataType")
			set objprop=($lg(propdef,2)=""),colprop=($lg(propdef,4)="list"),rep=$lg(type,6)
			if colprop {
				do ..outstream.WriteLine(tab_"set field("_elem_")="""",key=""""")
				do ..outstream.WriteLine(tab_"for {")
				do ..outstream.WriteLine(tab2_"set sub=obj."_prop_".GetNext(.key)")
				do ..outstream.WriteLine(tab2_"quit:key=""""")
				if ((objprop)||($isobject(paramdef)&&(paramdef.Default=datatype))) {
					do ..outstream.WriteLine(tab2_"set elem=##class("_proptype_").GenerateData(sub)")
				} else {
					set convclass=$select(class'="":class,1:..#DataTypePackage_"."_datatype)
					if (((datatype'="")||(class'=""))&&(##class(%Dictionary.ClassDefinition).%ExistsId(convclass))) {
						do ..outstream.WriteLine(tab2_"set elem=##class("_convclass_").ConvertToHL7("""_proptype_""",sub)")
					} else {
						do ..outstream.WriteLine(tab2_"set elem=sub")
					}
				}
				do ..outstream.WriteLine(tab2_"set field("_elem_")=field("_elem_")_$select(field("_elem_")="""": """",1:""~"")_elem")
				do ..outstream.WriteLine(tab_"}")
			} else {
				if ((objprop)||($isobject(paramdef)&&(paramdef.Default=datatype))) {
					do ..outstream.WriteLine(tab_"set field("_elem_")=##class("_proptype_").GenerateData(obj."_prop_")")
				} else {
					set convclass=$select(class'="":class,1:..#DataTypePackage_"."_datatype)
					if (((datatype'="")||(class'=""))&&(##class(%Dictionary.ClassDefinition).%ExistsId(convclass))) {
						do ..outstream.WriteLine(tab_"set field("_elem_")=##class("_convclass_").ConvertToHL7("""_proptype_""",obj."_prop_")")
					} else {
						do ..outstream.WriteLine(tab_"set field("_elem_")=obj."_prop_"")
					}
				}
			}
			set $piece(segment,"|",elem)="""_field("_elem_")_"""
			continue
		}

		// データタイプの生成
		set ret=..GenerateDataType($lg(type),value,"field("_elem_")")
		quit:$$$ISERR(ret)
		set line="" for i=1:1:$length(..pgm,$char(10)) {
			set line=$piece(..pgm,$char(10),i)
			do ..outstream.WriteLine(line)
		}
		set $piece(segment,"|",elem)="""_field("_elem_")_"""
		continue
	}
	// セグメント出力
	do ..outstream.WriteLine(tab_"do stream.WriteLine("""_segment_""")")
	quit ret
}

/// データタイプの解析
Method GenerateDataType(datatype As %String, template As %String, var As %String) As %Status
{
	set ret=$$$OK
	set tab=$char(9),tab2=(tab_tab)
	set ..pgm=tab_"kill item"
	if template["~" {
		set loopcnt=$length(template,"~")
		for loop=1:1:loopcnt {
			set elem=$piece(template,"~",loop)
			set updateelem=0
			for f=1:1:$length(elem,"^") {
				set field=$piece(elem,"^",f)
				if field?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#" {
					set prop=$piece($piece(field,"..",2),")#"),class=""
					if prop["(" {
						set class=$piece($piece(prop,")"),"(",2)
						set prop=$piece(prop,"(")
						set:$extract(class)="." class=%class.Name_class
						set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
					}
					if '$data(..props(prop),propdef) {
						set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
						quit
					}
					set proptype=$lg(propdef)
					if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
						set ret=$$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
						quit
					}
					set paramdef=##class(%Dictionary.CompiledParameter).%OpenId(proptype_"||HL7DataType")
					set objprop=($lg(propdef,2)=""),colprop=($lg(propdef,4)="list")
					if colprop {
						set ..pgm=..pgm_$char(10)_tab_"set sub="_prop_".GetNext("""")"
						set prop="sub"
					} else {
						set prop="obj."_prop
					}
					if ((objprop)||($isobject(paramdef)&&(paramdef.Default=datatype))) {
						set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_proptype_").GenerateData("_prop_")"
					} else {
						set convclass=$select(class'="":class,1:..#DataTypePackage_"."_datatype)
						if (((datatype'="")||(class'=""))&&(##class(%Dictionary.ClassDefinition).%ExistsId(convclass))) {
							set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_convclass_").ConvertToHL7("""_datatype_""","_prop_")"
						} else {
							set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")="_prop
						}
					}
					set $piece(elem,"^",f)="""_item("_itemcnt_")_"""
					set updateelem=1
				}
			}
			if updateelem set $piece(template,"~",loop)=elem
		}
		//set fieldval=$replace(field,"""","""""")
		set ..pgm=..pgm_$char(10)_tab_"set "_var_"="""_template_""""
		
		quit ret
	}
	// ループが無い場合
	for f=1:1:$length(template,"^") {
		set field=$piece(template,"^",f)
		if field?1"#(.."1A.AN.1(1"(".1"."1A.AN1")")1")#" {
			set prop=$piece($piece(field,"..",2),")#"),class=""
			if prop["(" {
				set class=$piece($piece(prop,")"),"(",2)
				set prop=$piece(prop,"(")
				set:$extract(class)="." class=%class.Name_class
				set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
			}
			if '$data(..props(prop),propdef) {
				set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
				quit
			}
			set proptype=$lg(propdef)
			if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
				set ret=$$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
				quit
			}
			set paramdef=##class(%Dictionary.CompiledParameter).%OpenId(proptype_"||HL7DataType")
			set objprop=($lg(propdef,2)=""),colprop=($lg(propdef,4)="list")
			if colprop {
				set ..pgm=..pgm_$char(10)_tab_"set sub="_prop_".GetNext("""")"
				set prop="sub"
			} else {
				set prop="obj."_prop
			}
			if ((objprop)||($isobject(paramdef)&&(paramdef.Default=datatype))) {
				set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_proptype_").GenerateData("_prop_")"
			} else {
				set convclass=$select(class'="":class,1:..#DataTypePackage_"."_datatype)
				if (((datatype'="")||(class'=""))&&(##class(%Dictionary.ClassDefinition).%ExistsId(convclass))) {
					set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_convclass_").ConvertToHL7("""_datatype_""","_prop_")"
				} else {
					set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")="_prop
				}
			}
			set $piece(template,"^",f)="""_item("_itemcnt_")_"""
		} else {
			for e=1:1:$length(field,"&") {
				set elem=$piece(field,"&",e)
				if elem?1"#(.."1A.AN.1(1"("1A.AN1")")1")#" {
					set prop=$piece($piece(elem,"..",2),")#"),class=""
					if prop["(" {
						set class=$piece($piece(prop,")"),"(",2)
						set prop=$piece(prop,"(")
						set:$extract(class)="." class=%class.Name_class
						set:class'["." class=$piece(%class.Name,".",1,*-1)_"."_class
					}
					if '$data(..props(prop),propdef) {
						set ret=$$$ERROR(5001,"プロパティ「"_prop_"」が存在しません")
						quit
					}
					set proptype=$lg(propdef)
					if '##class(%Dictionary.CompiledClass).%ExistsId(proptype) {
						set ret=$$$ERROR(5001,"プロパティ"_prop_"の型"_proptype_"が存在しません")
						quit
					}
					set paramdef=##class(%Dictionary.CompiledParameter).%OpenId(proptype_"||HL7DataType")
					set objprop=($lg(propdef,2)=""),colprop=($lg(propdef,4)="list")
					if colprop {
						set ..pgm=..pgm_$char(10)_tab_"set sub="_prop_".GetNext("""")"
						set prop="sub"
					} else {
						set prop="obj."_prop
					}
					if ((objprop)||($isobject(paramdef)&&(paramdef.Default=datatype))) {
						set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_proptype_").GenerateData("_prop_")"
					} else {
						set convclass=$select(class'="":class,1:..#DataTypePackage_"."_datatype)
						if (((datatype'="")||(class'=""))&&(##class(%Dictionary.ClassDefinition).%ExistsId(convclass))) {
							set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")=##class("_convclass_").ConvertToHL7("""_datatype_""","_prop_")"
						} else {
							set ..pgm=..pgm_$char(10)_tab_"set item("_$increment(itemcnt)_")="_prop
						}
					}
					set $piece(field,"&",e)="""_item("_itemcnt_")_"""
				}
			}
			set $piece(template,"^",f)=field
		}
	}
	set ..pgm=..pgm_$char(10)_tab_"set "_var_"="""_template_""""
	quit ret
}

}
