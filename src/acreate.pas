{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit ACreate;

interface

Uses
  lng,
  elist,

  r8ftn,
  r8str,
  r8objs,
  r8alst,
  areas,
  nodes,
  uplinks,
  announce,
  objects,
  forwards,
  groups;

Function AutocreateArea(AreaName:string;GroupName:char;UpLink:PUplink):pointer;
Procedure AnnounceAreas;
Function GetFirstFreeBoard:longint;

implementation

Uses
  r8elst,
  r8sqlst,
  r8felst,
  r8bcl,
  r8xofl,

  global;

Function GetFirstFreeBoard:longint;
Var
  iTemp : integer;
begin
  For iTemp:=1 to 200 do
    begin
{      If HudsonIndex^.FindBoard(iTemp)=nil then break;}
    end;
  GetFirstFreeBoard:=iTemp;
end;

Function AutocreateArea(AreaName:string;GroupName:char;UpLink:PUplink):pointer;
Var
  TempArea : PArea;
  TempGroup : PGroup;
  TempLink : PNodelistItem;
  i:integer;
  sTemp : string;
  AnnounceTask : PAnnounceTask;
  ForwardItem : PForwardItem;
begin
  AutocreateArea:=nil;

  TempGroup:=Pointer(GroupBase^.FindArea(GroupName));

{  If (TempGroup^.EchoType.Storage=etHudson)
    and (HudsonIndex^.Index^.Count>=200) then exit;}

  TempArea:=New(PArea,Init(AreaName));
  TempArea^.BaseType:=btEchomail;
  AreaBase^.AddArea(TempArea);
  TempGroup^.ItemBase^.AddArea(TempArea);

  AssignStr(TempArea^.Desc,TempGroup^.EchoDesc);
  TempArea^.Group:=GroupName;

  sTemp:='';

  If Uplink^.AutoDesc.ListType<>ltNone then
    begin
      If Uplink^.AutoDesc.List=nil then ReadEcholist(Uplink^.AreaList,ftnAddressToStrEx(Uplink^.Address));
      If Uplink^.AutoDesc.List<>nil then
         sTemp:=Uplink^.AutoDesc.List^.GetDesc(TempArea^.Name^)
    end
  else
  If DefEcholist.ListType<>ltNone then
     begin
      If DefEcholist.List=nil then ReadEcholist(DefEcholist,'AUTODESC');
      If DefEcholist.List<>nil then
        sTemp:=DefEcholist.List^.GetDesc(TempArea^.Name^);
   end;

  If sTemp<>'' then  AssignStr(TempArea^.Desc,sTemp);

  If not ftnIsAddressInvalidated(TempGroup^.UseAka)
    then TempArea^.UseAka:=TempGroup^.UseAka;

  TempArea^.WriteLevel:=TempGroup^.WriteLevel;
  TempArea^.ReadLevel:=TempGroup^.ReadLevel;

  TempArea^.PurgeDays:=TempGroup^.PurgeDays;
  TempArea^.PurgeMsgs:=TempGroup^.PurgeMsgs;

  TempArea^.EchoType:=TempGroup^.Echotype;
  TempArea^.Flags:=TempGroup^.Flags;

  If TempArea^.Echotype.Storage<>etPassThrough then
    begin

      If TempArea^.Echotype.Storage=etHudson then
        begin
{          i:=GetFirstFreeBoard;
          sTemp:=strIntToStr(i);
          sTemp:=strPadL(sTemp,'0',3);
          TempArea^.EchoType.Path:='hud'+sTemp;
          HudsonIndex^.AddBoard(i,TempArea); }
        end
        else
        begin
          If LongAutoCreate then
            begin
              sTemp:=TempArea^.Name^
            end
            else
            begin
              sTemp:=ftnPktName;
              sTemp:='SPC'+Copy(sTemp,4,5);
            end;

          TempArea^.EchoType.Path:=strLower(TempArea^.EchoType.Path+'\'+sTemp);
        end;
    end;

  For i:=0 to TempGroup^.Links^.Count-1 do
    begin
      TempLink:=TempGroup^.Links^.At(i);
      TempArea^.AddLink(PNode(TempLink^.Node)^.Address,TempLink^.Mode);
    end;

  TempArea^.AddLink(Uplink^.Address,modRead or modWrite);

  AreaBase^.Modified:=True;

  AnnounceTask:=New(PAnnounceTask,Init);
  AnnounceTask^.Address:=Uplink^.Address;
  AnnounceTask^.UplinkAddress:=Uplink^.Address;
  AnnounceTask^.AreaName:=NewStr(TempArea^.Name^);
  If TempArea^.Desc<>nil then AnnounceTask^.AreaDesc:=NewStr(TempArea^.Desc^);
  AnnounceTask^.GroupName:=NewStr(TempGroup^.Name^);
  AnnounceTask^.GroupDesc:=NewStr(TempGroup^.Desc^);

  ForwardItem:=Areafix^.ForwardFile^.FindItem(AreaName);
  While ForwardItem<>nil do
    begin
      AnnounceTask^.Address:=ForwardItem^.Address;
      TempArea^.AddLink(ForwardItem^.Address,modRead or modWrite);
      Areafix^.ForwardFile^.ForwardCollection^.Free(ForwardItem);
      ForwardItem:=Areafix^.ForwardFile^.FindItem(AreaName);
    end;

  AnnouncesStack^.Insert(AnnounceTask);
  AutocreateArea:=TempArea;
end;

Procedure AnnounceAreas;
var
  TempAnnounce : PAnnounce;
  i:integer;
begin
  If AnnouncesStack^.Count=0 then exit;

  For i:=0 to Announces^.Count-1 do
    begin
      TempAnnounce:=Announces^.At(i);
      TempAnnounce^.Post(AnnouncesStack);
    end;

  AnnouncesStack^.FreeAll;
end;

end.
