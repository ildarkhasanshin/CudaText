(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit TreeHelpers_Base;

{$mode ObjFPC}{$H+}
{$ModeSwitch advancedrecords}

interface

uses
  ATSynEdit_fgl;
    
type
  { TATTreeHelperRecord }

  PATTreeHelperRecord = ^TATTreeHelperRecord;
  TATTreeHelperRecord = record
    X1, Y1, X2, Y2: integer;
    Level: integer;
    Icon: integer;
    Title: string;
    class operator =(const A, B: TATTreeHelperRecord): boolean;
  end;

type
  { TATTreeHelperRecords }

  TATTreeHelperRecords = class(specialize TFPGList<TATTreeHelperRecord>)
  private
    function GetItemPtr(N: integer): PATTreeHelperRecord;
  protected
    procedure Deref(Item: Pointer); override;
  public
    property ItemPtr[N: integer]: PATTreeHelperRecord read GetItemPtr;
  end;

implementation

{ TATTreeHelperRecord }

class operator TATTreeHelperRecord.=(const A, B: TATTreeHelperRecord): boolean;
begin
  Result:= false;
end;

{ TATTreeHelperRecords }

function TATTreeHelperRecords.GetItemPtr(N: integer): PATTreeHelperRecord;
begin
  Result:= PATTreeHelperRecord(InternalGet(N));
end;

procedure TATTreeHelperRecords.Deref(Item: Pointer);
begin
  PATTreeHelperRecord(Item)^.Title:= '';
end;

end.
