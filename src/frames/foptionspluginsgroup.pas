{
   Double Commander
   -------------------------------------------------------------------------
   Options Plugins group

   Copyright (C) 2018-2019 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>.
}

unit fOptionsPluginsGroup;

{$mode objfpc}{$H+}

interface

uses
  //Lazarus, Free-Pascal, etc.
  Classes, SysUtils, StdCtrls, Buttons, EditBtn, Menus, fOptionsFrame,

  //DC
  DCStrUtils;

type
  { TfrmOptionsPluginsGroup }
  TfrmOptionsPluginsGroup = class(TOptionsEditor)
    gbConfiguration: TGroupBox;
    ckbAutoTweak: TCheckBox;
    lbPluginFilenameStyle: TLabel;
    cbPluginFilenameStyle: TComboBox;
    lbPathToBeRelativeTo: TLabel;
    dePathToBeRelativeTo: TDirectoryEdit;
    btnPathToBeRelativeToHelper: TSpeedButton;
    btnPathToBeRelativeToAll: TButton;
    pmPathToBeRelativeToHelper: TPopupMenu;
    procedure cbPluginFilenameStyleChange(Sender: TObject);
    procedure btnPathToBeRelativeToHelperClick(Sender: TObject);
    procedure btnPathToBeRelativeToAllClick(Sender: TObject);
    procedure FrameExit(Sender: TObject);
  protected
    procedure Init; override;
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    class function GetIconIndex: integer; override;
    class function GetTitle: string; override;
  end;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.
  Controls, Forms,

  //DC
  uGlobs, uDCUtils, uSpecialDir, uLng, uDefaultPlugins, fOptions,
  fOptionsPluginsDSX, fOptionsPluginsWCX, fOptionsPluginsWDX,
  fOptionsPluginsWFX, fOptionsPluginsWLX;

{ TOptionsPluginsGroup }

{ TfrmOptionsPluginsGroup.Init }
procedure TfrmOptionsPluginsGroup.Init;
begin
  ParseLineToList(rsPluginFilenameStyleList, cbPluginFilenameStyle.Items);
end;

{ TfrmOptionsPluginsGroup.Load }
procedure TfrmOptionsPluginsGroup.Load;
begin
  ckbAutoTweak.Checked := gPluginInAutoTweak;
  cbPluginFilenameStyle.ItemIndex := integer(gPluginFilenameStyle);
  cbPluginFilenameStyleChange(cbPluginFilenameStyle);
  dePathToBeRelativeTo.Text := gPluginPathToBeRelativeTo;
  gSpecialDirList.PopulateMenuWithSpecialDir(pmPathToBeRelativeToHelper, mp_PATHHELPER, nil);
end;

{ TfrmOptionsPluginsGroup.Save }
function TfrmOptionsPluginsGroup.Save: TOptionsEditorSaveFlags;
begin
  gPluginInAutoTweak := ckbAutoTweak.Checked;
  gPluginFilenameStyle := TConfigFilenameStyle(cbPluginFilenameStyle.ItemIndex);
  gPluginPathToBeRelativeTo := dePathToBeRelativeTo.Text;
  Result := [];
end;

{ TfrmOptionsPluginsGroup.GetIconIndex }
class function TfrmOptionsPluginsGroup.GetIconIndex: integer;
begin
  Result := 6;
end;

{ TfrmOptionsPluginsGroup.GetTitle }
class function TfrmOptionsPluginsGroup.GetTitle: string;
begin
  Result := rsOptionsEditorPlugins;
end;

{ TfrmOptionsPluginsGroup.cbPluginFilenameStyleChange }
procedure TfrmOptionsPluginsGroup.cbPluginFilenameStyleChange(Sender: TObject);
begin
  lbPathToBeRelativeTo.Visible := (TConfigFilenameStyle(cbPluginFilenameStyle.ItemIndex) = TConfigFilenameStyle.pfsRelativeToFollowingPath);
  dePathToBeRelativeTo.Visible := lbPathToBeRelativeTo.Visible;
  btnPathToBeRelativeToHelper.Visible := lbPathToBeRelativeTo.Visible;
end;

