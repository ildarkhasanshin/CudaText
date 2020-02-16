(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit proc_sidepanels;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Controls, ExtCtrls, Buttons, Forms,
  ATButtons,
  ATFlatToolbar;

type
  TAppSideId = (
    cSideLeft,
    cSideBottom
    );

type
  { TAppPanelItem }

  TAppPanelItem = class
  public
    ItemCaption: string;
    ItemControl: TCustomControl;
    ItemModule: string;
    ItemMethod: string;
    ItemOnShow: TNotifyEvent;
    procedure InitControl(const ACaption: string; AControl: TCustomControl; AParent: TWinControl);
  end;

type
  TAppPanelPythonCall = procedure(const ACallback: string) of object;

type
  { TAppPanelHost }

  TAppPanelHost = class
  private
    function GetFloating: boolean;
    function GetVisible: boolean;
    procedure SetVisible(AValue: boolean);
  public
    ParentPanel: TCustomControl;
    Toolbar: TATFlatToolbar;
    Panels: TFPList;
    Splitter: TSplitter;
    LastActivePanel: string;
    DefaultPanel: string;
    FormFloat: TForm;
    OnTabClick: TNotifyEvent;
    OnChange: TNotifyEvent;
    OnHide: TNotifyEvent;
    OnPythonCall: TAppPanelPythonCall;
    constructor Create;
    destructor Destroy; override;
    property Floating: boolean read GetFloating;
    property Visible: boolean read GetVisible write SetVisible;
    function CaptionToPanelIndex(const ACaption: string): integer;
    function CaptionToButtonIndex(const ACaption: string): integer;
    function CaptionToControlHandle(const ACaption: string): PtrInt;
    function Add(const ACaption: string; AImageIndex: integer; AHandle: PtrInt;
      AOnPanelShow: TNotifyEvent): boolean;
    function AddEmpty(const ACaption: string; AImageIndex: integer; const AModule, AMethod: string): boolean;
    function Delete(const ACaption: string): boolean;
    procedure UpdateButtons;
  end;

var
  AppPanels: array[TAppSideId] of TAppPanelHost;

implementation

{ TAppPanelItem }

procedure TAppPanelItem.InitControl(const ACaption: string; AControl: TCustomControl; AParent: TWinControl);
begin
  ItemCaption:= ACaption;
  ItemControl:= AControl;
  ItemModule:= '';
  ItemMethod:= '';

  AControl.BorderStyle:= bsNone;
  AControl.Parent:= AParent;
  AControl.Align:= alClient;
end;

{ TAppPanelHost }

constructor TAppPanelHost.Create;
begin
  inherited Create;
  Panels:= TFPList.Create;
end;

destructor TAppPanelHost.Destroy;
begin
  Panels.Clear;
  FreeAndNil(Panels);
  inherited Destroy;
end;

function TAppPanelHost.GetVisible: boolean;
begin
  if Floating then
    Result:= FormFloat.Visible
  else
    Result:= ParentPanel.Visible;
end;

procedure TAppPanelHost.SetVisible(AValue: boolean);
var
  N: integer;
  Panel: TAppPanelItem;
  Btn: TATButton;
begin
  if GetVisible=AValue then exit;

  ParentPanel.Visible:= AValue;
  if Floating then
  begin
    FormFloat.Visible:= AValue;
  end
  else
  begin
    Splitter.Visible:= AValue;
    if AValue then
      case Splitter.Align of
        alLeft:
          Splitter.Left:= ParentPanel.Width;
        alBottom:
          Splitter.Top:= ParentPanel.Top-8;
        alRight:
          Splitter.Left:= ParentPanel.Left-8;
        else
          begin end;
      end;
  end;

  if AValue then
  begin
    if LastActivePanel='' then
      LastActivePanel:= DefaultPanel;

    if LastActivePanel<>'' then
    begin
      N:= CaptionToPanelIndex(LastActivePanel);
      if N>=0 then
      begin
        Panel:= TAppPanelItem(Panels[N]);
        if Assigned(Panel.ItemOnShow) then
          Panel.ItemOnShow(nil);
      end;

      N:= CaptionToButtonIndex(LastActivePanel);
      if N>=0 then
      begin
        Btn:= Toolbar.Buttons[N];
        Btn.OnClick(Btn);
      end;

      if Assigned(OnChange) then
        OnChange(nil);
    end;
  end
  else
  if Assigned(OnHide) then
    OnHide(nil);

  UpdateButtons;
end;

function TAppPanelHost.GetFloating: boolean;
begin
  Result:= Assigned(FormFloat) and (ParentPanel.Parent=FormFloat);
end;

function TAppPanelHost.CaptionToPanelIndex(const ACaption: string): integer;
var
  i: integer;
begin
  Result:= -1;
  for i:= 0 to Panels.Count-1 do
    with TAppPanelItem(Panels[i]) do
      if ItemCaption=ACaption then
        exit(i);
end;

function TAppPanelHost.CaptionToButtonIndex(const ACaption: string): integer;
var
  i: integer;
begin
  Result:= -1;
  for i:= 0 to Toolbar.ButtonCount-1 do
    if SameText(Toolbar.Buttons[i].Caption, ACaption) then
      exit(i);
end;

function TAppPanelHost.CaptionToControlHandle(const ACaption: string): PtrInt;
var
  Num: integer;
begin
  Result:= 0;
  Num:= CaptionToPanelIndex(ACaption);
  if Num<0 then exit;

  with TAppPanelItem(Panels[Num]) do
    if Assigned(ItemControl) then
      Result:= PtrInt(ItemControl);
end;

function TAppPanelHost.Add(const ACaption: string; AImageIndex: integer;
  AHandle: PtrInt; AOnPanelShow: TNotifyEvent): boolean;
var
  Panel: TAppPanelItem;
  Num: integer;
  bExist: boolean;
begin
  Num:= CaptionToPanelIndex(ACaption);
  bExist:= Num>=0;

  if bExist then
    Panel:= TAppPanelItem(Panels[Num])
  else
  begin
    Panel:= TAppPanelItem.Create;
    Panel.ItemOnShow:= AOnPanelShow;
    Panels.Add(Panel);
  end;

  if AHandle<>0 then
    Panel.InitControl(ACaption, TCustomForm(AHandle), ParentPanel);

  if not bExist then
  begin
    Toolbar.AddButton(AImageIndex, OnTabClick, ACaption, ACaption, '', false);
    Toolbar.UpdateControls;
  end;

  Result:= true;
end;

function TAppPanelHost.AddEmpty(const ACaption: string; AImageIndex: integer;
  const AModule, AMethod: string): boolean;
var
  Panel: TAppPanelItem;
begin
  if CaptionToPanelIndex(ACaption)>=0 then exit(false);

  Panel:= TAppPanelItem.Create;
  Panel.ItemCaption:= ACaption;
  Panel.ItemControl:= nil;
  Panel.ItemModule:= AModule;
  Panel.ItemMethod:= AMethod;
  Panels.Add(Panel);

  //save module/method to Btn.DataString
  Toolbar.AddButton(AImageIndex, OnTabClick, ACaption, ACaption,
    AModule+'.'+AMethod,
    false);
  Toolbar.UpdateControls;

  Result:= true;
end;

function TAppPanelHost.Delete(const ACaption: string): boolean;
var
  Num, i: integer;
begin
  Num:= CaptionToButtonIndex(ACaption);
  Result:= Num>=0;
  if Result then
  begin
    Toolbar.Buttons[Num].Free;
    Toolbar.UpdateControls;

    //hard to remove item, so hide it by "?"
    for i:= 0 to Panels.Count-1 do
      with TAppPanelItem(Panels[i]) do
        if ItemCaption=ACaption then
        begin
          ItemCaption:= '?';
          Break;
        end;
  end;
end;

procedure TAppPanelHost.UpdateButtons;
var
  Btn: TATButton;
  bVis: boolean;
  i: integer;
begin
  bVis:= Visible;
  for i:= 0 to Toolbar.ButtonCount-1 do
  begin
    Btn:= Toolbar.Buttons[i];
    Btn.Checked:= bVis and SameText(Btn.Caption, LastActivePanel);
  end;
end;


var
  Side: TAppSideId;

initialization

  for Side in TAppSideId do
    AppPanels[Side]:= TAppPanelHost.Create;

finalization

  for Side in TAppSideId do
    FreeAndNil(AppPanels[Side]);

end.
