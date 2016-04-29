unit GlobalTypes;

(*==============================================================================

  Open FlappyBird - Clone by Faris Khowarizmi
  Copyright © Khayalan Software 2014.
  Copyright © initial developer of FlappyBird - for it's graphics and sfx.

  email: thekill96@gmail.com
  website: http://www.khayalan.web.id

  This code available under GNU General Public License (GPL) version 2
  See COPYING file that shipped with this application

==============================================================================*)

interface

uses
  zgl_textures, zgl_math_2d;

type

  TTextureBurung = array[0..2] of zglPTexture;
  TListBurung = array[0..2] of TTextureBurung;

  TPipa = packed record
    CelahPipa: integer;
    PanjangPipaAtas: integer;
    PosisiHorz: integer;
    ColAtas: zglTRect;
    ColBawah: zglTRect;
    ColInside: zglTRect;
    Dilewati: boolean;
  end;

  TScoreFile = record
    Skor: LongInt;
    Checksum: Cardinal;
  end;

implementation

end.
