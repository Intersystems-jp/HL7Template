Class HL7v2Template.Test.CodeSet.Medicine Extends (%Persistent, HL7v2Template.DT.CodeSet)
{

Index CodeIndex On Code [ IdKey, Unique ];

Storage Default
{
<Data name="MedicineDefaultData">
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
<DataLocation>^HL7v2Template.Tes9F11.MedicineD</DataLocation>
<DefaultData>MedicineDefaultData</DefaultData>
<IdLocation>^HL7v2Template.Tes9F11.MedicineD</IdLocation>
<IndexLocation>^HL7v2Template.Tes9F11.MedicineI</IndexLocation>
<StreamLocation>^HL7v2Template.Tes9F11.MedicineS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
