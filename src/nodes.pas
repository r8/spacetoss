{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit Nodes;

interface

Uses
  r8objs,
  r8out,
  r8ftn,
  r8dos,
  r8pkt,
  r8str,
  crt,
  objects;

const
  NodeFlags : TCharset = ['A','B','R'];

Type
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAreaListItem = object(TObject)
    Area : PObject;
    Mode : byte;

    Constructor Init(_Area:PObject;_Mode:byte);
    Destructor Done;virtual;
  end;
  PAreaListItem =  ^TAreaListItem;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TAreaList = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;
  PAreaList = ^TAreaList;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TNode = object(TObject)
    Address : TAddress;
    SysopName : PString;
    PktPassword : PString;
    AreafixPassword : PString;
    UseAKA      : TAddress;
    Archiver      : PString;
    Flavour : word;
    Level : byte;
    Groups : string[30];
    Flags : string[30];

    PktType : longint;

    MaxPktSize,
    MaxArcSize : longint;

    Areas : PAreaList;
    Packet : PPacket;

    Outbound : POutbound;

    Constructor Init(_Address:TAddress);
    Destructor Done;virtual;
    Procedure AddArea(Area:string;Mode:byte);

    Procedure ChangeSysopName(const _S:string);
    Procedure ChangePktPassword(const _S:string);
    Procedure ChangeAreafixPassword(const _S:string);
    Procedure ChangeArchiver(const _S:string);

    Function CheckFlag(S:string):boolean;
    Procedure SetFlag(S:string);
    Procedure ClearFlag(S:string);
  end;

  PNode = ^TNode;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TNodeCollection = object(TCollection)
    Procedure FreeItem(Item:pointer);virtual;
    Procedure ClosePackets;
  end;
  PNodeCollection = ^TNodeCollection;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

  TNodeBase = object(TObject)
    Nodes : PNodeCollection;
    Modified : boolean;

    Constructor Init;
    Destructor Done;virtual;
    Procedure AddNode(Node:PNode);
    Function FindNode(Address:TAddress):PNode;
    Function GetGroups(Address:TAddress):string;
  end;

  PNodeBase = ^TNodeBase;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure WriteNodeFile;

implementation
Uses
   global;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TAreaListItem.Init(_Area:PObject;_Mode:byte);
begin
  Inherited Init;

  Area:=_Area;
  Mode:=_Mode;
end;

Destructor TAreaListItem.Done;
begin
  Inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TAreaList.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(PAreaListItem(Item));
End;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TNode.Init(_Address:TAddress);
begin
  inherited Init;

  Address:=_Address;
  Areas:=New(PArealist,Init($10,$10));

  SysopName:=nil;
  PktPassword:=nil;
  AreafixPassword:=nil;
  Archiver:=nil;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TNode.Done;
begin
  objDispose(Areas);

  DisposeStr(SysopName);
  DisposeStr(PktPassword);
  DisposeStr(AreafixPassword);
  DisposeStr(Archiver);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TNode.AddArea(Area:string;Mode:byte);
Var
  TempObject : PObject;
  TempArealistItem: PArealistItem;
  i:integer;
begin
  TempObject:=Areabase^.FindArea(Area);
  If TempObject=nil then exit;

  TempArealistItem:=New(PArealistItem,Init(TempObject,Mode));

  Areas^.Insert(TempArealistItem);
end;

Function TNode.CheckFlag(S:string):boolean;
begin
  CheckFlag:=false;
  S:=strUpper(S);
  If Pos(S,Flags)<>0 then CheckFlag:=true;
end;

Procedure TNode.SetFlag(S:string);
begin
  S:=strUpper(S);
  If CheckFlag(S) then exit;

  Flags:=Flags+S;
end;

Procedure TNode.ClearFlag(S:string);
begin
  S:=strUpper(S);
  If not CheckFlag(S) then exit;

  Delete(Flags,Pos(S,Flags),1);
end;

Procedure TNode.ChangeSysopName(const _S:string);
begin
  If SysopName<>nil then DisposeStr(SysopName);
  SysopName:=NewStr(_S);
end;

Procedure TNode.ChangePktPassword(const _S:string);
begin
  If PktPassword<>nil then DisposeStr(PktPassword);
  PktPassword:=NewStr(_S);
end;

Procedure TNode.ChangeAreafixPassword(const _S:string);
begin
  If AreafixPassword<>nil then DisposeStr(AreafixPassword);
  AreafixPassword:=NewStr(_S);
end;

Procedure TNode.ChangeArchiver(const _S:string);
begin
  If Archiver<>nil then DisposeStr(Archiver);
  Archiver:=NewStr(_S);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TNodeCollection.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(PNode(Item));
End;

Procedure TNodeCollection.ClosePackets;
var
  i:longint;
begin
  For i:=0 to Count-1
    do objDispose(PNode(At(i))^.Packet);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TNodeBase.Init;
begin
  inherited Init;

  Nodes:=New(PNodeCollection,Init($50,$50));

  Modified:=False;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Destructor TNodeBase.Done;
begin
  objDispose(Nodes);

  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Procedure TNodeBase.AddNode(Node:PNode);
begin
  Nodes^.Insert(Node);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TNodeBase.FindNode(Address:TAddress):PNode;
Var
  TempNode : PNode;
  i:longint;
begin
  FindNode:=nil;

  For i:=0 to Nodes^.Count-1 do
    begin
      TempNode:=Nodes^.At(i);
      If ftnAddressCompare(Address,TempNode^.Address)=0 then FindNode:=TempNode;
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Function TNodeBase.GetGroups(Address:TAddress):string;
Var
  TempNode : PNode;
  i:integer;
begin
  GetGroups:='';

  TempNode:=NodeBase^.FindNode(Address);
  If TempNode=nil then exit;

  GetGroups:=TempNode^.Groups;
end;

Procedure WriteNodeFile;
Var
  sTemp : string;
  pTemp : PString;
  FileHeader:PStringsCollection;
  i:integer;
  W:word;
  T : text;
  TempNode:PNode;
begin
  TextColor(7);
  WriteLn('Saving nodes coniguration...');
  WriteLn;

  Assign(T,HomeDir+'\spctoss.nod');
  Reset(T);

  FileHeader:=New(PStringsCollection,Init($10,$10));

  While not Eof(T) do
    begin
      ReadLn(T,sTemp);
      If sTemp[1]<>';' then break;
      FileHeader^.Insert(NewStr(sTemp+#32));
    end;

  Close(T);

  dosMove(HomeDir+'\spctoss.nod',HomeDir+'\spctoss.no$');

  Rewrite(T);

  For i:=0 to FileHeader^.Count-1 do
    begin
      pTemp:=FileHeader^.At(i);
      WriteLn(T,pTemp^)
    end;

  For i:=0 to NodeBase^.Nodes^.Count-1 do
        begin
          TempNode:=NodeBase^.Nodes^.At(i);

          WriteLn(T,'BeginNode');

          WriteLn(T,'  Address ',ftnAddressToStrEx(TempNode^.Address));

          If TempNode^.SysopName<>nil then
                WriteLn(T,'  SysopName  ',TempNode^.SysopName^);

          WriteLn(T,'  UseAka ',ftnAddressToStrEx(TempNode^.UseAka));

          If Length(TempNode^.Flags)<>0 then
              WriteLn(T,'  Flags ',TempNode^.Flags);

          If TempNode^.PktPassword<>nil then
                WriteLn(T,'  PktPassword ',TempNode^.PktPassword^);

          If TempNode^.AreafixPassword<>nil then
                WriteLn(T,'  AreafixPassword ',TempNode^.AreafixPassword^);

          If TempNode^.Flavour<>flvNormal then
            Case TempNode^.Flavour of
                flvHold   : WriteLn(T,'  Flavour  Hold');
                flvCrash  : WriteLn(T,'  Flavour  Crash');
                flvDirect : WriteLn(T,'  Flavour  Direct');
            end;

          If TempNode^.PktType<>ptType2p then
            Case TempNode^.PktType of
                ptPkt2000   : WriteLn(T,'  PktType  Pkt2000');
            end;

          If TempNode^.Level<>$FF then
                WriteLn(T,'  Level ',TempNode^.Level);

          WriteLn(T,'  Archiver ',TempNode^.Archiver^);
          WriteLn(T,'  Groups ',TempNode^.Groups);
          WriteLn(T,'  MaxPktSize ',TempNode^.MaxPktSize);
          WriteLn(T,'  MaxArcSize ',TempNode^.MaxArcSize);

          W:=TempNode^.Outbound^.GetOutType;
          Case W of
              outBSO      : WriteLn(T,'  Outbound  BSO');
              outTBOX     : WriteLn(T,'  Outbound  TBOX');
              outTLBOX    : WriteLn(T,'  Outbound  TLBOX');
              outAMA      : WriteLn(T,'  Outbound  AMA');
              outDISKPOLL : WriteLn(T,'  Outbound  DISKPOLL ',TempNode^.Outbound^.OutDir^);
          end;

          WriteLn(T,'EndNode');
          WriteLn(T,'');
        end;

  Close(T);
  objDispose(FileHeader);
end;

end.
