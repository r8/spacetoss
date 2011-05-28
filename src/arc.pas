{
 Archive Stuff.
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit Arc;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8ftn,
  r8arc,
  r8dos,
  r8str,
  r8pkt,
  r8objs,
  r8out,

  color,
  lng,
  nodes,

  crt,
  dos,
  objects;

Type

  TArcer = object(TObject)
    QueueDir : PPktDir;

    Constructor Init;
    Destructor  Done; virtual;

    Procedure UnArcDir(const DirName:string);
    Procedure PackQueue;

    Procedure PackPacket;
  end;
  PArcer = ^TArcer;

implementation

Uses
  global;

Constructor TArcer.Init;
begin
  inherited Init;
end;

Destructor  TArcer.Done;
begin
  inherited Done;
end;

Procedure TArcer.UnArcDir(const DirName:string);
Var
  SR : SearchRec;
  sTemp : string;
begin

  FindFirst(DirName+'\*.*',AnyFile-Directory-Hidden,SR);
  While DosError=0 do
    begin
      If ftnIsArcmail(SR.Name) then
           begin
             LngFile^.AddVar(SR.Name);
             sTemp:=LngFile^.GetString(LongInt(lngProcessing));

             Writeln(sTemp);
             TextColor(colLongline);
             Writeln(constLongLine);
             TextColor(7);

             LogFile^.SendStr(sTemp,'@');

             ArcEngine^.Extract(DirName+'\'+SR.Name,'*.*');

             TextColor(colLongline);
             Writeln(constLongLine);

             TextColor(colError);
             Case ArcEngine^.Status of
                arcOk : dosErase(DirName+'\'+SR.Name);
                arcPackerError :
                  begin
                    LngFile^.AddVar(strIntToStr(ArcEngine^.ErrorLevel));
                    sTemp:=LngFile^.GetString(LongInt(lngPackerError));

                    WriteLn(sTemp);
                    LogFile^.SendStr('  '+sTemp,'!');
                  end;
                arcUnknownPacker :
                  begin
                    sTemp:=LngFile^.GetString(LongInt(lngUnknownPacker));

                    WriteLn(sTemp);
                    LogFile^.SendStr('  '+sTemp,'!');
                  end;
             end;

             If ArcEngine^.Status<>arcOk then
               begin
                 sTemp:=DirName+'\'+SR.Name;
                 Dec(sTemp[0],3);
                 sTemp:=sTemp+'BAD';
                 dosRename(DirName+'\'+SR.Name,sTemp);
               end;

             TextColor(7);
             writeln(' ');
           end;

      FindNext(SR);
    end;
{$IFNDEF VER70}
    FindClose(SR);
{$ENDIF}
end;

Procedure TArcer.PackPacket;
Var
  TempOutbound : POutbound;
  Node : PNode;

  PktToAddress : TAddress;
  PktFromAddress : TAddress;
  PktName : string;

  PktType : word;
  PktExt : string[3];

  sTemp : string;
begin
  QueueDir^.OpenPkt;

  QueueDir^.Packet^.GetToAddress(PktToAddress);
  QueueDir^.Packet^.GetFromAddress(PktFromAddress);
  PktName:=QueueDir^.GetPktName;
  QueueDir^.ClosePkt;

  PktType:=GetPktType(PktName);
  PktExt:=QueueDir^.GetExt(PktType);

  Dec(PktName[0],3);

  Node:=NodeBase^.FindNode(PktToAddress);
  If Node=nil then exit;

  LngFile^.AddVar(dosGetFileName(PktName)+PktExt);
  LngFile^.AddVar(ftnAddressToStrEx(PktToAddress));

  sTemp:=LngFile^.GetString(LongInt(lngPackingFor));

  WriteLn(sTemp);
  LogFile^.SendStr(sTemp,'@');

  TempOutbound:=nil;
  If TosserOutbounds^.GetBusy(PktToAddress) then
    begin
      sTemp:=LngFile^.GetString(LongInt(lngLinkIsBusy));

      WriteLn(sTemp);
      LogFile^.SendStr('  '+sTemp,'!');

      If (TosserOutbounds^.Busy<>nil) and (Node^.CheckFlag('B')) then
        begin
          TempOutbound:=Node^.Outbound;
          Node^.Outbound:=TosserOutbounds^.Busy;

          sTemp:=LngFile^.GetString(LongInt(lngPackingToBusyOutbound));

          WriteLn(sTemp);
          LogFile^.SendStr('  '+sTemp,'!');
        end
      else exit;
    end;

  TextColor(colLongline);
  Writeln(constLongLine);
  TextColor(7);

  If TempOutbound=nil then TosserOutbounds^.SetBusy(PktToAddress);

  dosCopy(PktName+'QQQ',PktName+PktExt);

  If Node^.Archiver^='NONE' then
    begin
      Node^.Outbound^.Attach(PktName+PktExt,PktFromAddress,PktToAddress,Node^.Flavour);
      TextColor(colLongline);
      Writeln(constLongLine);
      TextColor(7);
      dosErase(PktName+'QQQ');
    end
    else
    begin
      Node^.Outbound^.AddToBundle(PktName+PktExt,PktFromAddress,PktToAddress,Node^.Archiver^,
            Node^.Flavour,Node^.MaxArcSize);

      TextColor(colLongline);
      Writeln(constLongLine);
      TextColor(7);

      Case ArcEngine^.Status of
        arcOk : dosErase(PktName+'QQQ');
        arcPackerError :
          begin
            LngFile^.AddVar(strIntToStr(ArcEngine^.ErrorLevel));
            sTemp:=LngFile^.GetString(LongInt(lngPackerError));

            WriteLn(sTemp);
            LogFile^.SendStr('  '+sTemp,'!');
          end;
        arcUnknownPacker :
          begin
            sTemp:=LngFile^.GetString(LongInt(lngUnknownPacker));

            WriteLn(sTemp);
            LogFile^.SendStr('  '+sTemp,'!');
          end;
      end;
    end;

  dosErase(PktName+PktExt);

  If TempOutbound=nil then TosserOutbounds^.RemoveBusy(PktToAddress);
  If TempOutbound<>nil then Node^.Outbound:=TempOutbound;

  WriteLn;
end;

Procedure TArcer.PackQueue;
Var
  i : longint;
begin
  QueueDir:=New(PPktDir,Init);
  QueueDir^.SetPktExtension('QQQ');
  QueueDir^.OpenDir(QueuePath);

  TosserOutbounds^.OpenOutbounds;

  For i:=0 to QueueDir^.GetCount-1 do
    begin
      QueueDir^.Seek(i);
      PackPacket;
    end;

  QueueDir^.CloseDir;
  objDispose(QueueDir);

  TosserOutbounds^.CloseOutbounds;
end;

end.