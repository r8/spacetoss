{
 PktQueue Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit PQueue;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

Interface

Uses
  Nodes,

  r8objs,
  r8ftn,
  r8pkt,
  r8dos,

  dos,
  objects;

Type

  TPktQueue = object(TObject)
    Links : PNodeCollection;
    QueueDir : PPktDir;

    Constructor Init;
    Destructor Done;virtual;
    Function OpenPkt(const Node:PNode):pointer;
    Procedure SetPktData(const Node:PNode);virtual;
    Procedure ClosePkt;
  end;
  PPktQueue = ^TPktQueue;

implementation

Uses
  global;

Constructor TPktQueue.Init;
begin
  inherited Init;

  Links:=New(PNodeCollection,Init($10,$10));

  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('QQQ');
  QueueDir^.OpenDir(QueuePath);
end;

Destructor TPktQueue.Done;
begin
  Links^.ClosePackets;
  Links^.DeleteAll;
  objDispose(Links);

  objDispose(QueueDir);

  inherited Done;
end;

Procedure TPktQueue.SetPktData(const Node:PNode);
begin
  QueueDir^.Packet^.SetToAddress(Node^.Address);
  QueueDir^.Packet^.SetFromAddress(Node^.UseAka);
  If Node^.PktPassword<>nil
    then QueueDir^.Packet^.SetPassword(Node^.PktPassword^);
  QueueDir^.Packet^.SetPktAreaType(btEchomail);
  QueueDir^.Packet^.WritePkt;
end;

Function TPktQueue.OpenPkt(const Node:PNode):pointer;
begin
  OpenPkt:=nil;

  If Node^.Packet<>nil then
    begin
      If dosFileSize(Node^.Packet^.PktName^)>=
             Node^.MaxPktSize then Node^.Packet^.ClosePkt
      else
        begin
          OpenPkt:=Node^.Packet;
          exit;
        end;
    end;

  QueueDir^.PktType:=Node^.PktType;

  While true do
    begin
      QueueDir^.CreateNewPkt;

      If QueueDir^.Packet<>nil then break;
      If (DosError<>4) or (Links^.Count=0) then exit;
      ClosePkt;
    end;

  SetPktData(Node);

  Node^.Packet:=QueueDir^.Packet;
  QueueDir^.Packet:=nil;

  Links^.Insert(Node);
  OpenPkt:=Node^.Packet;
end;

Procedure TPktQueue.ClosePkt;
begin
  objDispose(PNode(Links^.At(Links^.Count-1))^.Packet);
  Links^.AtDelete(Links^.Count-1);
end;

end.