{ TfrmOptionsPluginsGroup.btnPathToBeRelativeToHelperClick }
procedure TfrmOptionsPluginsGroup.btnPathToBeRelativeToHelperClick(Sender: TObject);
begin
  dePathToBeRelativeTo.SetFocus;
  gSpecialDirList.SetSpecialDirRecipientAndItsType(dePathToBeRelativeTo, pfPATH);
  pmPathToBeRelativeToHelper.PopUp(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

{ TfrmOptionsPluginsGroup.btnPathToBeRelativeToAllClick }
// Let's don't apply the modification right away on "Global" plugin strutures.
// Let's load the configuration page of each and do the modifications on temporary plugin structure.
// If user is happy with what he sees, he will apply/save it.
procedure TfrmOptionsPluginsGroup.btnPathToBeRelativeToAllClick(Sender: TObject);
var
  iIndexPlugin: integer;
  Options: IOptionsDialog;
  Editor: TOptionsEditor;
begin
  Self.SaveSettings; //Call "SaveSettings" instead of just "Save" to get option signature set right away do we don't bother user for that page when close.

  Options := ShowOptions(TfrmOptionsPluginsDSX);
  Editor := Options.GetEditor(TfrmOptionsPluginsDSX);
  for iIndexPlugin := 0 to pred(tmpDSXPlugins.Count) do
    tmpDSXPlugins.GetDSXModule(iIndexPlugin).FileName := TfrmOptionsPluginsDSX(Editor).GetPluginFilenameToSave(mbExpandFileName(tmpDSXPlugins.GetDSXModule(iIndexPlugin).FileName));
  TfrmOptionsPluginsDSX(Editor).ShowPluginsTable;

  Options := ShowOptions(TfrmOptionsPluginsWCX);
  Editor := Options.GetEditor(TfrmOptionsPluginsWCX);
  for iIndexPlugin := 0 to pred(tmpWCXPlugins.Count) do
    tmpWCXPlugins.FileName[iIndexPlugin] := TfrmOptionsPluginsWCX(Editor).GetPluginFilenameToSave(mbExpandFileName(tmpWCXPlugins.FileName[iIndexPlugin]));
  TfrmOptionsPluginsWCX(Editor).ShowPluginsTable;

  Options := ShowOptions(TfrmOptionsPluginsWDX);
  Editor := Options.GetEditor(TfrmOptionsPluginsWDX);
  for iIndexPlugin := 0 to pred(tmpWDXPlugins.Count) do
    tmpWDXPlugins.GetWdxModule(iIndexPlugin).FileName := TfrmOptionsPluginsWDX(Editor).GetPluginFilenameToSave(mbExpandFileName(tmpWDXPlugins.GetWdxModule(iIndexPlugin).FileName));
  TfrmOptionsPluginsWDX(Editor).ShowPluginsTable;

  Options := ShowOptions(TfrmOptionsPluginsWFX);
  Editor := Options.GetEditor(TfrmOptionsPluginsWFX);
  for iIndexPlugin := 0 to pred(tmpWFXPlugins.Count) do
    tmpWFXPlugins.FileName[iIndexPlugin] := TfrmOptionsPluginsWFX(Editor).GetPluginFilenameToSave(mbExpandFileName(tmpWFXPlugins.FileName[iIndexPlugin]));
  TfrmOptionsPluginsWFX(Editor).ShowPluginsTable;

  Options := ShowOptions(TfrmOptionsPluginsWLX);
  Editor := Options.GetEditor(TfrmOptionsPluginsWLX);
  for iIndexPlugin := 0 to pred(tmpWLXPlugins.Count) do
    tmpWLXPlugins.GetWlxModule(iIndexPlugin).FileName := TfrmOptionsPluginsWLX(Editor).GetPluginFilenameToSave(mbExpandFileName(tmpWLXPlugins.GetWlxModule(iIndexPlugin).FileName));
  TfrmOptionsPluginsWLX(Editor).ShowPluginsTable;

  //Let's switch to plugin configuration tab with at least one configure element.
  if tmpDSXPlugins.Count > 0 then
    ShowOptions(TfrmOptionsPluginsDSX)
  else if tmpWCXPlugins.Count > 0 then
    ShowOptions(TfrmOptionsPluginsWCX)
  else if tmpWDXPlugins.Count > 1 then //For the WDX one we validate more than the default embedded one.
    ShowOptions(TfrmOptionsPluginsWDX)
  else if tmpWFXPlugins.Count > 0 then
    ShowOptions(TfrmOptionsPluginsWFX)
  else if tmpWLXPlugins.Count > 0 then
    ShowOptions(TfrmOptionsPluginsWLX);
end;

{ TfrmOptionsPluginsGroup.FrameExit }
// When focus is lost, let's save the settings here immediately.
// People will expect the settings here be effective right after changing them.
// Still in configuration, when they go in specific plugin configuration, they want to see the effects immediately.
procedure TfrmOptionsPluginsGroup.FrameExit(Sender: TObject);
begin
  Self.SaveSettings; //Call "SaveSettings" instead of just "Save" to get option signature set right away do we don't bother user for that page when close.
end;

end.

