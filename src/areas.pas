{
 Areas Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
 SaveConfig ¢ ¯®àï¤®ª ¯à¨¢¥áâ¨
 tempObject ==> tempNode
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
  r8ctl,
  lng,
  crt,
  objects;

const
  modNone    = $0000;
  modRead    = $0001;  { ! }
  modWrite   = $0002;  { ~ }
  modLocked  = $0004;  { & }
  modPassive = $0008;  { # }

  AreaFlags : TCharset = ['E','H','P','S'];

Type

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TNodelistItem = object(TObject)
    Address : TAddress;
    Node : Pointer;
    Mode : word;

    Constructor Init(const ANode:Pointer;const AMode:word);
    Destructor Done;virtual;
  end;
  PNodelistItem = ^TNodelistItem;

  TNodeList = object(TSortedCollection)
    Procedure FreeItem(item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PNodeList = ^TNodeList;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TArea = object(TObject)
    Name : PString;
    Desc : PString;

    WriteLevel : word;
    ReadLevel  : word;

    PurgeDays : word;
    PurgeMsgs : word;

    Group : char;

    UseAKA : TAddress;

    Echotype    : TEchoType;
    MessageBase : PMessageBase;
    BaseType : byte;

    Links : PNodeList;

    AddToSeenBys : PAddressSortedCollection;

    Flags : PString;

    Constructor Init(const AName:string);
    Destructor Done;virtual;

    Procedure AddLink(const Address:TAddress;const Mode:word);
    Procedure RemoveLink(const Address:TAddress);
    Function FindLink(const Address:TAddress):Pointer;
    Procedure AddSeenBys(const SeenBys:PCollection);

    Function CheckFlag(const c:char):boolean;
    Procedure SetFlag(const c:char);
    Procedure ClearFlag(const c:char);
  end;
  PArea = ^TArea;

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
    AreaFile : PSectionCTL;
    AreaFileName : PString;
    Modified : boolean;

    Error : string;

    Areas : PAreaCollection;

    Netmail   : PAreaCollection;
    Echomail  : PAreaCollection;
    Local     : PAreaCollection;
    Badmail   : PAreaCollection;
    Dupemail  : PAreaCollection;

    Constructor Init;
    Destructor Done;virtual;

    Function LoadConfigFile(const FileName:string):boolean;
    Procedure SaveConfig;
    Function ParserEchoType(S:string;Area:PArea):boolean;
    Procedure ParserLinks(S:string;Area:PArea;GroupMode:boolean);

    Procedure AddArea(const Area:PArea);
    Function FindArea(const Name:string):PArea;
    Function FindAreaByBase(const Base:string):PArea;

    Function GetAreaDesc(const AreaName:string):string;

    Procedure CheckForPassive;
  end;
  PAreaBase = ^TAreaBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

implementation
Uses
 groups,
 nodes,
 uplinks,
 global;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TNodelistItem.Init(const ANode:pointer;const AMode:word);
begin
  inherited Init;

  Node:=ANode;
  Mode:=AMode;

  If Node<>nil then
    Address:=PNode(Node)^.Address;
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

{$IFDEF VER70}
Function TNodeList.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TNodeList.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  Link1 : PNodelistItem absolute Key1;
  Link2 : PNodelistItem absolute Key2;
begin
  Compare:=ftnAddressCompare(Link1^.Address,Link2^.Address);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TArea.Init(const AName:string);
begin
  inherited Init;

  Name:=NewStr(strUpper(AName));
  Desc:=nil;
  Flags:=nil;

  MessageBase:=nil;
  BaseType:=0;

  UseAka:=InvAddress;

  Links:=New(PNodeList,Init($10,$10));

  AddToSeenBys:=New(PAddressSortedCollection,Init($10,$10));
  AddToSeenBys^.Duplicates:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TArea.Done;
begin
  objDispose(Links);
  objDispose(MessageBase);

  objDispose(AddToSeenBys);

  DisposeStr(Name);
  DisposeStr(Desc);
  DisposeStr(Flags);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TArea.AddLink(const Address:TAddress;const Mode:word);
Var
  TempNodelistItem : PNodelistItem;
  TempObject : PObject;
  i:longint;
begin
  TempObject:=NodeBase^.FindNode(Address);

  if TempObject=nil then exit;

  TempNodelistItem:=New(PNodelistItem,Init(TempObject,Mode));
  TempNodelistItem^.Address:=Address;

  If Address.Point=0 then
    begin
      AddToSeenBys^.Insert(ftnNewAddress(Address));
    end;

  If PNode(TempObject)^.UseAka.Point=0 then
    begin
      AddToSeenBys^.Insert(ftnNewAddress(PNode(TempObject)^.UseAka));
    end;

  Links^.Insert(TempNodelistItem);

  If ftnIsAddressInvalidated(UseAka) then
    If UplinkBase^.FindUplink(Address)<>nil
      then UseAKA:=PNode(TempObject)^.UseAka;
end;

Function TArea.FindLink(const Address:TAddress):pointer;
Var
  TempLink : PNodelistItem;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}
begin
  FindLink:=nil;

  TempLink:=New(PNodelistItem,Init(nil,0));
  TempLink^.Address:=Address;

  If Links^.Search(TempLink,i) then FindLink:=Links^.At(i);

  objDispose(TempLink);
end;

Function TArea.CheckFlag(const c:char):boolean;
begin
  CheckFlag:=false;

  If Flags<>nil then
    If Pos(strUpCaseChar(c),Flags^)<>0 then CheckFlag:=true;
end;

Procedure TArea.SetFlag(const c:char);
begin
  If CheckFlag(c) then exit;

  If Flags<>nil then AssignStr(Flags,Flags^+strUpCaseChar(c))
    else AssignStr(Flags,strUpCaseChar(c));
end;

Procedure TArea.ClearFlag(const c:char);
Var
  S:string;
begin
  If not CheckFlag(c) then exit;

  If Flags<>nil then S:=Flags^;
  Delete(S,Pos(strUpCaseChar(c),S),1);

  AssignStr(Flags,S);
end;

Procedure TAreaCollection.FreeItem(Item:pointer);
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
  i:=Count;
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

  AreaFile:=nil;

  Areas:=New(PAreaCollection,Init($100,$100));

  Netmail:=New(PAreaCollection,Init($10,$10));
  Echomail:=New(PAreaCollection,Init($50,$50));
  Local:=New(PAreaCollection,Init($10,$10));
  Badmail:=New(PAreaCollection,Init($1,$1));
  Dupemail:=New(PAreaCollection,Init($1,$1));

  Modified:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TAreaBase.Done;
begin
  If Modified then SaveConfig;

  objDispose(Areas);

  Echomail^.DeleteAll;
  Netmail^.DeleteAll;
  Local^.DeleteAll;
  Badmail^.DeleteAll;
  Dupemail^.DeleteAll;

  objDispose(Echomail);
  objDispose(Netmail);
  objDispose(Local);
  objDispose(Badmail);
  objDispose(Dupemail);

  DisposeStr(AreaFileName);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAreaBase.ParserLinks(S:string;Area:PArea;GroupMode:boolean);
Var
  i:integer;
  i2:integer;
  sTemp:string;
  PrevAddress : TAddress;
  TempAddress : TAddress;
  TempNode : PNode;
  Mode : byte;
begin
  AddressBase^.GetAddress(0,PrevAddress);

  S:=strTrimB(S,[#32,#9]);

  If S='' then exit;

  For i:=1 to strNumbOfTokens(S,[#32,#9]) do
    begin
      sTemp:=strParser(S,i,[#32,#9]);
      Mode:=modNone;

      Case sTemp[1] of
        '!' :
          begin
            Mode:=modRead;
            sTemp:=Copy(sTemp,2,Length(sTemp)-1);
          end;
        '~' :
          begin
            Mode:=modWrite;
            sTemp:=Copy(sTemp,2,Length(sTemp)-1);
          end;
        '&' :
          begin
            Mode:=modLocked;
            sTemp:=Copy(sTemp,2,Length(sTemp)-1);
          end;
        '#' :
          begin
            Mode:=modPassive;
            sTemp:=Copy(sTemp,2,Length(sTemp)-1);
          end;
      end;

      if Mode=modNone then Mode:=modRead or modWrite;

      TempAddress:=PrevAddress;
      ftnStrToAddress(sTemp,TempAddress);

      TempNode:=NodeBase^.FindNode(TempAddress);

      if TempNode=nil then
        begin
          Lngfile^.AddVar(Area^.Name^);
          Lngfile^.AddVar(ftnAddressToStrEx(TempAddress));
          ErrorOut(LngFile^.GetString(LongInt(lngInvalidNode)));
        end;

      If not GroupMode then TempNode^.AddArea(Area^.Name^,Mode);
      Area^.AddLink(TempAddress,Mode);

      PrevAddress:=TempAddress;
    end;
end;

Function TAreaBase.ParserEchoType(S:string;Area:PArea):boolean;
begin
  ParserEchoType:=True;
  Area^.EchoType.Storage:=etPassThrough;

  If S='' then exit;

  Area^.EchoType.Path:=strLower(S);
  S:=strUpper(S);
  S:=Copy(S,1,3);

  If S='MSG' then Area^.EchoType.Storage:=etMSG
  else
  If S='SQH' then Area^.EchoType.Storage:=etSquish
  else
  If S='JAM' then Area^.EchoType.Storage:=etJAM
{  else
  If S='SMB' then Area^.EchoType.Storage:=etSMB
  else
  If S='HUD' then Area^.EchoType.Storage:=etHudson}
  else ParserEchoType:=False;
end;

Function TAreaBase.LoadConfigFile(const FileName:string):boolean;
Var
  i  : longint;
  i2 : byte;
  SR:CTLSR;
  TempArea : PArea;
  TempGroup : PGroup;

  sTemp : string;
  TempAddress : TAddress;
begin
  AreaFileName:=NewStr(FileName);

  AreaFile:=New(PSectionCtl,Init('BEGINAREA','ENDAREA'));

  AreaFile^.SetErrorMessages(LngFile^.GetString(LongInt(lngctlCantFindFile)),
     LngFile^.GetString(LongInt(lngctlUnknownKeyword)),
     LngFile^.GetString(LongInt(lngctlLoopInclude)));

  AreaFile^.AddKeyword('Name');
  AreaFile^.AddKeyword('Desc');
  AreaFile^.AddKeyword('Type');
  AreaFile^.AddKeyword('Group');
  AreaFile^.AddKeyword('UseAka');
  AreaFile^.AddKeyword('Path');
  AreaFile^.AddKeyword('Flags');
  AreaFile^.AddKeyword('PurgeDays');
  AreaFile^.AddKeyword('PurgeMsgs');
  AreaFile^.AddKeyword('Links');
  AreaFile^.AddKeyword('WriteLevel');
  AreaFile^.AddKeyword('ReadLevel');

  AreaFile^.SetCTLName(dosMakeValidString(FileName));
  AreaFile^.LoadCTL;

  If AreaFile^.CTLError<>ctlErrNone
      then ErrorOut(AreaFile^.ExplainStatus(AreaFile^.CTLError));

  For i:=0 to AreaFile^.GetSectionCount-1 do
    begin
      sTemp:=AreaFile^.FindFirstValue(i,'Name',SR);
      If AreaFile^.CTLError<>0 then continue;

      If AreaBase^.FindArea(sTemp)<>nil then
        begin
          LngFile^.AddVar(strUpper(sTemp));
          ErrorOut(LngFile^.GetString(LongInt(lngDuplicateEntry)));
        end;

      TempArea:=New(PArea,Init(sTemp));
      sTemp:=strUpper(AreaFile^.FindFirstValue(i,'Type',SR));
      If AreaFile^.CTLError<>0 then
        begin
          Lngfile^.AddVar(TempArea^.Name^);
          objDispose(TempArea);
          ErrorOut(LngFile^.GetString(LongInt(lngInvalidAreaType)));
        end;

      If sTemp='NET' then TempArea^.BaseType:=btNetmail else
      If sTemp='ECHO' then TempArea^.BaseType:=btEchomail else
      If sTemp='LOCAL' then TempArea^.BaseType:=btLocal else
      If sTemp='DUPE' then TempArea^.BaseType:=btDupemail else
      If sTemp='BAD' then TempArea^.BaseType:=btBadmail else
        begin
          Lngfile^.AddVar(TempArea^.Name^);
          objDispose(TempArea);
          ErrorOut(LngFile^.GetString(LongInt(lngInvalidAreaType)));
        end;

      AreaBase^.AddArea(TempArea);

      AssignStr(TempArea^.Desc,AreaFile^.FindFirstValue(i,'Desc',SR));

      sTemp:=AreaFile^.FindFirstValue(i,'Group',SR);
      TempGroup:=Pointer(GroupBase^.FindArea(sTemp));
      If TempGroup=nil then
        begin
          LngFile^.AddVar(TempArea^.Name^);
          ErrorOut(LngFile^.GetString(LongInt(lngInvalidGroup)));
        end;
      TempGroup^.ItemBase^.AddArea(TempArea);
      TempArea^.Group:=sTemp[1];

      sTemp:=AreaFile^.FindFirstValue(i,'Path',SR);
      If not ParserEchoType(sTemp,TempArea) then
        begin
          ErrorOut(TempArea^.Name^+': '+LngFile^.GetString(LongInt(lngInvalidEchotype)));
        end;

      sTemp:=AreaFile^.FindFirstValue(i,'ReadLevel',SR);
      TempArea^.ReadLevel:=strStrToInt(sTemp);
      If AreaFile^.CTLError<>0 then TempArea^.ReadLevel:=0;

      sTemp:=AreaFile^.FindFirstValue(i,'WriteLevel',SR);
      TempArea^.WriteLevel:=strStrToInt(sTemp);
      If AreaFile^.CTLError<>0 then TempArea^.WriteLevel:=0;

      sTemp:=AreaFile^.FindFirstValue(i,'PurgeDays',SR);
      TempArea^.PurgeDays:=strStrToInt(sTemp);

      sTemp:=AreaFile^.FindFirstValue(i,'PurgeMsgs',SR);
      TempArea^.PurgeMsgs:=strStrToInt(sTemp);

      sTemp:=AreaFile^.FindFirstValue(i,'Flags',SR);
      While Pos(#32,sTemp)<>0 do Delete(sTemp,Pos(#32,sTemp),1);
      AssignStr(TempArea^.Flags,strUpper(sTemp));

      If TempArea^.Flags<>nil then
        For i2:=1 to Length(TempArea^.Flags^) do
          If not (TempArea^.Flags^[i2] in AreaFlags) then
            begin
              LngFile^.AddVar(TempArea^.Name^);
              LngFile^.AddVar(TempArea^.Flags^[i2]);
              ErrorOut(LngFile^.GetString(LongInt(lngInvalidFlag)));
            end;

      TempArea^.UseAka:=InvAddress;
      AreaFile^.FindFirstAddressValue(i,'UseAKA',TempAddress,SR);
      If AreaFile^.CTLError=0 then TempArea^.UseAka:=TempAddress;

      sTemp:=AreaFile^.FindFirstValue(i,'Links',SR);
      While AreaFile^.CTLError=0 do
        begin
          ParserLinks(sTemp,TempArea,False);
          sTemp:=AreaFile^.FindNextValue(SR);
        end;
    end;

  If BadMail^.Count=0
    then ErrorOut(LngFile^.GetString(LongInt(lngNoBadmail)))
  else
  If BadMail^.Count>1
    then ErrorOut(LngFile^.GetString(LongInt(lngNotOneBadmail)));

  If DupeMail^.Count=0
    then ErrorOut(LngFile^.GetString(LongInt(lngNoDupemail)))
  else
  If DupeMail^.Count>1
    then ErrorOut(LngFile^.GetString(LongInt(lngNotOneDupemail)));

  objDispose(AreaFile);
  LoadConfigFile:=True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAreaBase.AddArea(const Area:PArea);
begin
  Areas^.Insert(Area);

  Case Area^.BaseType of
    btNetmail  : Netmail^.Insert(Area);
    btEchomail : Echomail^.Insert(Area);
    btLocal    : Local^.Insert(Area);
    btBadmail  : Badmail^.Insert(Area);
    btDupemail : Dupemail^.Insert(Area);
  end;
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

Procedure TArea.RemoveLink(const Address:TAddress);
Var
  P:pointer;
begin
  P:=FindLink(Address);
  If P=nil then exit;

  Links^.Free(P);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TAreaBase.GetAreaDesc(const AreaName:string):string;
Var
  TempArea : PArea;
  i:longint;
begin
  GetAreaDesc:='';

  TempArea:=FindArea(AreaName);
  If TempArea=nil then exit;
  GetAreaDesc:=TempArea^.Desc^;
end;

Procedure TAreaBase.SaveConfig;
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

  Assign(T,AreaFileName^);
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

      sTemp:=AreaFileName^;
      Dec(sTemp[0]);
      sTemp:=sTemp+'$';
      dosMove(AreaFileName^,sTemp);
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

          If not ftnIsAddressInvalidated(TempArea^.UseAka) then
            WriteLn(T,'  UseAka ',ftnAddressToStrEx(TempArea^.UseAka));

          Write(T,'  Type ');
          Case TempArea^.BaseType of
            btNetmail  : WriteLn(T,'Net');
            btEchomail : WriteLn(T,'Echo');
            btLocal    : WriteLn(T,'Local');
            btBadmail  : WriteLn(T,'Bad');
            btDupemail : WriteLn(T,'Dupe');
          end;

          If TempArea^.Flags<>nil then
              WriteLn(T,'  Flags ',TempArea^.Flags^);

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

          If TempArea^.Links^.Count<>0 then
            NodeList(S,TempArea^.Links,'  Links ',True,'!','~','&','#');

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
  Modified:=False;
end;

Procedure TAreaBase.CheckForPassive;
  Procedure CheckActive(Area:PArea);far;
  var
    UplinkCount : longint;
    TempUplink  : PUplink;

    Procedure CountUplinks(Link:PNodelistItem);far;
    var
      P:pointer;
    begin
      P:=UplinkBase^.FindUplink(Link^.Address);
      If P<>nil then
        begin
         TempUplink:=P;
         Inc(UplinkCount);
        end;
    end;

    Function CheckLink(Link:PNodelistItem):boolean;far;
    begin
      CheckLink:=False;

      If UplinkBase^.FindUplink(Link^.Address)<>nil then exit;

      If Link^.Mode<>modPassive then Inc(UplinkCount);
    end;
  begin
    If Area^.Echotype.Storage<>etPassthrough then exit else
      If Area^.CheckFlag('P') then exit;

    UplinkCount:=0;
    TempUplink:=nil;

    Area^.Links^.ForEach(@CountUpLinks);
    Area^.Links^.FirstThat(@CheckLink);
    If (UplinkCount>1) or (TempUplink=nil) then exit;

    TempUplink^.Requests^.Insert(NewStr('-'+Area^.Name^));
    Area^.SetFlag('P');

    Writeln('Area ',Area^.Name^,' set to passive...');
    Logfile^.SendStr('Area '+Area^.Name^+' set to passive.',' ');

    AreaBase^.Modified:=true;
  end;

  Procedure CheckPassive(Area:PArea);far;
  var
    UplinkCount : longint;
    TempUplink  : PUplink;

    Procedure CountUplinks(Link:PNodelistItem);far;
    var
      P:pointer;
    begin
      P:=UplinkBase^.FindUplink(Link^.Address);
      If P<>nil then
        begin
         TempUplink:=P;
         Inc(UplinkCount);
        end;
    end;
    Procedure FindUpLink(Link:PNodelistItem);far;
    begin
      TempUplink:=UplinkBase^.FindUplink(Link^.Address);
      If TempUplink=nil then exit;
      TempUplink^.Requests^.Insert(NewStr('+'+Area^.Name^));
    end;
    Function CheckLink(Link:PNodelistItem):boolean;far;
    begin
      CheckLink:=False;

      If UplinkBase^.FindUplink(Link^.Address)<>nil then exit;

      If Link^.Mode<>modPassive then CheckLink:=True;
    end;
  begin
    If not Area^.CheckFlag('P') then exit;

    UplinkCount:=0;

    Area^.Links^.ForEach(@CountUpLinks);

    If Area^.Links^.FirstThat(@CheckLink)=nil then exit else
      If UplinkCount=0 then exit;

    Area^.Links^.ForEach(@FindUplink);

    Writeln('Area ',Area^.Name^,' set to active...');
    Logfile^.SendStr('Area '+Area^.Name^+' set to active.',' ');

    AreaBase^.Modified:=true;
    Area^.ClearFlag('P');
  end;
begin
  If EchoMail<>nil then EchoMail^.ForEach(@CheckActive);
  If EchoMail<>nil then EchoMail^.ForEach(@CheckPassive);
  Writeln;
end;

end.
