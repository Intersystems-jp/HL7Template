Class HL7v2Template.Test.CodeSet.Units Extends (%Persistent, HL7v2Template.DT.CodeSet)
{

Index CodeIndex On Code [ IdKey, Unique ];

Storage Default
{
<Data name="UnitsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Text</Value>
</Value>
<Value name="3">
<Value>System</Value>
</Value>
</Data>
<DataLocation>^HL7v2Template.Test.C9F11.UnitsD</DataLocation>
<DefaultData>UnitsDefaultData</DefaultData>
<IdLocation>^HL7v2Template.Test.C9F11.UnitsD</IdLocation>
<IndexLocation>^HL7v2Template.Test.C9F11.UnitsI</IndexLocation>
<StreamLocation>^HL7v2Template.Test.C9F11.UnitsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
