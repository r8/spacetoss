{
 Outbounds Stuff for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit outbnds;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8out,
  r8objs,

  ama,
  r8bso,
  r8tbox,
  r8tlbox,
  r8dsk,
  r8ftn,

  objects;

Type

  TTosserOutbound = record
    Name : PString;
    Path : PString;
    Outbound : POutbound;
  end;
  PTosserOutbound = ^TTosserOutbound;

  TTosserOutboundsCollection = object(TSortedCollection)
    Procedure FreeItem(Item:pointer);virtual;
{$IFDEF VER70}
    Function Compare(Key1, Key2: Pointer):Integer;virtual;
{$ELSE}
    Function Compare(Key1, Key2: Pointer):LongInt;virtual;
{$ENDIF}
  end;
  PTosserOutboundsCollection = ^TTosserOutboundsCollection;

  TTosserOutboundsBase = object(TObject)
    Default : POutbound;
    Busy : POutbound;
    Outbounds : PTosserOutboundsCollection;

    Constructor Init;
    Destructor Done;virtual;

    Procedure OpenOutbounds;
    Procedure CloseOutbounds;

    Function FindOutbound(const S:string):pointer;
    Procedure AddOutbound(const AName:string;const OutType:word;const APath:string);

    Procedure SetBusy(Address:TAddress);virtual;
    Procedure RemoveBusy(Address:TAddress);virtual;
    Function GetBusy(Address:TAddress):boolean;virtual;
  end;
  PTosserOutboundsBase = ^TTosserOutboundsBase;

implementation

Uses
  global;

Constructor TTosserOutboundsBase.Init;
begin
  inherited Init;

  Default:=nil;
  Busy:=nil;
  Outbounds:=New(PTosserOutboundsCollection,Init($10,$10));
end;

Destructor TTosserOutboundsBase.Done;
begin
  objDispose(Outbounds);

  inherited Done;
end;

Procedure TTosserOutboundsBase.OpenOutbounds;
  Procedure ProcessOutbound(P:pointer);far;
  Var
    TempOutbound : PTosserOutbound absolute P;
  begin
    TempOutbound^.Outbound^.OpenDir(TempOutbound^.Path^);
  end;
begin
  Outbounds^.ForEach(@ProcessOutbound);
end;

Procedure TTosserOutboundsBase.CloseOutbounds;
begin
  Outbounds^.FreeAll;
end;

Function TTosserOutboundsBase.FindOutbound(const S:string):pointer;
Var
  TempOutbound : PTosserOutbound;
{$IFDEF VER70}
  i:integer;
{$ELSE}
  i:longint;
{$ENDIF}
begin
  FindOutbound:=nil;

  TempOutbound:=New(PTosserOutbound);
  TempOutbound^.Name:=NewStr(S);

  If Outbounds^.Search(TempOutbound,i)
    then FindOutbound:=PTosserOutbound(Outbounds^.At(i))^.Outbound;

  DisposeStr(TempOutbound^.Name);
  Dispose(TempOutbound);
end;

Procedure TTosserOutboundsBase.AddOutbound(const AName:string;const OutType:word;const APath:string);
Var
  TempOutbound : PTosserOutbound;
begin
  TempOutbound:=New(PTosserOutbound);
  TempOutbound^.Name:=NewStr(AName);
  TempOutbound^.Path:=NewStr(APath);

  Case OutType of
    outAMA :
      begin
        TempOutbound^.Outbound:=New(PSpcAMA,Init);
        PSpcAMA(TempOutbound^.Outbound)^.QueuePath:=NewStr(QueuePath);
      end;
    outBSO : TempOutbound^.Outbound:=New(PBSO,Init);
    outTBOX : TempOutbound^.Outbound:=New(PTBOX,Init);
    outTLBOX : TempOutbound^.Outbound:=New(PTLBOX,Init);
    outDiskPoll : TempOutbound^.Outbound:=New(PDiskPoll,Init);
  end;

  TempOutbound^.Outbound^.ArcEngine:=ArcEngine;
  TempOutbound^.Outbound^.SetDefZone(AddressBase^.MainAddress^.Zone);

  Outbounds^.Insert(TempOutbound);
end;

Procedure TTosserOutboundsBase.SetBusy(Address:TAddress);
  Procedure ProcessOutbound(P:pointer);far;
  Var
    TempOutbound : PTosserOutbound absolute P;
  begin
    TempOutbound^.Outbound^.SetBusy(Address);
  end;
begin
  Outbounds^.ForEach(@ProcessOutbound);
end;

Procedure TTosserOutboundsBase.RemoveBusy(Address:TAddress);
  Procedure ProcessOutbound(P:pointer);far;
  Var
    TempOutbound : PTosserOutbound absolute P;
  begin
    TempOutbound^.Outbound^.RemoveBusy(Address);
  end;
begin
  Outbounds^.ForEach(@ProcessOutbound);
end;

Function TTosserOutboundsBase.GetBusy(Address:TAddress):boolean;
  Function ProcessOutbound(P:pointer):boolean;far;
  Var
    TempOutbound : PTosserOutbound absolute P;
  begin
    ProcessOutbound:=TempOutbound^.Outbound^.GetBusy(Address);
  end;
begin
  GetBusy:=false;
  If Outbounds^.FirstThat(@ProcessOutbound)<>nil then GetBusy:=true;
end;

Procedure TTosserOutboundsCollection.FreeItem(Item:pointer);
begin
  DisposeStr(PTosserOutbound(Item)^.Name);
  DisposeStr(PTosserOutbound(Item)^.Path);
  objDispose(PTosserOutbound(Item)^.Outbound);

  If Item<>nil then Dispose(PTosserOutbound(Item));
end;

{$IFDEF VER70}
Function TTosserOutboundsCollection.Compare(Key1, Key2: Pointer):Integer;
{$ELSE}
Function TTosserOutboundsCollection.Compare(Key1, Key2: Pointer):LongInt;
{$ENDIF}
Var
  S1,S2:String;
begin
  S1:=PTosserOutbound(Key1)^.Name^;
  S2:=PTosserOutbound(Key2)^.Name^;

  If S1>S2 then Compare:=1 else
  If S1<S2 then Compare:=-1 else
  Compare:=0;
end;

end.