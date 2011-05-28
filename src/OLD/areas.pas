{
 Areas Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Areas;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8objs,
  dos,
  r8crc,
  r8dos,
  r8ftn,
  r8str,
  r8mail,
  crt,
  objects;

const
  modNone   = $00;
  modRead   = $01;
  modWrite  = $02;
  modLocked = $04;

  AreaFlags : TCharset = ['L','P'];

Type

  TRulesitem = packed record
    FileName : string[12];
    Areaname : string[21];
   end;

  PRulesitem =  ^TRulesitem;

  TRulesCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
  end;

  PRulesCollection = ^TRulesCollection;

  TNodelistItem = object(TObject)
    Node : PObject;
    Mode : byte;

    Constructor Init(const ANode:PObject;const AMode:byte);
    Destructor Done;virtual;
  end;
  PNodelistItem = ^TNodelistItem;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TNodeList = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PNodeList = ^TNodeList;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TArea = object(TObject)
    Name : PString;
    Desc : PString;
    RulesFile : PString;

    WriteLevel : byte;
    ReadLevel  : byte;

    PurgeDays : word;
    PurgeMsgs : word;

    Group : string[1];

    Echotype : TEchoType;
    MessageBase : PMessageBase;

    Links : PNodeList;

    AddToSeenBys : PAddressSortedCollection;

    Flags : string[30];

    Constructor Init(const AName:string);
    Destructor Done;virtual;

    Procedure ChangeName(const AName:string);
    Procedure ChangeDesc(const ADesc:string);
    Procedure ChangeRulesFile(const AFile:string);

    Procedure AddLink(Address:TAddress;Mode:byte);
    Procedure RemoveLink(Address:TAddress);
    Function FindLink(Address:TAddress):Pointer;
    Procedure AddSeenBys(const SeenBys:PCollection);

    Function CheckFlag(S:string):boolean;
    Procedure SetFlag(S:string);
    Procedure ClearFlag(S:string);
  end;

  PArea = ^TArea;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAreaCollection = object(TSortedCollection)
    Procedure FreeItem(item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
    Procedure CloseBases;
  end;

  PAreaCollection = ^TAreaCollection;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAreaBase = object(TObject)
    RulesDir : string;
    RulesId : string;

    Modified : boolean;
    Areas : PAreaCollection;
    RulesCollection : PRulesCollection;

    Constructor Init;
    Destructor Done;virtual;
    Procedure AddArea(Area:PArea);
    Function FindArea(const Name:string):PArea;
    Function FindAreaByBase(const Base:string):PArea;

    Function GetAreaDesc(AreaName:string):string;

    Procedure LoadRules;
    Procedure CompileRules;
  end;

  PAreaBase = ^TAreaBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  THudsonBoard = record
    Board : integer;
    Area : PArea;
  end;

  PHudsonBoard = ^THudsonBoard;

  THudsonBoards = object(TSortedCollection)
    Procedure FreeItem(Item:Pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;

  PHudsonBoards = ^THudsonBoards;

  THudsonIndex = object(TObject)
    Index : PHudsonBoards;

    Constructor Init;
    Destructor Done;virtual;
    Function FindBoard(i:integer):PHudsonBoard;
    Function AddBoard(i:integer;Area:PArea):boolean;
  end;

  PHudsonIndex =  ^THudsonIndex;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure WriteAreaFile;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

implementation
Uses
    groups,
    nodes,
    global;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TNodelistItem.Init(const ANode:PObject;const AMode:byte);
begin
  inherited Init;

  Node:=ANode;
  Mode:=AMode;
end;

Destructor TNodelistItem.Done;
begin
  Inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TNodeList.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(PNodelistItem(Item));
End;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TArea.Init(const AName:string);
begin
  inherited Init;

  Name:=NewStr(strUpper(AName));
  Desc:=nil;
  RulesFile:=nil;
  EchoBase:=nil;

  Links:=New(PNodeList,Init($10,$10));

  AddToSeenBys:=New(PAddressSortedCollection,Init($10,$10));
  AddToSeenBys^.Duplicates:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TArea.Done;
begin
  objDispose(Links);
  objDispose(EchoBase);

  objDispose(AddToSeenBys);

  DisposeStr(Name);
  DisposeStr(Desc);
  DisposeStr(RulesFile);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TArea.AddLink(Address:TAddress;Mode:byte);
Var
  TempNodelistItem : PNodelistItem;
  TempObject : PObject;
  i:longint;
begin
  TempObject:=NodeBase^.FindNode(Address);

  if TempObject=nil then exit;

  TempNodelistItem:=New(PNodelistItem,Init(TempObject,Mode));

  If Address.Point=0 then
    begin
      AddToSeenBys^.Insert(ftnNewAddress(Address));
    end;

  If PNode(TempObject)^.UseAka.Point=0 then
    begin
      AddToSeenBys^.Insert(ftnNewAddress(PNode(TempObject)^.UseAka));
    end;

  Links^.Insert(TempNodelistItem);
end;

Function TArea.FindLink(Address:TAddress):pointer;
Var
  TempNodelistItem : PNodelistItem;
  i:integer;
begin
  FindLink:=nil;

  For i:=0 to Links^.Count-1 do
    begin
      TempNodelistItem:=Links^.At(i);
      If ValidLink(Address,TempNodelistItem^.Node) then
        begin
          FindLink:=TempNodelistItem;
          break;
        end;
    end;
end;

Function TArea.CheckFlag(S:string):boolean;
begin
  CheckFlag:=false;
  S:=strUpper(S);
  If Pos(S,Flags)<>0 then CheckFlag:=true;
end;

Procedure TArea.SetFlag(S:string);
begin
  S:=strUpper(S);
  If CheckFlag(S) then exit;

  Flags:=Flags+S;
end;

Procedure TArea.ClearFlag(S:string);
begin
  S:=strUpper(S);
  If not CheckFlag(S) then exit;

  Delete(Flags,Pos(S,Flags),1);
end;

Procedure TArea.ChangeName(const AName:string);
begin
  DisposeStr(Name);
  Name:=NewStr(AName);
end;

Procedure TArea.ChangeDesc(const ADesc:string);
begin
  If Desc<>nil then DisposeStr(Desc);
  Desc:=NewStr(ADesc);
end;

Procedure TArea.ChangeRulesFile(const AFile:string);
begin
  DisposeStr(RulesFile);
  RulesFile:=NewStr(AFile);
end;

Procedure TAreaCollection.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(PArea(Item));
End;

{$IFDEF VER70}
Function TAreaCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TAreaCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  S1,S2:String;
begin
  S1:=PArea(Key1)^.Name^;
  S2:=PArea(Key2)^.Name^;

  If S1>S2 then Compare:=1 else
  If S1<S2 then Compare:=-1 else
  Compare:=0;
end;

Procedure TAreaCollection.CloseBases;
var
  i:longint;
begin
  For i:=0 to Count-1
    do MessageBasesEngine^.DisposeBase(PArea(At(i))^.MessageBase);
end;

Procedure TArea.AddSeenBys(const SeenBys:PCollection);
  Procedure AddSeenBy(Item:pointer);
  begin
    SeenBys^.Insert(ftnNewAddress(PAddress(Item)^));
  end;
begin
  AddToSeenBys^.ForEach(@AddSeenBy);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TAreaBase.Init;
begin
  inherited Init;

  Areas:=New(PAreaCollection,Init($50,$50));
  RulesCollection:=New(PRulesCollection,Init($10,$10));
  Modified:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TAreaBase.Done;
begin
  objDispose(Areas);
  objDispose(RulesCollection);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAreaBase.AddArea(Area:PArea);
begin
  Areas^.Insert(Area);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TAreaBase.FindArea(const Name:string):PArea;
Var
  TempArea : PArea;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}
  CRC : longint;
begin
  FindArea:=nil;

  TempArea:=New(PArea,Init(Name));
  If Areas^.Search(TempArea,i) then FindArea:=Areas^.At(i);
  objDispose(TempArea);
end;

Function TAreaBase.FindAreaByBase(const Base:string):PArea;
Var
  TempArea : PArea;
  i : longint;
  sTemp : string;
begin
  FindAreaByBase:=nil;

  For i:=0 to Areas^.Count-1 do
    begin
      TempArea:=Areas^.At(i);

      sTemp:=strUpper(Copy(TempArea^.EchoType.Path,4,Length(TempArea^.EchoType.Path)-3));
      If sTemp=Base then
        begin
          FindAreaByBase:=TempArea;
          exit;
        end;
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TArea.RemoveLink(Address:TAddress);
Var
  P:pointer;
begin
  P:=FindLink(Address);
  If P=nil then exit;

  Links^.Free(P);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TAreaBase.GetAreaDesc(AreaName:string):string;
Var
  TempArea : PArea;
  i:longint;
begin
  GetAreaDesc:='';

  TempArea:=FindArea(AreaName);
  If TempArea=nil then exit;
  GetAreaDesc:=TempArea^.Desc^;
end;

Procedure WriteAreaFile;
Var
  sTemp : string;
  pTemp : PString;
  FileHeader:PStringsCollection;
  i:integer;
  i2:integer;
  iTemp:longint;
  T : text;
  TempArea:PArea;
  TempGroup : pGroup;
  S:PStream;
begin
  TextColor(7);

  WriteLn('Saving areas coniguration...');
  WriteLn;

  FileHeader:=New(PStringsCollection,Init($10,$10));
  pTemp:=New(PString);

  Assign(T,HomeDir+'\spctoss.ar');
{$I-}
  Reset(T);
{$I+}

  If IOResult=0 then
    begin
      While not Eof(T) do
        begin
          ReadLn(T,sTemp);
          pTemp^:=strTrimL(sTemp,[#32]);
          If pTemp^[1]<>';' then break;
          FileHeader^.Insert(NewStr(sTemp+#32));
        end;

      Close(T);

      dosMove(HomeDir+'\spctoss.ar',HomeDir+'\spctoss.ar$');
    end;

  Dispose(pTemp);

  Rewrite(T);

  For i:=0 to FileHeader^.Count-1 do
    begin
      pTemp:=FileHeader^.At(i);
      WriteLn(T,pTemp^)
    end;

  For i:=0 to GroupBase^.Areas^.Count-1 do
    begin
      TempGroup:=GroupBase^.Areas^.At(i);

      For i2:=0 to TempGroup^.ItemBase^.Areas^.Count-1 do
        begin
          TempArea:=TempGroup^.ItemBase^.Areas^.At(i2);

          WriteLn(T,'BeginArea');

          WriteLn(T,'  Name ',TempArea^.Name^);
          If TempArea^.Desc<>nil then
                      WriteLn(T,'  Desc ',TempArea^.Desc^);

          WriteLn(T,'  Group ',TempArea^.Group);

          If Length(TempArea^.Flags)<>0 then
              WriteLn(T,'  Flags ',TempArea^.Flags);

          If TempArea^.ReadLevel<>0 then
                      WriteLn(T,'  ReadLevel ',TempArea^.ReadLevel);

          If TempArea^.WriteLevel<>0 then
                      WriteLn(T,'  WriteLevel ',TempArea^.WriteLevel);

          If TempArea^.PurgeDays<>0 then
                      WriteLn(T,'  PurgeDays ',TempArea^.PurgeDays);

          If TempArea^.PurgeMsgs<>0 then
                      WriteLn(T,'  PurgeMsgs ',TempArea^.PurgeMsgs);

          If TempArea^.EchoType.Storage<>etPassThrough then
                      WriteLn(T,'  Path ',TempArea^.EchoType.Path);

          S:=New(PMemoryStream,Init(0,cBuffSize));

          NodeList(S,TempArea^.Links,'  Links ',True,'!','~','&');

          S^.Seek(0);
          iTemp:=S^.GetSize;


      If iTemp<>0 then
          While S^.GetPos<iTemp-1 do
            begin
              sTemp:=objStreamReadLn(S);
              WriteLn(T,sTemp);
            end;

          objDispose(S);

          WriteLn(T,'EndArea');
          WriteLn(T,'');
        end;
      end;

  Close(T);
  objDispose(FileHeader);
end;

Procedure TAreaBase.LoadRules;
Var
  F : File;
  TempRules : PRulesItem;
  TempArea : PArea;
  i:longint;
  i2:longint;
begin
  If RulesDir='' then exit;

  If not dosFileExists(HomeDir+'\rules.dat') then
    begin
      CompileRules;
      exit;
    end;

  Assign(F,HomeDir+'\rules.dat');
  Reset(F,1);

  While not Eof(F) do
    begin
      New(TempRules);
      Blockread(F,TempRules^,SizeOf(TempRules^));
      RulesCollection^.Insert(TempRules);
    end;

  Close(F);

  If RulesCollection^.Count>0 then
    begin
      For i:= 0 to RulesCollection^.Count-1 do
        begin
          TempRules:=RulesCollection^.At(i);

          TempArea:=FindArea(TempRules^.AreaName);
          If TempArea=nil then continue;

          TempArea^.ChangeRulesFile(TempRules^.FileName);
        end;
    end;

end;

Procedure TAreaBase.CompileRules;
Var
  F : File;
  T : Text;
  SR : SearchRec;
  sTemp:string;
  TempRules : PRulesItem;
  i:longint;
begin
  If RulesDir='' then exit;

  LogFile^.SendStr('Indexing rules files...',' ');

  FindFirst(RulesDir+'\*.*',AnyFile-Directory,SR);
  While DosError=0 do
    begin
      Assign(T,RulesDir+'\'+SR.Name);
      Reset(T);
      Readln(T,sTemp);
      Close(T);

      If Copy(sTemp,1,Length(RulesId))=RulesId then
        begin
          sTemp:=Copy(sTemp,Length(RulesId)+1,
               Length(sTemp)-Length(RulesId));

          New(TempRules);
          TempRules^.FileName:=SR.Name;
          TempRules^.AreaName:=strUpper(sTemp);
          RulesCollection^.Insert(TempRules);
        end;

      FindNext(SR);
    end;
{$IFNDEF VER70}
  FindClose(SR);
{$ENDIF}

  If RulesCollection^.Count>0 then
    begin
      Assign(F,HomeDir+'\rules.dat');
      Rewrite(F,1);

      For i:= 0 to RulesCollection^.Count-1 do
        begin
          TempRules:=RulesCollection^.At(i);
          BlockWrite(F,TempRules^,SizeOf(TempRules^));
        end;

      Close(F);
    end;

  LogFile^.SendStr(strIntToStr(RulesCollection^.Count)
             +' files was indexed sucessfully...',' ');
end;

Procedure TRulesCollection.FreeItem(Item:pointer);
begin
  Dispose(PRulesitem(Item));
end;

Procedure THudsonBoards.FreeItem(Item:Pointer);
begin
  Dispose(PHudsonBoard(Item));
end;

{$IFDEF VER70}
Function THudsonBoards.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function THudsonBoards.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
begin
  If PHudsonBoard(Key1)^.Board>PHudsonBoard(Key2)^.Board then Compare:=1
  else
  If PHudsonBoard(Key1)^.Board<PHudsonBoard(Key2)^.Board then Compare:=-1
  else Compare:=0;
end;

Constructor THudsonIndex.Init;
begin
  inherited Init;
  Index:=New(PHudsonBoards,Init(256,256));
end;

Destructor THudsonIndex.Done;
begin
  objDispose(Index);
  inherited Done;
end;

Function THudsonIndex.FindBoard(i:integer):PHudsonBoard;
Var
  TempBoard : PHudsonBoard;
{$IFDEF VER70}
  iTemp : integer;
{$ELSE}
  iTemp : longint;
{$ENDIF}
begin
  FindBoard:=nil;
  If Index^.Count=0 then exit;

  TempBoard:=New(PHudsonBoard);
  TempBoard^.Board:=i;


  If Index^.Search(TempBoard,iTemp)
      then FindBoard:=Index^.At(iTemp);

  Dispose(TempBoard);
end;

Function THudsonIndex.AddBoard(i:integer;Area:PArea):boolean;
Var
  TempBoard : PHudsonBoard;
begin
  AddBoard:=False;

  If FindBoard(i)<>nil then exit;

  TempBoard:=New(PHudsonBoard);
  TempBoard^.Board:=i;
  TempBoard^.Area:=Area;

  Index^.Insert(TempBoard);

  AddBoard:=True;
end;

end.
