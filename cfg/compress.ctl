;  ==============================-
;     SpaceToss Compress File ===-
;  ==============================-
;
;  %a - archive file name
;  %f - files to extract/compress
;  %p - path to extract
;
;============================================================================


;
;=¦ Phil Katz's PKZip 2.0x ¦================================================
;
BeginArc
      Name     ZIP
      Ident    0,504b0304
;(WIN) Add      pkzip25 -add -max -nozip %a %f
;(WIN) Extract  pkzip25 -ext -over=all -nozip %a %f %p
;(DOS) Add      pkzip -a -ex %a %f
;(DOS) Extract  pkunzip -e -o %a %f %p
  Add      pkzip -a -ex %a %f
  Extract  pkunzip -e -o %a %f %p
EndArc

;
;=¦ Robert Jung's ARJ v2.30 program ¦=======================================
;
BeginArc
  Name     ARJ
  Ident    0,60EA
  Add      arj a -y %a %f
  Extract  arj e -y %a %f %p
EndArc

;
;=¦ Eugene Roshal RAR 2.0x ¦================================================
;
BeginArc
      Name     RAR
      Ident    0,526172211A
;(WIN) Add      rar32 a -y -mmf -m5 -c- -std -ep %a %f
;(WIN) Extract  rar32 x -o+ -y -c- -std -ep %a %f %p
;(DOS) Add      rar a -y -mmf -m5 -c- -std -ep %a %f
;(DOS) Extract  rar x -o+ -y -c- -std -ep %a %f %p
  Add      rar a -y -mmf -m5 -c- -std -ep %a %f
  Extract  rar x -o+ -y -c- -std -ep %a %f %p
EndArc

;
;=¦ Haruyasu Yoshizaki's LHarc 2.11 ¦=======================================
;
BeginArc
  Name     LZH
  Ident    3,6c68
  Add      lha a /m %a %f
  Extract  lha e /m %a %f %p
EndArc

;
;=¦ Harri Hirvola's HA 0.98 ¦===============================================
;
BeginArc
  Name     HA
  Ident    0,4841
  Add      ha a2e %a %f
  Extract  ha ey %a %f
EndArc

;
;=¦ JAR ¦===================================================================
;
BeginArc
  Name     JAR
  Ident    14,1a4a61721b
  Add      jar32 a -y %a %f
  Extract  jar32 e -y %a %p %f
EndArc
