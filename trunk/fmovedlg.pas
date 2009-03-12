unit fMoveDlg;
{$mode objfpc}{$H+}
interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type

  { TfrmMoveDlg }

  TfrmMoveDlg = class(TForm)
    btnCancel: TBitBtn;
    btnOK: TBitBtn;
    cmbFileType: TComboBox;
    edtDst: TEdit;
    lblFileType: TLabel;
    lblMoveSrc: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    panel3: TPanel;
    pnlSelector: TPanel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure frmMoveDlgKeyPress(Sender: TObject; var Key: Char);
    procedure frmMoveDlgShow(Sender: TObject);
  private
    function ShowTabsSelector: integer;
    procedure TabsSelector(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMoveDlg: TfrmMoveDlg;

implementation
uses
  uLng,fmain,framePanel,LCLType,uGlobs;

var noteb:TNotebook;
procedure TfrmMoveDlg.TabsSelector(Sender: TObject);
begin
  edtDst.Text:=TFrameFilePanel(noteb.Page[(sender as TBitBtn).tag].Components[0]).ActiveDir;
end;

function TfrmMoveDlg.ShowTabsSelector: integer;
var btnS:TBitBtn; i,tc:integer; st:TStringList; s:string;
begin
  if frmmain.SelectedPanel=fpRight
  then noteb:=frmmain.nbLeft
  else noteb:=frmmain.nbRight;

  if noteb.PageCount=1 then
    begin
      Result:=0;
      exit;
    end;
  tc:=noteb.PageCount;
  try
    st:=TStringList.Create;
    for i:=0 to tc-1 do
    if TFrameFilePanel(noteb.Page[i].Components[0]).Visible=true then
      begin
       s:=TFrameFilePanel(noteb.Page[i].Components[0]).ActiveDir;
        if st.IndexOf(s)=-1 then
          begin
            st.Add(s);
            st.Objects[st.Count-1]:=TObject(ptrint(i));
          end;

      end;

  tc:=st.Count;
  if tc>10 then tc:=10;
  for i:=0 to tc-1 do
    begin
      btnS:=TBitBtn.Create(frmMoveDlg);
      btns.Parent:=pnlSelector;
      btns.Tag:=PtrInt(st.Objects[i]);
      if i<9 then
        btns.Caption:=inttostr(i+1)+' - '+noteb.Page[PtrInt(st.Objects[i])].Caption
      else
        btns.Caption:='0 - '+noteb.Page[PtrInt(st.Objects[i])].Caption;

      btnS.OnClick:=@TabsSelector;

      btns.Width:=60;
      btns.Height:=34;
      btns.Left:=i*62;
      btns.Top:=5;
      btns.Visible:=true;
    end;
  finally
    st.Free;
  end;

end;


procedure TfrmMoveDlg.frmMoveDlgShow(Sender: TObject);
begin
  if gShowCopyTabSelectPanel then
    begin
      ShowTabsSelector;
      Panel2.SetFocus;
    end
  else
    begin
      edtDst.SelectAll;
      edtDst.SetFocus;
    end;
end;

procedure TfrmMoveDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    if gShowCopyTabSelectPanel and (edtDst.Focused=false) and (key-49<pnlSelector.ControlCount) then
    begin
      if (key>=VK_1) and (Key<=VK_9) then
         TBitBtn(pnlSelector.Controls[key-49]).Click;

      if key=vk_0 then
        TBitBtn(pnlSelector.Controls[9]).Click;
    end;
end;

procedure TfrmMoveDlg.frmMoveDlgKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#27 then
    ModalResult:=mrCancel;
  if Key=#13 then
  begin
    ModalResult:=mrOK;
    Key:=#0;
  end;
end;

initialization
 {$I fmovedlg.lrs}
end.
