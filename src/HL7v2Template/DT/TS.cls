/// MSGデータタイプ
Class HL7v2Template.DT.TS Extends DataType
{

Parameter HL7DataType = "TS";

ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	if datatype="%Library.TimeStamp" {
		set year=$extract(HL7value,1,4),month=$extract(HL7value,5,6),day=$extract(HL7value,7,8)
			,hour=$extract(HL7value,9,10),minute=$extract(HL7value,11,12),second=$extract(HL7value,13,14)
		quit $select(year>0:year,1:1870)_"-"_$select(month>0:month,1:"01")_"-"_$select(day>0:day,1:"01")_" "
			_$select(hour>0:hour,1:"00")_":"_$select(minute>0:minute,1:"00")_":"_$select(second>0:second,1:"00")
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
