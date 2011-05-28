{
 ImportList Stuff
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit IList;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8str,
  r8objs,
  r8dos,

  areas,

  objects;

Type

  TImportList = object(TObject)
    FileName : PString;
    Bases : PString;
    Areas : PStringCollection;

    Constructor Init(const AFileName,ABases:string);
    Destructor  Done; virtual;
    Procedure Read;
    Procedure Write;
    Procedure AddArea(const S:string);
   end;
  PImportList = ^TImportList;

  TImportListCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PImportListCollection = ^TImportListCollection;

  TImportLists = object(TObject)
    Lists : PImportListCollection;

    Constructor Init;
    Destructor  Done; virtual;
    Procedure AddList(const AFileName,ABases:string);
    Procedure AddArea(const Area:PArea);
    Procedure Read;
  end;
  PImportLists = ^TImportLists;

implementation

Uses
  global,
  lng;

Constructor TImportList.Init(const AFileName,ABases:string);
begin
  inherited Init;

  FileName:=NewStr(AFileName);
  Bases:=NewStr(strUpper(ABases));
  Areas:=New(PStringCollection,Init($10,$10));
end;

Destructor TImportList.Done;
begin
  Write;

  DisposeStr(FileName);
  DisposeStr(Bases);
  Areas^.FreeAll;
  objDispose(Areas);

  inherited Done;
end;

Procedure TImportList.Read;
Var
  T : text;
  sTemp : string;
begin
  If (FileName=nil) or (not dosFileExists(FileName^)) then exit;

  Assign(T,FileName^);
{$I-}
  Reset(T);
{$I+}

  If IOResult<>0 then exit;

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      Areas^.Insert(NewStr(sTemp));
    end;

  Close(T);
end;

Procedure TImportList.Write;
Var
  T : text;

  Procedure WriteLine(P:Pointer);
  begin
    WriteLn(T,PString(P)^);
  end;

begin
  If (FileName=nil) or (Areas^.Count=0) then exit;

  Assign(T,FileName^);
{$I-}
  Rewrite(T);
{$I+}

  LngFile^.AddVar(FileName^);

  If IOResult<>0 then
    begin
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngCantCreateFile)),'!');
      exit;
    end;

  LngFile^.AddVar(strintToStr(Areas^.Count));
  LogFile^.SendStr(LngFile^.GetString(LongInt(lngWritingImportList)),'#');

  Areas^.ForEach(@WriteLine);

  Close(T);
end;

Procedure TImportList.AddArea(const S:string);
var
 TempString : PString;
 i : longint;
begin
  i:=Areas^.Count;
  TempString:=NewStr(S);
  Areas^.Insert(TempString);
  if Areas^.Count=i then DisposeStr(TempString);
end;

Procedure TImportListCollection.FreeItem(Item:pointer);
begin
  objDispose(PImportList(Item));
end;

Constructor TImportLists.Init;
begin
  inherited Init;

  Lists:=New(PImportListCollection,Init($10,$10));
end;

Destructor TImportLists.Done;
begin
  objDispose(Lists);

  inherited Done;
end;

Procedure TImportLists.AddList(const AFileName,ABases:string);
Var
  i : longint;
  sTemp : string;
  TempList : PImportList;
begin
  sTemp:=strUpper(ABases);

  For i:=0 to strNumbofTokens(sTemp,[','])-1 do
    If not MessageBasesEngine^.CheckPrefix(strParser(sTemp,i+1,[','])) then
      begin
        ErrorOut(AFileName+': '+LngFile^.GetString(LongInt(lngInvalidEchotype)));
      end;

  TempList:=New(PImportList,Init(AFileName,sTemp));
  Lists^.Insert(TempList);
end;

Procedure TImportLists.AddArea(const Area:PArea);
Var
  sTemp : string;

  Procedure CheckList(P:pointer);far;
  begin
    If (PImportList(P)^.Bases=nil) or
      (Pos(sTemp,PImportList(P)^.Bases^)<>0)
        then PImportList(P)^.AddArea(Area^.Name^);
  end;
begin
  sTemp:=strUpper(Copy(Area^.Echotype.Path,1,3));
  Lists^.ForEach(@CheckList);
end;

Procedure TImportLists.Read;
  Procedure ReadList(P:pointer);far;
  begin
    PImportList(P)^.Read;
  end;
begin
  Lists^.ForEach(@ReadList);
end;

end.