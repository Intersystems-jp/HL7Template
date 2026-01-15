/// MSGデータタイプ
Class HL7v2Template.DT.IS Extends DataType
{

Parameter HL7DataType = "IS";

ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	if datatype="%Library.TimeStamp" {
		
		quit $extract(HL7value,1,4)_"-"_$extract(HL7value,5,6)_"-"_$extract(HL7value,7,8)_" "_$extract(HL7value,9,10)_":"_$extract(HL7value,11,12)_":"_$extract(HL7value,13,14)
	}
	if datatype="%Library.Date" {
		quit $zdateh($extract(HL7value,1,8),8)
	}
	quit HL7value
}

/// 指定したデータをHL7の形式に変換
ClassMethod ConvertToHL7(datatype As %String, value As %String) As %DataType
{
	if datatype="%Library.TimeStamp" {
		quit $translate(value,"-: ","")
	}
	if datatype="%Library.Date" {
		quit $zdate(value,8)
	}
	quit value
}

}
