Include %occErrors

Class HL7v2Template.Test.RDEO11.MessageTest Extends %UnitTest.TestCase
{

Method TestMessageOutput() As %Status
{
	write "Running TestMessageOutput...",!
	set ret=$$$OK
	try {
		/// 単位データの登録
		do ##class(HL7v2Template.Test.CodeSet.Units).%KillExtent()
		set tab=##class(HL7v2Template.Test.CodeSet.Units).%New()
		set tab.Code="TAB"
		set tab.Text="錠"
		set tab.System="MR9P"
		set ret=tab.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code TAB")
		quit:$$$ISERR(ret)
		set mg=##class(HL7v2Template.Test.CodeSet.Units).%New()
		set mg.Code="MG"
		set mg.Text="ミリグラム"
		set mg.System="MR9P"
		set ret=mg.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code MG")
		quit:$$$ISERR(ret)

		/// 繰返しパターンデータの登録
		do ##class(HL7v2Template.Test.CodeSet.RepeatPattern).%KillExtent()
		set rp=##class(HL7v2Template.Test.CodeSet.RepeatPattern).%New()
		set rp.Code="1013044400000000"
		set rp.Text="内服・経口・１日３回朝昼夕食後"
		set rp.System="JAMISDP01"
		set ret=rp.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code 1013044400000000")
		quit:$$$ISERR(ret)
		set rp2=##class(HL7v2Template.Test.CodeSet.RepeatPattern).%New()
		set rp2.Code="1012040400000000"
		set rp2.Text="内服・経口・１日２回朝夕食後"
		set rp2.System="JAMISDP01"
		set ret=rp2.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code 1012040400000000")
		quit:$$$ISERR(ret)

		 /// 薬剤データの登録
		do ##class(HL7v2Template.Test.CodeSet.Medicine).%KillExtent()
		set med1=##class(HL7v2Template.Test.CodeSet.Medicine).%New()
		set med1.Code="108665201"
		set med1.Text="ダーゼン錠（５mg)"
		set med1.System="HOT9"
		set ret=med1.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code 108665201")
		quit:$$$ISERR(ret)
		set med2=##class(HL7v2Template.Test.CodeSet.Medicine).%New()
		set med2.Code="110626901"
		set med2.Text="パンスポリンＴ錠（１００mg)"
		set med2.System="HOT9"
		set ret=med2.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code 110626901")
		quit:$$$ISERR(ret)
		set med3=##class(HL7v2Template.Test.CodeSet.Medicine).%New()
		set med3.Code="100607002"
		set med3.Text="アレピアチン１０倍散"
		set med3.System="HOT9"
		set ret=med3.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code 100607002")
		quit:$$$ISERR(ret)

		/// 経路コードの登録
		do ##class(HL7v2Template.Test.CodeSet.Route).%KillExtent()
		set route=##class(HL7v2Template.Test.CodeSet.Route).%New()
		set route.Code="PO"
		set route.Text="口"
		set route.System="HL70162"
		set ret=route.%Save()
		do $$$AssertStatusOK(ret,"Failed to save code PO")
		quit:$$$ISERR(ret)

		 /// メッセージデータの作成
		set msg=##class(HL7v2Template.Test.RDEO11.Message).%New()
		set msg.MsgTime="2011-07-01 22:46:03"
		set msg.MsgControlId="20110701000001"
		set msg.PatientId="9999013"
		set msg.LastName="患者"
		set msg.FirstName="太郎"
		set msg.LastNameKana="カンジャ"
		set msg.FirstNameKana="タロウ"
		set dob=$zdateh("19480405",8)
		set msg.DOB=dob
		set msg.Gender="M"
		set addr=##class(HL7v2Template.Test.RDEO11.Address).%New()
		set addr.PostalCode="422-8033"
		set addr.Text="静岡県静岡市登呂１－３－５"
		set msg.Address=addr
		set msg.PhoneHome="054-000-0000"
		set msg.PhoneWork="054-999-2455"
		set msg.PatientUpdateTime="2011-06-01 12:15:51"

		set docatt=##class(HL7v2Template.Test.RDEO11.Doctor).%New()
		set docatt.Id="110"
		set docatt.FamilyName="医師"
		set docatt.GivenName="一郎"
		set docatt.NameTypeCode="I"
		set msg.AttendingDoctor=docatt

		set docenter=##class(HL7v2Template.Test.RDEO11.Doctor).%New()
		set docenter.Id="058"
		set docenter.FamilyName="入力者"
		set docenter.GivenName="花子"
		set docenter.NameTypeCode="I"

		set docorder=##class(HL7v2Template.Test.RDEO11.Doctor).%New()
		set docorder.Id="110"
		set docorder.FamilyName="医師"
		set docorder.GivenName="一郎"
		set docorder.NameTypeCode="I"

		set msg.MedicationOrders=##class(%ListOfObjects).%New()

		set orderone=##class(HL7v2Template.Test.RDEO11.Order).%New()
		set orderone.OrderControl="NW"
		set orderone.PlacerOrderNumber="000000011000185"
		set orderone.PlacerGroupNumber="1"
		set orderone.TransactionTime="2011-07-01 10:30:45"
		set orderone.EnteredBy=docenter
		set orderone.OrderingProvider=docorder
		set occr=##class(HL7v2Template.Test.CodeSet).%New()
		set occr.Code="01"
		set occr.Text="内科"
		set occr.System="99XY1"
		set orderone.OrderControlCodeReason=occr
		set otype=##class(HL7v2Template.Test.CodeSet).%New()
		set otype.Code="O"
		set otype.Text="外来患者オーダ"
		set otype.System="HL70482"
		set orderone.OrderType=otype
		set orderone.DispenseGiveCode=med1
		set orderone.GiveAmountMinimum="1"
		set orderone.GiveUnits=tab
		set orderone.DispenseAmount="15"
		set orderone.DispenseUnits=tab
		set orderone.PrescriptionNumber="2011070112345"
		set tdd=##class(HL7v2Template.DT.CQ).%New()
		set tdd.Quantity="3"
		set tdd.Code="TAB"
		set tdd.Text="錠"
		set tdd.System="MR9P"
		set orderone.TotalDailyDose=tdd
		set ohp=##class(HL7v2Template.Test.CodeSet).%New()
		set ohp.Code="OHP"
		set ohp.Text="外来処方"
		set ohp.System="MR9P"
		set ohi=##class(HL7v2Template.Test.CodeSet).%New()
		set ohi.Code="OHI"
		set ohi.Text="院内処方"
		set ohi.System="MR9P"
		set orderone.SpecialDispensingInstructions=##class(%ListOfObjects).%New()
		do orderone.SpecialDispensingInstructions.Insert(ohp)
		do orderone.SpecialDispensingInstructions.Insert(ohi)
		set orderone.SetId="1"
		set orderone.RepeatPattern=rp
		set dur=##class(HL7v2Template.Test.RDEO11.Duration).%New()
		set dur.Quantity="5"
		set dur.Units="d"
		set orderone.Duration=dur
		set orderone.StartDateTime="2011-07-01 00:00:00"
		set orderone.Route=route
		do msg.MedicationOrders.Insert(orderone)

		set ordertwo=##class(HL7v2Template.Test.RDEO11.Order).%New()
		set ordertwo.OrderControl="NW"
		set ordertwo.PlacerOrderNumber="000000011000185"
		set ordertwo.PlacerGroupNumber="1"
		set ordertwo.TransactionTime="2011-07-01 10:30:45"
		set ordertwo.EnteredBy=docenter
		set ordertwo.OrderingProvider=docorder
		set ordertwo.OrderControlCodeReason=occr
		set ordertwo.OrderType=otype
		set ordertwo.DispenseGiveCode=med2
		set ordertwo.GiveAmountMinimum="2"
		set ordertwo.GiveUnits=tab
		set ordertwo.DispenseAmount="30"
		set ordertwo.DispenseUnits=tab
		set tdd=##class(HL7v2Template.DT.CQ).%New()
		set tdd.Quantity="6"
		set tdd.Code="TAB"
		set tdd.Text="錠"
		set tdd.System="MR9P"
		set ordertwo.TotalDailyDose=tdd
		set ordertwo.SpecialDispensingInstructions=##class(%ListOfObjects).%New()
		do ordertwo.SpecialDispensingInstructions.Insert(ohp)
		do ordertwo.SpecialDispensingInstructions.Insert(ohi)
		set ordertwo.SetId="1"
		set ordertwo.RepeatPattern=rp
		set ordertwo.Duration=dur
		set ordertwo.StartDateTime="2011-07-01 00:00:00"
		set ordertwo.Route=route
		do msg.MedicationOrders.Insert(ordertwo)

		set orderthree=##class(HL7v2Template.Test.RDEO11.Order).%New()
		set orderthree.OrderControl="NW"
		set orderthree.PlacerOrderNumber="000000011000185"
		set orderthree.PlacerGroupNumber="2"
		set orderthree.TransactionTime="2011-07-01 10:30:45"
		set orderthree.EnteredBy=docenter
		set orderthree.OrderingProvider=docorder
		set orderthree.OrderControlCodeReason=occr
		set orderthree.OrderType=otype
		set orderthree.DispenseGiveCode=med3
		set orderthree.GiveAmountMinimum="50"
		set orderthree.GiveUnits=mg
		set orderthree.DispenseAmount="1400"
		set orderthree.DispenseUnits=mg
		set orderthree.PrescriptionNumber="2011070112345"
		set tdd=##class(HL7v2Template.DT.CQ).%New()
		set tdd.Quantity="100"
		set tdd.Code="MG"
		set tdd.Text="ミリグラム"
		set tdd.System="MR9P"
		set orderthree.TotalDailyDose=tdd
		set orderthree.SpecialDispensingInstructions=##class(%ListOfObjects).%New()
		do orderthree.SpecialDispensingInstructions.Insert(ohp)
		do orderthree.SpecialDispensingInstructions.Insert(ohi)
		set orderthree.SetId="1"
		set orderthree.RepeatPattern=rp2
		set dur=##class(HL7v2Template.Test.RDEO11.Duration).%New()
		set dur.Quantity="14"
		set dur.Units="d"
		set orderthree.Duration=dur
		set orderthree.StartDateTime="2011-07-01 00:00:00"
		set orderthree.Route=route
		do msg.MedicationOrders.Insert(orderthree)

		set stream=##class(%Stream.TmpCharacter).%New()
		set ret=##class(HL7v2Template.Test.RDEO11.Message).OutputToStream(msg,stream)
		do $$$AssertStatusOK(ret,"OutputToStream failed")
		quit:$$$ISERR(ret)

		do stream.Rewind()
		set out=""
		write "-----output start-----",!
		while ('stream.AtEnd) {
			set line=stream.ReadLine()
			write line,!
			set out=out_line_$c(13)
		}
		write "-----output end-----",!

		set addrfield=##class(HL7v2Template.Test.RDEO11.Address).GenerateData(addr)
		set docattfield=##class(HL7v2Template.Test.RDEO11.Doctor).GenerateData(docatt)
		set docenterfield=##class(HL7v2Template.Test.RDEO11.Doctor).GenerateData(docenter)
		set docorderfield=##class(HL7v2Template.Test.RDEO11.Doctor).GenerateData(docorder)

		set expected=""
		set expected=expected_"MSH|^~\&|HIS123|SEND|GW|RCV|20110701224603||RDE^O11^RDE_O11|20110701000001|P|2.5||||||~ISO IR87||ISO2022-1994|SS-MIX2_1.20^SS-MIX2^1.2.392.200250.2.1.100.1.2.120^ISO"_$c(13)
		set expected=expected_"PID|0001||9999013^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19480405|M|||"_addrfield_"||^PRN^PH^^^^^^^^^054-000-0000|^WPN^PH^^^^^^^^^054-999-2455|||||||||||||||||||20110601121551"_$c(13)
		set expected=expected_"PV1|0001|O|01^^^^^C||||"_docattfield_"|||01"_$c(13)
		set expected=expected_"ORC|NW|000000011000185||1|||||20110701103045|"_docenterfield_"||"_docorderfield_"|10^^^^^C||||01^内科^99XY1|VMDOCX01^^99XY2||||||||||O^外来患者オーダ^HL70482"_$c(13)
		set expected=expected_"RXE||108665201^ダーゼン錠（５mg)^HOT9|1||TAB^錠^MR9P|||||15|TAB^錠^MR9P||||2011070112345||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P"_$c(13)
		set expected=expected_"TQ1|1||1013044400000000^内服・経口・１日３回朝昼夕食後^JAMISDP01|||5^d|20110701000000"_$c(13)
		set expected=expected_"RXR|PO^口^HL70162"_$c(13)
		set expected=expected_"ORC|NW|000000011000185||1|||||20110701103045|"_docenterfield_"||"_docorderfield_"|10^^^^^C||||01^内科^99XY1|VMDOCX01^^99XY2||||||||||O^外来患者オーダ^HL70482"_$c(13)
		set expected=expected_"RXE||110626901^パンスポリンＴ錠（１００mg)^HOT9|2||TAB^錠^MR9P|||||30|TAB^錠^MR9P||||||||6^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P"_$c(13)
		set expected=expected_"TQ1|1||1013044400000000^内服・経口・１日３回朝昼夕食後^JAMISDP01|||5^d|20110701000000"_$c(13)
		set expected=expected_"RXR|PO^口^HL70162"_$c(13)
		set expected=expected_"ORC|NW|000000011000185||2|||||20110701103045|"_docenterfield_"||"_docorderfield_"|10^^^^^C||||01^内科^99XY1|VMDOCX01^^99XY2||||||||||O^外来患者オーダ^HL70482"_$c(13)
		set expected=expected_"RXE||100607002^アレピアチン１０倍散^HOT9|50||MG^ミリグラム^MR9P|||||1400|MG^ミリグラム^MR9P||||2011070112345||||100^MG&ミリグラム&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P"_$c(13)
		set expected=expected_"TQ1|1||1012040400000000^内服・経口・１日２回朝夕食後^JAMISDP01|||14^d|20110701000000"_$c(13)
		set expected=expected_"RXR|PO^口^HL70162"_$c(13)

		do $$$AssertTrue( out=expected, "Message output mismatch" )
		if (out'=expected) {
			for l=1:1:$l(out,$c(13)) {
				s ol=$p(out,$c(13),l),el=$p(expected,$c(13),l)
				if (ol'=el) {
					write !,"line("_l_"):",!,ol,!,el,!
				}
			}
			set ret=$$$ERROR(5001,"Message output mismatch")
		}
	} catch err {
		set ret=err.AsStatus()
		do $$$AssertStatusOK(ret,"Unexpected error occurred "_$SYSTEM.Status.GetErrorText(ret))
	}
	quit ret
}

}
