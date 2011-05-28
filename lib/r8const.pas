{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
{$IfDef MsDos} {$Define DOS} {$EndIf}
{$IfDef Dpmi}  {$Define DOS} {$EndIf}
Unit r8Const;

interface

const

{$IFDEF MSDOS}
  cstrOsId = 'DOS';
{$ENDIF}
{$IFDEF DPMI}
{$IFDEF FPC}
  cstrOsId = '386';
{$ELSE}
  cstrOsId = 'DPMI';
{$ENDIF}
{$ENDIF}
{$IFDEF WIN32}
  cstrOsId = 'WIN32';
{$ENDIF}
{$IFDEF OS2}
  cstrOsId = 'OS2';
{$ENDIF}
{$IFDEF LINUX}
  cstrOsId = 'LINUX';
{$ENDIF}
{$IFDEF DPMI32}
  cstrOsId = 'DPMI32';
{$ENDIF}

implementation

end.