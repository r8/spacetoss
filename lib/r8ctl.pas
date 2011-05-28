{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8Ctl;

interface

Uses
  objects,
  r8const,
  r8objs,
  r8ftn,
  r8mcr,
  r8Dos, r8Str;

const
  ctlErrNone              = $00000000;
  ctlErrFileNotFound      = $00000001;
  ctlErrInvalidParameter  = $00000002;
  ctlErrCantFindParameter = $00000003;
  ctlErrCantFindSection   = $00000004;
  ctlErrUndIncludeLoop    = $00000005;
  ctlErrIncludeLoop       = $00000006;

Type

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

CTLSR = record
  CurSec : longint;
  CurKey : longint;
  Key    : string;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

TParsedItem = object(TObject)
  Keyword : PString;
  Value : PString;

  Constructor Init(_Keyword, _Value:string);
  Destructor Done;virtual;
end;

PParsedItem = ^TParsedItem;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

TIncludeStack = object(TObject)
  Includes : PStringsCollection;

  Constructor Init;
  Destructor Done;virtual;

  Procedure AddInclude(const S:string);
  Function CheckInclude(S:string):boolean;
end;

PIncludeStack = ^TIncludeStack;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

TParsed = object(TCollection)
  Procedure FreeItem(Item:pointer);virtual;
end;

PParsed = ^TParsed;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

TCTLFile = object(TObject)
  Parsed : PParsed;

  CTLFileName : PString;

  CTLError : longint;
  CTLSError : string;
  CurrentLine : longint;

  KeyWords : PStringsCollection;
  Macros : PMacroEngine;
  IncludeStack : PIncludeStack;

  kwrdCantFindFile : PString;
  kwrdUnknownKeyword : PString;
  kwrdLoopInclude : PString;

  Constructor Init;
  Destructor Done;virtual;

  Procedure SetCTLName(const _CTLName:string);
  Procedure AddKeyword(S:string);

  Function  CheckKeyword(S:string):boolean;

  Procedure LoadCTL;

  Function FindFirstValue(S:string;var SR:CTLSR):string;
  Function FindNextValue(var SR:CTLSR):string;virtual;

  Procedure FindFirstAddressValue(S:string;var Address:TAddress;var SR:CTLSR);
  Procedure FindNextAddressValue(var Address:TAddress;var SR:CTLSR);virtual;

  Function ExplainStatus(Status:longint):string;

  Procedure CheckPlatform(Var S:string);
  Procedure ParsFile(var T:text);virtual;
  Function ParsLine(S:string):PParsedItem;

  Procedure SetErrorMessages(const _kwrdCantFindFile, _kwrdUnknownKeyword,
           _kwrdLoopInclude:string);
end;

PCTLFile = ^TCTLFile;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

TSectionBase = object (TCollection)
  Procedure FreeItem(Item:pointer);virtual;
end;

PSectionBase = ^TSectionBase;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

TSectionCTL = object(TCTLFile)
  BeginSig, EndSig : string;

  SectionBase : PSectionBase;

  Constructor Init(const BeginS, EndS:string);
  Destructor Done;virtual;

  Function FindFirstValue(Section:integer;S:string;var SR:CTLSR):string;
  Function FindNextValue(var SR:CTLSR):string;virtual;

  Procedure FindFirstAddressValue(Section:integer;S:string;var Address:TAddress;var SR:CTLSR);

  Function GetSectionCount:longint;

  Procedure ParsFile(var T:text);virtual;
end;

PSectionCTL = ^TSectionCTL;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

TIniCTL = object(TSectionCTL)
  SectionNames : PStringsCollection;

  Constructor Init;
  Destructor Done;virtual;

  Function FindFirstValue(Section, S:string;var SR:CTLSR):string;

  Procedure ParsFile(var T:text);virtual;

  Function FindSection(S:string):longint;
  Procedure ModifyValue(Section:string;Keyword:string;Value:string);
end;

PIniCTL = ^TIniCTL;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

implementation

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TParsedItem.Init(_Keyword, _Value:string);
begin
  inherited init;

  Keyword:=NewStr(_Keyword);
  Value:=NewStr(_Value);
end;

Destructor TParsedItem.Done;
begin
  If Keyword<>nil then DisposeStr(Keyword);
  If Value<>nil then DisposeStr(Value);

  inherited Done;
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Procedure TParsed.FreeItem(Item:pointer);
begin
  if Item<> nil then Dispose(PParsedItem(Item),Done);
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TIncludeStack.Init;
begin
  inherited Init;

  Includes:=New(PStringsCollection,Init($10,$10));
end;

Destructor TIncludeStack.Done;
begin
  Dispose(Includes,Done);

  inherited Done;
end;

Procedure TIncludeStack.AddInclude(const S:string);
begin
 Includes^.Insert(NewStr(strUpper(S)));
end;

Function TIncludeStack.CheckInclude(S:string):boolean;
Var
  i:integer;
  pTemp:PString;

  Function Match(P:pointer):boolean; far;
    begin
      Match:=False;
      If PString(P)^=S then Match:=true;
    end;

begin
  CheckInclude:=False;
  If Includes^.Count=0 then Exit;

  S:=strUpper(S);

  If Includes^.FirstThat(@Match)<>nil then CheckInclude:=True;
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TCTLFile.Init;
begin
  inherited Init;

  KeyWords:=New(PStringsCollection,Init($10,$10));
  Parsed:=New(PParsed,Init($10,$10));
  Macros:=New(PMacroEngine,Init);
  IncludeStack:=New(PIncludeStack,Init);

  CTLError:=0;
  CTLSError:='';
  CurrentLine:=0;

  CTLFileName:=nil;

  kwrdCantFindFile:=NewStr('Cannot find config file');
  kwrdUnknownKeyword:=NewStr('Unknown keyword');
  kwrdLoopInclude:=NewStr('Loop include');
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TCTLFile.Done;
begin
  objDispose(KeyWords);
  objDispose(Parsed);
  objDispose(Macros);
  objDispose(IncludeStack);

  DisposeStr(CTLFileName);

  DisposeStr(kwrdCantFindFile);
  DisposeStr(kwrdUnknownKeyword);
  DisposeStr(kwrdLoopInclude);

  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.SetErrorMessages(const _kwrdCantFindFile, _kwrdUnknownKeyword,
               _kwrdLoopInclude:string);
begin
  If kwrdCantFindFile<>nil then DisposeStr(kwrdCantFindFile);
  kwrdCantFindFile:=NewStr(_kwrdCantFindFile);

  If kwrdUnknownKeyword<>nil then DisposeStr(kwrdUnknownKeyword);
  kwrdUnknownKeyword:=NewStr(_kwrdUnknownKeyword);

  If kwrdLoopInclude<>nil then DisposeStr(kwrdLoopInclude);
  kwrdLoopInclude:=NewStr(_kwrdLoopInclude);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.SetCTLName(const _CTLName:string);
begin
  If CTLFileName<>nil then DisposeStr(CTLFileName);

  CTLFileName:=NewStr(_CTLName);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.AddKeyword(S:string);
begin
  KeyWords^.Insert(NewStr(strUpper(S)));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function  TCTLFile.CheckKeyword(S:string):boolean;
Var
  I : integer;

  Function Match(P:pointer):boolean; far;
    begin
      Match:=False;
      If PString(P)^=S then Match:=true;
    end;

begin
  CheckKeyWord:=False;
  If Keywords^.Count=0 then Exit;

  S:=strUpper(S);


  If Keywords^.FirstThat(@Match)<>nil then CheckKeyWord:=True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.CheckPlatform(Var S:string);
Var
  sTemp : string;
begin
  S:=strTrimL(S,[#32,#9]);

  sTemp:=strUpper(strParser(S,1,[')']));

  If (sTemp<>'(DOS')
  and (sTemp<>'(WIN')
  and (sTemp<>'(OS2') then exit;

  S:=strTrimL(Copy(S,6,Length(S)-5),[#32,#9]);

  If (cstrOsId='WIN32') and (sTemp<>'(WIN') then S:='';
  If (cstrOsId='OS2') and (sTemp<>'(OS2') then S:='';

  If ((cstrOsId='DOS') or (cstrOsId='386') or (cstrOsId='DMPI'))
     and (sTemp<>'(DOS') then S:='';

end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TCTLFile.ParsLine(S:string):PParsedItem;
Var
  P : longint;

  sTemp : string;
  lTemp : longint;
  TempKeyword, TempValue : string;
begin
  ParsLine:=nil;
  CTLError:=ctlerrNone;

  P:=Pos(';',S);
  If P<>0 then S:=strTrimB(Copy(S,1,P-1),[#32,#9]);

  Macros^.ProcessString(S);

  CheckPlatform(S);

  If S='' then exit;

  If strUpper(strParser(S,1,[#32,#9]))='$INCLUDE' then
    begin
      sTemp:=CTLFileName^;
      lTemp:=CurrentLine;

      SetCTLName(dosMakeValidString(strParser(S,2,[#32,#9])));

      LoadCTL;

      If (CTLError=ctlerrNone) or (CTLError=ctlErrUndIncludeLoop) then
        begin
          SetCTLName(sTemp);
          CurrentLine:=lTemp;

          If CTLError=ctlErrUndIncludeLoop
              then CTLError:=ctlErrIncludeLoop;
        end;
      exit;
    end;

  If strUpper(strParser(S,1,[#32,#9]))='$DEFINE' then
    begin
      S:=strTrimL(Copy(S,8,Length(S)-7),[#32,#9]);
      S:=strParser(S,1,[#32,#9]);

      Macros^.AddMacro(S,Copy(S,Length(S)+1,
            Length(S)-Length(S)),False);

      exit;
    end;

  If CheckKeyword(strUpper(strParser(S,1,[#32,#9])))=False then
    begin
      CTLError:=ctlErrInvalidParameter;
      CTLSError:=strParser(S,1,[#32,#9]);
      Exit;
    end;

  TempKeyword:=strUpper(strParser(S,1,[#32,#9]));
  TempValue:=strTrimB(Copy(S,
       Length(TempKeyword)+1,
       Length(S)-Length(TempKeyword)),[#32,#9]);

  ParsLine:=New(PParsedItem,Init(TempKeyword,TempValue));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.ParsFile(var T:text);
Var
  sTemp : string;
  S:string;
  TempParsed : PParsedItem;
begin
  While not Eof(t) do
    begin
      ReadLn(T,sTemp);
      Inc(CurrentLine);

      sTemp:=strTrimB(sTemp,[#32,#9]);
      If sTemp='' then continue;

      TempParsed:=ParsLine(sTemp);

      If TempParsed=nil then
         If CTLError<>ctlErrNone then break else continue;

      Parsed^.Insert(TempParsed);
    end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.LoadCTL;
Var
  t : text;
begin
  CTLError:=0;
  CTLSError:='';
  CurrentLine:=0;

  If (CTLFileName=nil) or (not dosFileExists(CTLFileName^)) then
    begin
      CTLError:=ctlErrFileNotFound;
      Exit;
    end;

  If IncludeStack^.CheckInclude(CTLFileName^) then
    begin
      CTLError:=ctlErrUndIncludeLoop;
      Exit;
    end;

  IncludeStack^.AddInclude(CTLFileName^);

  Assign(T,CTLFileName^);
  ReSet(T);

  ParsFile(T);

  Close(T);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TCTLFile.FindFirstValue(S:string;var SR:CTLSR):string;
Var
 i : integer;
 sTemp : string;
 TempParsed : PParsedItem;
begin
  CTLError:=0;
  CTLSError:='';

  S:=strUpper(S);
  sTemp:='';

  SR.CurKey:=i;
  SR.Key:=S;

  for i:=0 to Parsed^.Count-1 do
    begin
      TempParsed:=Parsed^.At(i);
      If TempParsed^.Keyword^=S then
        begin
          sTemp:=strTrimB(TempParsed^.Value^,[#32,#9]);
          Break;
        end;
    end;

  SR.CurKey:=i;
  SR.Key:=S;

  If sTemp='' then
    begin
      CTLError:=ctlErrCantFindParameter;
      CTLSError:=S;
    end;

  FindFirstValue:=sTemp;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TCTLFile.FindNextValue(var SR:CTLSR):string;
Var
 i : integer;
 sTemp : string;
 TempParsed : PParsedItem;
begin
  CTLError:=0;
  CTLSError:='';
  sTemp:='';

  for i:=SR.CurKey+1 to Parsed^.Count-1 do
    begin
      TempParsed:=Parsed^.At(i);
      If TempParsed^.Keyword^=SR.Key then
        begin
          sTemp:=strTrimB(TempParsed^.Value^,[#32,#9]);
          Break;
        end;
    end;

  SR.CurKey:=i;

  If sTemp='' then
    begin
      CTLError:=ctlErrCantFindParameter;
      CTLSError:=SR.Key;
    end;

  FindNextValue:=sTemp;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.FindFirstAddressValue(S:string;var Address:TAddress;
            var SR:CTLSR);
Var
  sTemp:string;
begin
  sTemp:=FindFirstValue(S,SR);
  If CTLError<>0 then exit;
  If not ftnStrToAddress(sTemp,Address)
      then CTLError:=ctlErrInvalidParameter;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TCTLFile.FindNextAddressValue(var Address:TAddress;var SR:CTLSR);
Var
  sTemp:string;
begin
  sTemp:=FindNextValue(SR);
  If CTLError<>0 then exit;
  If not ftnStrToAddress(sTemp,Address)
      then CTLError:=ctlErrInvalidParameter;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TCTLFile.ExplainStatus(Status:longint):string;
begin
  Case Status of

    ctlErrFileNotFound : ExplainStatus:=kwrdCantFindFile^+#32
              +dosGetFileName(CTLFileName^);

    ctlErrInvalidParameter : ExplainStatus:=dosGetFileName(CTLFileName^)
                +'('+strIntToStr(CurrentLine)
                +'): '+kwrdUnknownKeyword^+' "'+CTLSError+'"';

    ctlErrIncludeLoop : ExplainStatus:=dosGetFileName(CTLFileName^)
                +'('+strIntToStr(CurrentLine)
                +'): '+kwrdLoopInclude^;
  end;
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Procedure TSectionBase.FreeItem(Item:pointer);
begin
  PParsed(Item)^.FreeAll;
  Dispose(PParsed(Item),Done);
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TSectionCTL.Init(const BeginS, EndS:string);
begin
  inherited Init;

  SectionBase:=New(PSectionBase,Init($10,$10));

  BeginSig:=strUpper(BeginS);
  EndSig:=strUpper(EndS);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TSectionCTL.Done;
begin
  Dispose(SectionBase,Done);

  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TSectionCTL.ParsFile(var T:text);
Var
  sTemp : string;
  S:string;
  TempParsed : PParsedItem;
  TempSection : PParsed;

  Opened : boolean;
begin
  Opened:=False;

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      Inc(CurrentLine);

      sTemp:=strTrimB(sTemp,[#32,#9]);
      If sTemp='' then continue;

      If strUpper(sTemp)=BeginSig then
        begin
          If Opened then continue;

          New(TempSection,Init($10,$10));
          Opened:=True;
          continue;
        end;

      If strUpper(sTemp)=EndSig then
        begin
          If not Opened then continue;

          Opened:=False;

          SectionBase^.Insert(TempSection);

          continue;
        end;

      TempParsed:=ParsLine(sTemp);

      If TempParsed=nil then
         If CTLError<>ctlErrNone then break else continue;

      If Opened then
         TempSection^.Insert(TempParsed)
         else objDispose(TempParsed);
    end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TSectionCTL.FindFirstValue(Section:integer;S:string;var SR:CTLSR):string;
Var
 i : integer;
 sTemp : string;
 TempParsed : PParsedItem;
 TempSection : PParsed;
begin
  CTLError:=0;
  CTLSError:='';

  S:=strUpper(S);
  sTemp:='';

  If (Section > SectionBase^.Count-1) or (Section<0) then
    begin
      CTLError:=ctlErrCantFindSection;
      FindFirstValue:=sTemp;
      Exit
    end;

  TempSection:=SectionBase^.At(Section);

  SR.CurKey:=i;
  SR.Key:=S;
  SR.CurSec:=Section;

  for i:=0 to TempSection^.Count-1 do
    begin
      TempParsed:=TempSection^.At(i);
      If TempParsed^.Keyword^=S then
        begin
          If TempParsed^.Value<>nil
            then sTemp:=strTrimB(TempParsed^.Value^,[#32,#9]);
          Break;
        end;
    end;

  SR.CurKey:=i;
  SR.Key:=S;

  If sTemp='' then
    begin
      CTLError:=ctlErrCantFindParameter;
      CTLSError:=S;
    end;
  FindFirstValue:=sTemp;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TSectionCTL.FindNextValue(var SR:CTLSR):string;
Var
 i : integer;
 sTemp : string;
 TempParsed : PParsedItem;
 TempSection : PParsed;
begin
  CTLError:=0;
  CTLSError:='';
  sTemp:='';

  TempSection:=SectionBase^.At(SR.CurSec);

  for i:=SR.CurKey+1 to TempSection^.Count-1 do
    begin
      TempParsed:=TempSection^.At(i);
      If TempParsed^.Keyword^=SR.Key then
        begin
          If TempParsed^.Value<>nil
             then sTemp:=strTrimB(TempParsed^.Value^,[#32,#9]);
          Break;
        end;
    end;

  SR.CurKey:=i;

  If sTemp='' then
    begin
      CTLError:=ctlErrCantFindParameter;
      CTLSError:=SR.Key;
    end;
  FindNextValue:=sTemp;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TSectionCTL.GetSectionCount:longint;
begin
  GetSectionCount:=SectionBase^.Count;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TSectionCTL.FindFirstAddressValue(Section:integer;S:string;var Address:TAddress;
            var SR:CTLSR);
Var
  sTemp:string;
begin
  sTemp:=FindFirstValue(Section,S,SR);
  If CTLError<>0 then exit;
  If not ftnStrToAddress(sTemp,Address)
      then CTLError:=ctlErrInvalidParameter;
end;

{袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴袴}

Constructor TIniCTL.Init;
begin
  inherited Init('','');

  SectionNames:=New(PStringsCollection,Init($10,$10));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Destructor TIniCTL.Done;
begin
  Dispose(SectionNames,Done);

  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TIniCTL.ParsFile(var T:text);
Var
  sTemp : string;
  S:string;
  TempParsed : PParsedItem;
  TempSection : PParsed;

  Opened : boolean;
begin
  Opened:=False;

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      Inc(CurrentLine);

      sTemp:=strTrimB(sTemp,[#32,#9]);
      If sTemp='' then continue;

      If (Pos('[',sTemp)<>0) and (Pos(']',sTemp)<>0) then
        begin
          If Opened then SectionBase^.Insert(TempSection);

          New(TempSection,Init($10,$10));
          SectionNames^.Insert(NewStr(strUpper(strTrimB(sTemp,['[',']']))));
          Opened:=True;
          continue;
        end;

      TempParsed:=ParsLine(sTemp);

      If TempParsed=nil then
         If CTLError<>ctlErrNone then break else continue;

      If Opened then
         TempSection^.Insert(TempParsed)
         else objDispose(TempParsed);
    end;

  If Opened then SectionBase^.Insert(TempSection);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TIniCTL.FindFirstValue(Section,S:string;var SR:CTLSR):string;
Var
 i : integer;
 sTemp : string;
 TempParsed : PParsedItem;
 TempSection : PParsed;
begin
  CTLError:=0;
  CTLSError:='';

  S:=strUpper(S);
  sTemp:='';

  SR.CurSec:=FindSection(strUpper(Section));

  If (SR.CurSec > SectionBase^.Count-1) or (SR.CurSec<0) then
    begin
      CTLError:=ctlErrCantFindSection;
      FindFirstValue:=sTemp;
      Exit
    end;

  TempSection:=SectionBase^.At(SR.CurSec);

  SR.CurKey:=i;
  SR.Key:=S;

  for i:=0 to TempSection^.Count-1 do
    begin
      TempParsed:=TempSection^.At(i);
      If TempParsed^.Keyword^=S then
        begin
          sTemp:=strTrimB(TempParsed^.Value^,[#32,#9]);
          Break;
        end;
    end;

  SR.CurKey:=i;
  SR.Key:=S;

  If sTemp='' then
    begin
      CTLError:=ctlErrCantFindParameter;
      CTLSError:=S;
    end;
  FindFirstValue:=sTemp;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Function TIniCTL.FindSection(S:string):longint;
Var
 i:integer;
 pTemp:^string;
begin
  FindSection:=-1;

  for i:=0 to SectionNames^.Count-1 do
    begin
      pTemp:=SectionNames^.At(i);
      if pTemp^=strUpper(S) then FindSection:=i;
    end;

end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

Procedure TIniCTL.ModifyValue(Section:string;Keyword:string;
                          Value:string);
Var
 i:integer;
 TempSection : PParsed;
 TempParsedItem : PParsedItem;
begin

  i:=FindSection(Section);

  If i=-1 then Exit;

  TempSection:=SectionBase^.At(i);

  for i:=0 to TempSection^.Count-1 do
    begin
      TempParsedItem:=TempSection^.At(i);
      If TempParsedItem^.Keyword^=Keyword then
        begin
          TempParsedItem^.Value^:=Value;
          Break;
        end;
    end;

  If TempParsedItem^.Keyword^<>Keyword then
    begin
      TempParsedItem:=New(PParsedItem,Init(Keyword,Value));
      TempSection^.Insert(TempParsedItem);
    end;

end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

end.
