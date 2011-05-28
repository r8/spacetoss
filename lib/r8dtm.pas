{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8DTM;

Interface
Uses
  r8Str,
  Dos;

const

  dtmDayOfWeek : array[0..6] of string[3] = ('Sun','Mon', 'Tue',
                      'Wen','Thu','Fri','Sat');

  dtmMonth : array[1..12] of string[3] = ('Jan', 'Feb', 'Mar','Apr',
                      'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

type

  TDateTime = record
{$IFDEF VIRTUALPASCAL}
    Day : longint;
    Month : longint;
    Year : longint;
    DayOfWeek : longint;
    Hour : longint;
    Minute : longint;
    Sec : longint;
    Sec100 : longint;
{$ELSE}
    Day : word;
    Month : word;
    Year : word;
    DayOfWeek : word;
    Hour : word;
    Minute : word;
    Sec : word;
    Sec100 : word;
{$ENDIF}
  end;

  PDatetime = ^TDateTime;

Procedure dtmGetDateTime(var DateTime:TDateTime);
Procedure dtmGetTime(var DateTime:TDateTime);
Procedure dtmGetDate(var DateTime:TDateTime);
Function dtmGetDateTimeUnix:longint;

Function dtmGetWDay:integer;

Function dtmDate2String(DateTime:TDateTime;Sep:char;
               MonthByWord:boolean;Year2:boolean):string;
Function dtmTime2String(DateTime:TDateTime;Sep:char;Sec:boolean;Sec100:Boolean):string;

Function dtmDateToUnix(DateTime:TDateTime):LongInt;
Procedure dtmUnixToDate(UnixDate:LongInt; Var DateTime:TDateTime);

Function dtmStrToMonth(S:string):integer;

Function dtmGetDateTimeStr:string;


Function dtmSecPastMidnight:real;

Function dtmStartTimer:real;
Function dtmStopTimer(S:real):real;

Procedure dtmDosToDTM(DosTime:DateTime; var DTMTime:TDateTime);
Function dtmDOSToUnix(DT:DateTime):longint;

Function dtmFileTimeUnix(const S:string):longint;

Procedure dtmDateToFTN(DateTime:TDatetime;var FTNDateTime : array of char);
Function dtmFTNPackedDate:string;

Implementation

Procedure dtmGetDateTime(var DateTime:TDateTime);
Begin
  With DateTime do
    Begin
       GetTime(Hour, Minute, Sec, Sec100);
       GetDate(Year,Month,Day,DayOfWeek);
    End;
end;

Procedure dtmGetTime(var DateTime:TDateTime);
Begin
  With DateTime do
    Begin
       GetTime(Hour, Minute, Sec, Sec100);
    End;
end;

Procedure dtmGetDate(var DateTime:TDateTime);
Begin
  With DateTime do
    Begin
       GetDate(Year,Month,Day,DayOfWeek);
    End;
end;

Function dtmDate2String(DateTime:TDateTime;Sep:char;
               MonthByWord:boolean;Year2:boolean):string;
Var
  sTemp:string;
Begin
  sTemp:=strPadL(strIntToStr(DateTime.Day),'0',2)+Sep;
  If MonthByWord Then
    Begin
      sTemp:=sTemp+dtmMonth[DateTime.Month]+Sep;
    End
    else
    Begin
      sTemp:=sTemp+strPadL(strIntToStr(DateTime.Month),'0',2)+Sep;
    End;
  If Year2 Then
    Begin
      sTemp:=sTemp+Copy(strIntToStr(DateTime.Year),
      Length(strIntToStr(DateTime.Year))-1,2);
    End
    else
    Begin
      sTemp:=sTemp+strIntToStr(DateTime.Year);
    End;
  dtmDate2String:=sTemp;
End;

Function dtmTime2String(Datetime:TDateTime;Sep:char;Sec:boolean;Sec100:Boolean):string;
Var
  sTemp:string;
Begin
  sTemp:=strPadL(strIntToStr(DateTime.Hour),'0',2)+Sep;
  sTemp:=sTemp+strPadL(strIntToStr(DateTime.Minute),'0',2);
  If Sec Then sTemp:=sTemp+Sep+strPadL(strIntToStr(DateTime.Sec),'0',2);
  If Sec100 Then sTemp:=sTemp+Sep+strPadL(strIntToStr(DateTime.Sec100),'0',3);
  dtmTime2String:=sTemp;
End;

Function dtmDateToUnix(DateTime:TDateTime):LongInt;
const
  DaysPerMonth :
    Array[1..12] of ShortInt = (031,028,031,030,031,030,031,031,030,031,030,031);
Var
  lTemp : LongInt;
  i : integer;
Begin
  lTemp:=0;
  lTemp:=lTemp+DateTime.Sec;
  lTemp:=lTemp+60*DateTime.Minute;
  lTemp:=lTemp+3600*DateTime.Hour;

  If DateTime.Day>1 Then lTemp:=lTemp+86400*(DateTime.Day-1);

  If DateTime.Year mod 4 = 0 Then
    DaysPerMonth[02]:=29 else DaysPerMonth[02]:=28;

  If  DateTime.Month>1 then
    for i:=1 to (DateTime.Month-1) do
     lTemp:=lTemp+(DaysPerMonth[i]*86400);

  While DateTime.Year>1970 do
  Begin
    If (DateTime.Year-1) mod 4 = 0  Then
      lTemp:=lTemp+31622400 else lTemp:=lTemp+31536000;
    Dec(DateTime.Year);
  End;

  dtmDateToUnix:=lTemp;
End;

procedure JulianToGregorian(JulianDN: LongInt; var Year, Month, Day: Integer);
const
 D0            = 1461;
 D1            = 146097;
 D2            = 1721119;
 var
  Temp, XYear: LongInt;
  YYear, YMonth, YDay: Integer;
 begin
  Temp:=(((JulianDN - D2) shl 2) - 1);
  XYear:=(Temp mod D1) or 3;
  JulianDN:=Temp div D1;
  YYear:=(XYear div D0);
  Temp:=((((XYear mod D0) + 4) shr 2) * 5) - 3;
  YMonth:=Temp div 153;
  if YMonth >= 10 then
   begin
    YYear:=YYear + 1;
    YMonth:=YMonth - 12;
   end;
  YMonth:=YMonth + 3;
  YDay:=Temp mod 153;
  YDay:=(YDay + 5) div 5;
  Year:=YYear + (JulianDN * 100);
  Month:=YMonth;
  Day:=YDay;
 end;

Procedure dtmUnixToDate(UnixDate:LongInt; Var DateTime:TDateTime);
Var
  DateNum: LongInt;
  Year, Month, Day: Integer;
begin
  Datenum:=(UnixDate div 86400) + 2440588;

  JulianToGregorian(DateNum, Year, Month, Day);

  DateTime.Year:=Year;
  DateTime.Month:=Month;
  DateTime.Day:=Day;

  UnixDate:=UnixDate mod 86400;
  DateTime.Hour:=UnixDate div 3600;
  UnixDate:=UnixDate mod 3600;
  DateTime.Minute:=UnixDate div 60;
  DateTime.Sec:=UnixDate mod 60;
end;

Function dtmGetWDay:integer;
Var
  DateTime :  TDateTime;
begin
  dtmGetDate(DateTime);
  dtmGetWDay:=DateTime.DayOfWeek;
end;

Function dtmStrToMonth(S:string):integer;
Var
  i:integer;
begin
  For i:=1 to 12 do
    begin
      If strUpper(S)=strUpper(dtmMonth[i]) then
        begin
          dtmStrToMonth:=i;
          exit;
        end;
    end;
end;

Function dtmGetDateTimeStr:string;
Var
  DateTime : TDateTime;
  sTemp:string;
Begin
  dtmGetDateTime(DateTime);

  sTemp:=dtmDate2String(DateTime,#32,True,True);
  sTemp:=sTemp+#32+dtmTime2String(DateTime,':',True,False);

  dtmGetDateTimeStr:=sTemp;
End;

Function dtmGetDateTimeUnix:longint;
Var
  DateTime : TDateTime;
begin
  dtmGetDateTime(DateTime);
  dtmGetDateTimeUnix:=dtmDateToUnix(DateTime);
end;

Function dtmDOSToUnix(DT:DateTime):longint;
Var
  MyDateTime : TDateTime;
begin
  dtmDOSToDTM(DT,MyDateTime);
  dtmDOSToUnix:=dtmDateToUnix(MyDateTime);
end;

Function dtmSecPastMidnight:real;
Var
{$IFDEF VIRTUALPASCAL}
  hour : longint;
  minute : longint;
  sec : longint;
  sec100 : longint;
{$ELSE}
  hour : word;
  minute : word;
  sec : word;
  sec100 : word;
{$ENDIF}
begin
  GetTime(hour, minute, sec, sec100);
  dtmSecPastMidnight:=hour*3600+minute*60+sec+sec100*0.01;
end;

Function dtmStartTimer:real;
begin
  dtmStartTimer:=dtmSecPastMidnight;
end;

Function dtmStopTimer(S:real):real;
Var
  S2:real;
begin
  S2:=dtmSecPastMidnight;

  If S2<S then
    begin
      S2:=24*3600+S2;
    end;

  dtmStopTimer:=S2-S;
end;

Procedure dtmDosToDTM(DosTime:DateTime; var DTMTime:TDateTime);
begin
  With DosTime do
    begin
      DTMTime.Day:=Day;
      DTMTime.Month:=Month;
      DTMTime.Year:=year;
      DTMTime.Hour:=Hour;
      DTMTime.Minute:=Min;
      DTMTime.Sec:=Sec;
    end;
end;

Function dtmFileTimeUnix(const S:string):longint;
Var
  F:file;
  DT : DateTime;
  Time: Longint;
begin
  dtmFileTimeUnix:=-1;

{$I-}
  Assign(F, S);
  Reset(F);
{$I+}
  If IOResult=0 then
    begin
      GetFTime(F,Time);
      UnpackTime(Time,DT );
      Close(F);
      dtmFileTimeUnix:=dtmDOSToUnix(DT);
    end;
end;

Procedure dtmDateToFTN(DateTime:TDatetime;var FTNDateTime : array of char);
Var
  sTemp : string[20];
begin
  FillChar(FTNDateTime,20,#0);
  sTemp:=dtmDate2String(DateTime,#32,True,True)+#32#32+
         dtmTime2String(DateTime,':',True,False);
  Move(sTemp[1],FTNDateTime,19);
end;

Function dtmFTNPackedDate:string;
Var
  DateTime : TDateTime;
  sTemp : string;
begin
  dtmGetDateTime(DateTime);

  sTemp:=strPadL(strIntToStr(DateTime.Year),'0',4);

  sTemp:=sTemp+strPadL(strIntToStr(DateTime.Month),'0',2);
  sTemp:=sTemp+strPadL(strIntToStr(DateTime.Day),'0',2);

  sTemp:=sTemp+'.'+strPadL(strIntToStr(DateTime.Hour),'0',2);
  sTemp:=sTemp+strPadL(strIntToStr(DateTime.Minute),'0',2);
  sTemp:=sTemp+strPadL(strIntToStr(DateTime.Sec),'0',2);

  dtmFTNPackedDate:=sTemp;
end;

End.
