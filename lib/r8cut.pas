{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8cut;

interface
uses
  r8str,
  strings,
  objects;

Type
  TCutter = object(TObject)
    LinesPerSection : longint;
    BytesPerSection : longint;

    TotalLines : longint;
    TotalBytes : longint;
    TotalSections : longint;
    CurrentSection : longint;

    Constructor Init;
    Destructor Done;virtual;

    Procedure DoCut;
    Procedure OpenCutSection;
    Procedure CloseCutSection;

    Procedure CreateSection;virtual;
    Procedure CloseSection;virtual;
    Procedure AddLine(S:PChar);virtual;
    Procedure GetLine(var S:PChar);virtual;
  private
    Line : longint;
    Bytes : longint;
    Countdown : LongInt;
end;

implementation

Constructor TCutter.Init;
begin
  inherited init;

  LinesPerSection:=0;
  BytesPerSection:=0;

  TotalLines:=0;
  TotalBytes:=0;
  TotalSections:=0;

  CurrentSection:=0;
end;

Destructor TCutter.Done;
begin
  inherited Done;
end;

Procedure TCutter.DoCut;
var
 i:integer;
 PTemp : PChar;
 TempTotal : integer;
begin
  If LinesPerSection=0 then LinesPerSection:=TotalLines;
  If BytesPerSection=0 then BytesPerSection:=TotalBytes;

  TotalSections:=TotalBytes div BytesPerSection;
  If TotalSections<>TotalBytes/BytesPerSection
      then Inc(TotalSections);

  TempTotal:=TotalLines div LinesPerSection;
  If TempTotal<>TotalLines/LinesPerSection
      then Inc(TempTotal);

  If TempTotal>TotalSections then TotalSections:=TempTotal;

  OpenCutSection;

  Countdown:=TotalLines;

  repeat
    if Countdown <= 0 then Break;

    GetLine(PTemp);
    AddLine(PTemp);
    Inc(Bytes,StrLen(PTemp)+1);
    StrDispose(PTemp);

    Inc(Line);

    Dec(CountDown);

    if (Line = LinesPerSection) and (TotalSections>1) then
    begin
      CloseCutSection;
      OpenCutSection;
    end;

    if (Bytes>=BytesPerSection) and (TotalSections>1) then
    begin
      CloseCutSection;
      OpenCutSection;
    end;

  until False;

  CloseCutSection;
end;

Procedure TCutter.CreateSection;
begin
  Abstract;
end;

Procedure TCutter.CloseSection;
begin
  Abstract;
end;

Procedure TCutter.Addline(S:PChar);
begin
  Abstract;
end;

Procedure TCutter.GetLine(var S:PChar);
begin
  Abstract;
end;

Procedure TCutter.OpenCutSection;
Var
  sTemp : string;
begin
  Line:=0;
  Bytes:=0;

  Inc(CurrentSection);

  CreateSection;

  If CurrentSection = 1 then
  begin
  end;
end;

Procedure TCutter.CloseCutSection;
var
  sTemp: String;
begin
  if CurrentSection = TotalSections then
  begin
  end;

   CloseSection;
end;

end.
