{
   Double Commander
   -------------------------------------------------------------------------
   WDX-API implementation.
   (TC WDX-API v1.5)

   Copyright (C) 2008  Dmitry Kolomiets (B4rr4cuda@rambler.ru)
   Copyright (C) 2008-2017 Alexander Koblov (alexx2000@mail.ru)

   Some ideas were found in sources of WdxGuide by Alexey Torgashin
   and SuperWDX by Pavel Dubrovsky and Dmitry Vorotilin.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

}


unit uWDXModule;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, DCClassesUtf8,
  uWdxPrototypes, WdxPlugin,
  dynlibs, uDetectStr, lua, uFile, DCXmlConfig;

const
  WDX_MAX_LEN = 2048;

type

  { TWdxField }

  TWdxField = class
    FName:  String;
    FUnits: String;
    FType:  Integer;
    function GetUnitIndex(UnitName: String): Integer;
  end;

  { TWDXModule }

  TWDXModule = class
  protected
    FMutex: TRTLCriticalSection;
  protected
    function GetAName: String; virtual; abstract;
    function GetAFileName: String; virtual; abstract;
    function GetADetectStr: String; virtual; abstract;
    procedure SetAName(AValue: String); virtual; abstract;
    procedure SetAFileName(AValue: String); virtual; abstract;
    procedure SetADetectStr(const AValue: String); virtual; abstract;
  public
    //---------------------
    constructor Create; virtual;
    destructor Destroy; override;
    //---------------------
    function LoadModule: Boolean; virtual; abstract;
    procedure UnloadModule; virtual; abstract;
    function IsLoaded: Boolean; virtual; abstract;
    //---------------------
    function FieldList: TStringList; virtual; abstract;
    function WdxFieldType(n: Integer): String;
    function GetFieldIndex(FieldName: String): Integer; virtual; abstract;
    function FileParamVSDetectStr(const aFile: TFile): Boolean; virtual; abstract;
    //------------------------------------------------------
    procedure CallContentGetSupportedField; virtual; abstract;
    procedure CallContentSetDefaultParams; virtual; abstract;
    procedure CallContentStopGetValue(FileName: String); virtual; abstract;
    //---------------------
    function CallContentGetDefaultSortOrder(FieldIndex: Integer): Boolean; virtual; abstract;
    function CallContentGetDetectString: String; virtual; abstract;
    function CallContentGetValueV(FileName: String; FieldName: String; UnitName: String; flags: Integer): Variant; overload; virtual;
    function CallContentGetValueV(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): Variant; overload; virtual; abstract;
    function CallContentGetValue(FileName: String; FieldName: String; UnitName: String; flags: Integer): String; overload; virtual;
    function CallContentGetValue(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): String; overload; virtual; abstract;
    function CallContentGetValue(FileName: String; FieldIndex: Integer; var UnitIndex: Integer): String; overload; virtual; abstract;
    function CallContentGetSupportedFieldFlags(FieldIndex: Integer): Integer; virtual; abstract;
        {ContentSetValue
         ContentEditValue
         ContentSendStateInformation}
    //------------------------------------------------------
    property Name: String read GetAName write SetAName;
    property FileName: String read GetAFileName write SetAFileName;
    property DetectStr: String read GetADetectStr write SetADetectStr;
    //---------------------
  end;


  { TPluginWDX }

  TPluginWDX = class(TWDXModule)
  private
    FFieldsList: TStringList;
    FModuleHandle: TLibHandle;  // Handle to .DLL or .so
    FForce:     Boolean;
    FParser:    TParserControl;
    FName:      String;
    FFileName:  String;
    FDetectStr: String;

    function GetAName: String; override;
    function GetAFileName: String; override;
    function GetADetectStr: String; override;

    procedure SetAName(AValue: String); override;
    procedure SetAFileName(AValue: String); override;
    procedure SetADetectStr(const AValue: String); override;
  protected
    //a) Mandatory (must be implemented)
    ContentGetSupportedField: TContentGetSupportedField;
    ContentGetValue:      TContentGetValue;
    //b) Optional (must NOT be implemented if unsupported!)
    ContentGetDetectString: TContentGetDetectString;
    ContentSetDefaultParams: TContentSetDefaultParams;
    ContentStopGetValue:  TContentStopGetValue;
    ContentGetDefaultSortOrder: TContentGetDefaultSortOrder;
    ContentPluginUnloading: TContentPluginUnloading;
    ContentGetSupportedFieldFlags: TContentGetSupportedFieldFlags;
    ContentSetValue:      TContentSetValue;
    ContentEditValue:     TContentEditValue;
    ContentSendStateInformation: TContentSendStateInformation;
    //c) Unicode
    ContentGetValueW:     TContentGetValueW;
    ContentStopGetValueW: TContentStopGetValueW;
    ContentSetValueW:     TContentSetValueW;
    ContentSendStateInformationW: TContentSendStateInformationW;
  public
    //---------------------
    constructor Create; override;
    destructor Destroy; override;
    //---------------------
    function LoadModule: Boolean; override;
    procedure UnloadModule; override;
    function IsLoaded: Boolean; override;
    //---------------------
    function FieldList: TStringList; override;
    function GetFieldIndex(FieldName: String): Integer; override;
    function FileParamVSDetectStr(const aFile: TFile): Boolean; override;
    //------------------------------------------------------
    procedure CallContentGetSupportedField; override;
    procedure CallContentSetDefaultParams; override;
    procedure CallContentStopGetValue(FileName: String); override;
    //---------------------
    function CallContentGetDefaultSortOrder(FieldIndex: Integer): Boolean; override;
    function CallContentGetDetectString: String; override;
    function CallContentGetValueV(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): Variant; overload; override;
    function CallContentGetValue(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): String; overload; override;
    function CallContentGetValue(FileName: String; FieldIndex: Integer; var UnitIndex: Integer): String; overload; override;
    function CallContentGetSupportedFieldFlags(FieldIndex: Integer): Integer; override;
        {ContentSetValue
         ContentEditValue
         ContentSendStateInformation}
    //------------------------------------------------------
    property ModuleHandle: TLibHandle read FModuleHandle write FModuleHandle;
    property Force: Boolean read FForce write FForce;
    property Name: String read GetAName write SetAName;
    property FileName: String read GetAFileName write SetAFileName;
    property DetectStr: String read GetADetectStr write SetADetectStr;

    //---------------------
  end;

  { TLuaWdx }

  TLuaWdx = class(TWdxModule)
  private
    L:      Plua_State;
    FFieldsList: TStringList;
    FForce: Boolean;
    FParser: TParserControl;
    FName:  String;
    FFileName: String;
    FDetectStr: String;

    function GetAName: String; override;
    function GetAFileName: String; override;
    function GetADetectStr: String; override;

    procedure SetAName(AValue: String); override;
    procedure SetAFileName(AValue: String); override;
    procedure SetADetectStr(const AValue: String); override;

    function DoScript(AName: String): Integer;
    function WdxLuaContentGetSupportedField(Index: Integer; var xFieldName, xUnits: String): Integer;
    procedure WdxLuaContentPluginUnloading;
  public
    constructor Create; override;
    destructor Destroy; override;
    //---------------------
    function LoadModule: Boolean; override;
    procedure UnloadModule; override;
    function IsLoaded: Boolean; override;
    //---------------------
    function FieldList: TStringList; override;
    function GetFieldIndex(FieldName: String): Integer; override;
    function FileParamVSDetectStr(const aFile: TFile): Boolean; override;
    //------------------------------------------------------
    procedure CallContentGetSupportedField; override;
    procedure CallContentSetDefaultParams; override;
    procedure CallContentStopGetValue(FileName: String); override;
    //---------------------
    function CallContentGetDefaultSortOrder(FieldIndex: Integer): Boolean; override;
    function CallContentGetDetectString: String; override;
    function CallContentGetValueV(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): Variant; overload; override;
    function CallContentGetValue(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): String; overload; override;
    function CallContentGetValue(FileName: String; FieldIndex: Integer; var UnitIndex: Integer): String; overload; override;
    function CallContentGetSupportedFieldFlags(FieldIndex: Integer): Integer; override;
    //---------------------
    property Force: Boolean read FForce write FForce;
    property Name: String read GetAName write SetAName;
    property FileName: String read GetAFileName write SetAFileName;
    property DetectStr: String read GetADetectStr write SetADetectStr;


  end;

  { TEmbeddedWDX }

  TEmbeddedWDX = class(TWDXModule)
  private
    FFieldsList: TStringList;
    FParser:     TParserControl;
  protected
    function GetAName: String; override;
    function GetAFileName: String; override;
    function GetADetectStr: String; override;
    procedure SetAName(AValue: String); override;
    procedure SetAFileName(AValue: String); override;
    procedure SetADetectStr(const AValue: String); override;
  protected
    procedure AddField(const AName: String; AType: Integer);
  public
    //---------------------
    constructor Create; override;
    destructor Destroy; override;
    //---------------------
    function LoadModule: Boolean; override;
    procedure UnloadModule; override;
    function IsLoaded: Boolean; override;
    //---------------------
    function FieldList: TStringList; override;
    function GetFieldIndex(FieldName: String): Integer; override;
    function FileParamVSDetectStr(const aFile: TFile): Boolean; override;
    //------------------------------------------------------
  end;

  { TWDXModuleList }

  TWDXModuleList = class
  private
    Flist: TStringList;
    function GetCount: Integer;
  public
    //---------------------
    constructor Create;
    destructor Destroy; override;
    //---------------------
    procedure Assign(Source: TWDXModuleList);
    function IndexOfName(const AName: String): Integer;
    //---------------------
    procedure Clear;
    procedure Exchange(Index1, Index2: Integer);
    procedure Load(AConfig: TXmlConfig; ANode: TXmlNode); overload;
    procedure Save(AConfig: TXmlConfig; ANode: TXmlNode); overload;
    procedure DeleteItem(Index: Integer);
    //---------------------
    function Add(Item: TWDXModule): Integer; overload;
    function Add(FileName: String): Integer; overload;
    function Add(AName, FileName, DetectStr: String): Integer; overload;

    function IsLoaded(AName: String): Boolean; overload;
    function IsLoaded(Index: Integer): Boolean; overload;
    function LoadModule(AName: String): Boolean; overload;
    function LoadModule(Index: Integer): Boolean; overload;

    function GetWdxModule(Index: Integer): TWDXModule; overload;
    function GetWdxModule(AName: String): TWDXModule; overload;
    //---------------------
    //property WdxList:TStringList read Flist;
    property Count: Integer read GetCount;
  end;

  function StrToVar(const Value: String; FieldType: Integer): Variant;

implementation

uses
  StrUtils, LazUTF8, uGlobs, uGlobsPaths, FileUtil, uDebug, uDCUtils, uOSUtils,
  DCBasicTypes, DCOSUtils, DCDateTimeUtils, DCConvertEncoding, uLuaPas;

const
  WdxIniFileName = 'wdx.ini';

function StrToVar(const Value: String; FieldType: Integer): Variant;
begin
  case FieldType of
  ft_fieldempty: Result := Unassigned;
  ft_numeric_32: Result := StrToInt(Value);
  ft_numeric_64: Result := StrToInt64(Value);
  ft_numeric_floating: Result := StrToFloat(Value);
  ft_date: Result := StrToDate(Value);
  ft_time: Result := StrToTime(Value);
  ft_datetime: Result := StrToDateTime(Value);
  ft_boolean: Result := StrToBool(Value);

  ft_multiplechoice,
  ft_string,
  ft_fulltext,
  ft_stringw: Result := Value;
  else
    Result := Unassigned;
  end;
end;

{ TWDXModuleList }

function TWDXModuleList.GetCount: Integer;
begin
  if Assigned(Flist) then
    Result := Flist.Count
  else
    Result := 0;
end;

constructor TWDXModuleList.Create;
begin
  Flist := TStringList.Create;
end;

destructor TWDXModuleList.Destroy;
begin
  Clear;
  FreeAndNil(Flist);

  inherited Destroy;
end;

procedure TWDXModuleList.Assign(Source: TWDXModuleList);
var
  I: Integer;
begin
  if Assigned(Source) then
  begin
    Clear;
    for I := 0 to Source.Flist.Count - 1 do
    begin
      with TWdxModule(Source.Flist.Objects[I]) do
      Add(Name, FileName, DetectStr);
    end;
  end;
end;

function TWDXModuleList.IndexOfName(const AName: String): Integer;
begin
  Result := Flist.IndexOf(UpCase(AName));
end;

procedure TWDXModuleList.Clear;
var
  i: Integer;
begin
  for i := 0 to Flist.Count - 1 do
    TWDXModule(Flist.Objects[i]).Free;
  Flist.Clear;
end;

procedure TWDXModuleList.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
end;

procedure TWDXModuleList.Load(AConfig: TXmlConfig; ANode: TXmlNode);
var
  AName, APath: String;
  AWdxModule: TWDXModule;
begin
  Self.Clear;

  ANode := ANode.FindNode('WdxPlugins');
  if Assigned(ANode) then
  begin
    ANode := ANode.FirstChild;
    while Assigned(ANode) do
    begin
      if ANode.CompareName('WdxPlugin') = 0 then
      begin
        if AConfig.TryGetValue(ANode, 'Name', AName) and
           AConfig.TryGetValue(ANode, 'Path', APath) then
        begin
          // Create a correct object based on plugin file extension.
          APath := GetCmdDirFromEnvVar(APath);
          DCDebug('WDX: LOAD: ' + APath);

          if UpCase(ExtractFileExt(APath)) = '.LUA' then
            AWdxModule := TLuaWdx.Create
          else
            AWdxModule := TPluginWDX.Create;

          AWdxModule.Name := AName;
          AWdxModule.FileName := APath;
          AWdxModule.DetectStr := AConfig.GetValue(ANode, 'DetectString', '');
          Flist.AddObject(UpCase(AName), AWdxModule);
        end
        else
          DCDebug('Invalid entry in configuration: ' + AConfig.GetPathFromNode(ANode) + '.');
      end;
      ANode := ANode.NextSibling;
    end;
  end;
end;

procedure TWDXModuleList.Save(AConfig: TXmlConfig; ANode: TXmlNode);
var
  i: Integer;
  SubNode: TXmlNode;
begin
  ANode := AConfig.FindNode(ANode, 'WdxPlugins', True);
  AConfig.ClearNode(ANode);

  For i := 0 to Flist.Count - 1 do
  begin
    if not (Flist.Objects[I] is TEmbeddedWDX) then
    begin
      SubNode := AConfig.AddNode(ANode, 'WdxPlugin');
      AConfig.AddValue(SubNode, 'Name', TWDXModule(Flist.Objects[I]).Name);
      AConfig.AddValue(SubNode, 'Path', SetCmdDirAsEnvVar(TWDXModule(Flist.Objects[I]).FileName));
      AConfig.AddValue(SubNode, 'DetectString', TWDXModule(Flist.Objects[I]).DetectStr);
    end;
  end;
end;

procedure TWDXModuleList.DeleteItem(Index: Integer);
begin
  if (Index > -1) and (Index < Flist.Count) then
  begin
    TWDXModule(Flist.Objects[Index]).Free;
    Flist.Delete(Index);
  end;
end;

function TWDXModuleList.Add(Item: TWDXModule): Integer;
begin
  Result := Flist.AddObject(UpCase(item.Name), Item);
end;

function TWDXModuleList.Add(FileName: String): Integer;
var
  s: String;
begin
  s := ExtractFileName(FileName);
  if pos('.', s) > 0 then
    Delete(s, pos('.', s), length(s));

  if UpCase(ExtractFileExt(FileName)) = '.LUA' then
    Result := Flist.AddObject(UpCase(s), TLuaWdx.Create)
  else
    Result := Flist.AddObject(UpCase(s), TPluginWDX.Create);

  TWDXModule(Flist.Objects[Result]).Name := s;
  TWDXModule(Flist.Objects[Result]).FileName := FileName;
  if TWDXModule(Flist.Objects[Result]).LoadModule then
  begin
    TWDXModule(Flist.Objects[Result]).DetectStr := TWDXModule(Flist.Objects[Result]).CallContentGetDetectString;
    TWDXModule(Flist.Objects[Result]).UnloadModule;
  end;
end;

function TWDXModuleList.Add(AName, FileName, DetectStr: String): Integer;
begin
  if UpCase(ExtractFileExt(FileName)) = '.LUA' then
    Result := Flist.AddObject(UpCase(AName), TLuaWdx.Create)
  else
    Result := Flist.AddObject(UpCase(AName), TPluginWDX.Create);

  TWDXModule(Flist.Objects[Result]).Name := AName;
  TWDXModule(Flist.Objects[Result]).DetectStr := DetectStr;
  TWDXModule(Flist.Objects[Result]).FileName := FileName;
end;

function TWDXModuleList.IsLoaded(AName: String): Boolean;
var
  x: Integer;
begin
  x := Flist.IndexOf(AName);
  if x = -1 then
    Result := False
  else
  begin
    Result := GetWdxModule(x).IsLoaded;
  end;
end;

function TWDXModuleList.IsLoaded(Index: Integer): Boolean;
begin
  Result := GetWdxModule(Index).IsLoaded;
end;

function TWDXModuleList.LoadModule(AName: String): Boolean;
var
  x: Integer;
begin
  x := Flist.IndexOf(UpCase(AName));
  if x = -1 then
    Result := False
  else
  begin
    Result := GetWdxModule(x).LoadModule;
  end;
end;

function TWDXModuleList.LoadModule(Index: Integer): Boolean;
begin
  Result := GetWdxModule(Index).LoadModule;
end;

function TWDXModuleList.GetWdxModule(Index: Integer): TWDXModule;
begin
  Result := TWDXModule(Flist.Objects[Index]);
end;

function TWDXModuleList.GetWdxModule(AName: String): TWDXModule;
var
  tmp: Integer;
begin
  tmp := Flist.IndexOf(upcase(AName));
  if tmp < 0 then Exit(nil);
  Result := TWDXModule(Flist.Objects[tmp])
end;

{ TPluginWDX }

function TPluginWDX.IsLoaded: Boolean;
begin
  Result := FModuleHandle <> 0;
end;

function TPluginWDX.FieldList: TStringList;
begin
  Result := FFieldsList;
end;

function TPluginWDX.GetADetectStr: String;
begin
  Result := FDetectStr;
end;

function TPluginWDX.GetAName: String;
begin
  Result := FName;
end;

function TPluginWDX.GetAFileName: String;
begin
  Result := FFileName;
end;

procedure TPluginWDX.SetADetectStr(const AValue: String);
begin
  FDetectStr := AValue;
end;

procedure TPluginWDX.SetAName(AValue: String);
begin
  FName := AValue;
end;

procedure TPluginWDX.SetAFileName(AValue: String);
begin
  FFileName := AValue;
end;

constructor TPluginWDX.Create;
begin
  inherited Create;
  FFieldsList := TStringList.Create;
  FParser := TParserControl.Create;
end;

destructor TPluginWDX.Destroy;
var
  i: Integer;
begin
  if assigned(FParser) then
    FParser.Free;

  if assigned(FFieldsList) then
  begin
    for i := 0 to FFieldsList.Count - 1 do
      TWdxField(FFieldsList.Objects[i]).Free;
    FFieldsList.Free;
  end;

  Self.UnloadModule;
  inherited Destroy;
end;

function TPluginWDX.LoadModule: Boolean;
begin
  FModuleHandle := mbLoadLibrary(Self.FileName);
  Result := (FModuleHandle <> 0);
  if FModuleHandle = 0 then
    exit;
  { Mandatory }
  ContentGetSupportedField := TContentGetSupportedField(GetProcAddress(FModuleHandle, 'ContentGetSupportedField'));
  ContentGetValue := TContentGetValue(GetProcAddress(FModuleHandle, 'ContentGetValue'));
  { Optional (must NOT be implemented if unsupported!) }
  ContentGetDetectString := TContentGetDetectString(GetProcAddress(FModuleHandle, 'ContentGetDetectString'));
  ContentSetDefaultParams := TContentSetDefaultParams(GetProcAddress(FModuleHandle, 'ContentSetDefaultParams'));
  ContentStopGetValue := TContentStopGetValue(GetProcAddress(FModuleHandle, 'ContentStopGetValue'));
  ContentGetDefaultSortOrder := TContentGetDefaultSortOrder(GetProcAddress(FModuleHandle, 'ContentGetDefaultSortOrder'));
  ContentPluginUnloading := TContentPluginUnloading(GetProcAddress(FModuleHandle, 'ContentPluginUnloading'));
  ContentGetSupportedFieldFlags := TContentGetSupportedFieldFlags(GetProcAddress(FModuleHandle, 'ContentGetSupportedFieldFlags'));
  ContentSetValue := TContentSetValue(GetProcAddress(FModuleHandle, 'ContentSetValue'));
  ContentEditValue := TContentEditValue(GetProcAddress(FModuleHandle, 'ContentEditValue'));
  ContentSendStateInformation := TContentSendStateInformation(GetProcAddress(FModuleHandle, 'ContentSendStateInformation'));
  { Unicode }
  ContentGetValueW := TContentGetValueW(GetProcAddress(FModuleHandle, 'ContentGetValueW'));
  ContentStopGetValueW := TContentStopGetValueW(GetProcAddress(FModuleHandle, 'ContentStopGetValueW'));
  ContentSetValueW := TContentSetValueW(GetProcAddress(FModuleHandle, 'ContentSetValueW'));
  ContentSendStateInformationW := TContentSendStateInformationW(GetProcAddress(FModuleHandle, 'ContentSendStateInformationW'));

  CallContentSetDefaultParams;
  CallContentGetSupportedField;
  if Length(Self.DetectStr) = 0 then
    Self.DetectStr := CallContentGetDetectString;
end;


procedure TPluginWDX.CallContentSetDefaultParams;
var
  dps: tContentDefaultParamStruct;
begin
  if assigned(ContentSetDefaultParams) then
  begin
    dps.DefaultIniName := mbFileNameToSysEnc(gpCfgDir + WdxIniFileName);
    dps.PluginInterfaceVersionHi := 1;
    dps.PluginInterfaceVersionLow := 50;
    dps.size := SizeOf(tContentDefaultParamStruct);
    ContentSetDefaultParams(@dps);
  end;
end;

procedure TPluginWDX.CallContentStopGetValue(FileName: String);
begin
  if Assigned(ContentStopGetValueW) then
    ContentStopGetValueW(PWideChar(UTF8Decode(FileName)))
  else if Assigned(ContentStopGetValue) then
      ContentStopGetValue(PAnsiChar(CeUtf8ToSys(FileName)));
end;

function TPluginWDX.CallContentGetDefaultSortOrder(FieldIndex: Integer): Boolean;
var
  x: Integer;
begin
  if Assigned(ContentGetDefaultSortOrder) then
  begin
    x := ContentGetDefaultSortOrder(FieldIndex);
    case x of
      1: Result := False;  //a..z 1..9
      -1: Result := True;  //z..a 9..1
    end;
  end;

end;

procedure TPluginWDX.UnloadModule;
begin
  if assigned(ContentPluginUnloading) then
    ContentPluginUnloading;

{$IF (not DEFINED(LINUX)) or ((FPC_VERSION > 2) or ((FPC_VERSION=2) and (FPC_RELEASE >= 5)))}
  if FModuleHandle <> 0 then
    FreeLibrary(FModuleHandle);
{$ENDIF}
  FModuleHandle := 0;

  { Mandatory }
  ContentGetSupportedField := nil;
  ContentGetValue := nil;
  { Optional (must NOT be implemented if unsupported!) }
  ContentGetDetectString := nil;
  ContentSetDefaultParams := nil;
  ContentStopGetValue := nil;
  ContentGetDefaultSortOrder := nil;
  ContentPluginUnloading := nil;
  ContentGetSupportedFieldFlags := nil;
  ContentSetValue := nil;
  ContentEditValue := nil;
  ContentSendStateInformation := nil;
  { Unicode }
  ContentGetValueW := nil;
  ContentStopGetValueW := nil;
  ContentSetValueW := nil;
  ContentSendStateInformationW := nil;
end;

procedure TPluginWDX.CallContentGetSupportedField;
var
  Index,
  MaxLen,
  I,
  Rez: Integer;
  xFieldName: PAnsiChar;
  xUnits: PAnsiChar;
  sFieldName: String;
begin
  if not Assigned(ContentGetSupportedField) then
    Exit;
  Index := 0;
  GetMem(xFieldName, MAX_PATH);
  GetMem(xUnits, MAX_PATH);
  maxlen := MAX_PATH;
  repeat
    Rez := ContentGetSupportedField(Index, xFieldName, xUnits, MaxLen);
    if Rez <> ft_nomorefields then
    begin
      sFieldName := CeSysToUtf8(StrPas(xFieldName));
      I := FFieldsList.AddObject(sFieldName, TWdxField.Create);
      with TWdxField(FFieldsList.Objects[I]) do
      begin
        FName := sFieldName;
        FUnits := xUnits;
        FType := Rez;
      end;
    end;
    Inc(Index);
  until Rez = ft_nomorefields;
  FreeMem(xFieldName);
  FreeMem(xUnits);
end;

function TPluginWDX.CallContentGetDetectString: String;
const
  MAX_LEN = 2048; // See contentplugin.hlp for details
begin
  if not Assigned(ContentGetDetectString) then
    Result := EmptyStr
  else begin
    Result := StringOfChar(#0, MAX_LEN);
    ContentGetDetectString(PAnsiChar(Result), MAX_LEN);
    Result := PAnsiChar(Result);
  end;
end;

function TPluginWDX.CallContentGetValueV(FileName: String; FieldIndex,
  UnitIndex: Integer; flags: Integer): Variant;
var
  Rez: Integer;
  Buf: array[0..WDX_MAX_LEN] of Byte;
  fnval: Integer absolute buf;
  fnval64: Int64 absolute buf;
  ffval: Double absolute buf;
  fdate: TDateFormat absolute buf;
  ftime: TTimeFormat absolute buf;
  wtime: TWinFileTime absolute buf;
begin
  EnterCriticalSection(FMutex);
  try
    if Assigned(ContentGetValueW) then
      Rez := ContentGetValueW(PWideChar(UTF8Decode(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), flags)
    else if Assigned(ContentGetValue) then
      Rez := ContentGetValue(PAnsiChar(mbFileNameToSysEnc(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), flags);

    case Rez of
      ft_fieldempty: Result := Unassigned;
      ft_numeric_32: Result := fnval;
      ft_numeric_64: Result := fnval64;
      ft_numeric_floating: Result := ffval;
      ft_date: Result := EncodeDate(fdate.wYear, fdate.wMonth, fdate.wDay);
      ft_time: Result := EncodeTime(ftime.wHour, ftime.wMinute, ftime.wSecond, 0);
      ft_datetime: Result :=  WinFileTimeToDateTime(wtime);
      ft_boolean: Result := Boolean(fnval);

      ft_multiplechoice,
      ft_string,
      ft_fulltext: Result := CeSysToUtf8(AnsiString(PAnsiChar(@Buf[0])));
      ft_stringw,
      ft_fulltextw: Result := UTF16ToUTF8(UnicodeString(PWideChar(@Buf[0])));
      else
        Result := Unassigned;
    end;
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TPluginWDX.CallContentGetValue(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): String;
var
  Rez: Integer;
  Buf: array[0..WDX_MAX_LEN] of Byte;
  fnval: Integer absolute buf;
  fnval64: Int64 absolute buf;
  ffval: Double absolute buf;
  fdate: TDateFormat absolute buf;
  ftime: TTimeFormat absolute buf;
  wtime: TWinFileTime absolute buf;
begin
  EnterCriticalSection(FMutex);
  try
    if Assigned(ContentGetValueW) then
      Rez := ContentGetValueW(PWideChar(UTF8Decode(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), flags)
    else if Assigned(ContentGetValue) then
        Rez := ContentGetValue(PAnsiChar(mbFileNameToSysEnc(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), flags);

    case Rez of
      ft_fieldempty: Result := '';
      ft_numeric_32: Result := IntToStr(fnval);
      ft_numeric_64: Result := IntToStr(fnval64);
      ft_numeric_floating: Result := FloatToStr(ffval);
      ft_date: Result :=  Format('%2.2d.%2.2d.%4.4d', [fdate.wDay, fdate.wMonth, fdate.wYear]);
      ft_time: Result := Format('%2.2d:%2.2d:%2.2d', [ftime.wHour, ftime.wMinute, ftime.wSecond]);
      ft_datetime: Result := DateTimeToStr(WinFileTimeToDateTime(wtime));

      ft_boolean: if fnval = 0 then
          Result := 'FALSE'
        else
          Result := 'TRUE';

      ft_multiplechoice,
      ft_string,
      ft_fulltext: Result := CeSysToUtf8(AnsiString(PAnsiChar(@Buf[0])));
      ft_stringw,
      ft_fulltextw: Result := UTF16ToUTF8(UnicodeString(PWideChar(@Buf[0])));
        //TODO: FT_DELAYED,ft_ondemand
      else
        Result := '';
    end;
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TPluginWDX.CallContentGetValue(FileName: String; FieldIndex: Integer; var UnitIndex: Integer): String;
var
  Rez: Integer;
  ValueA: AnsiString;
  ValueW: UnicodeString;
  Buf: array[0..WDX_MAX_LEN] of Byte;
begin
  EnterCriticalSection(FMutex);
  try
    if Assigned(ContentGetValueW) then
      Rez := ContentGetValueW(PWideChar(UTF8Decode(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), 0)
    else if Assigned(ContentGetValue) then
      Rez := ContentGetValue(PAnsiChar(mbFileNameToSysEnc(FileName)), FieldIndex, UnitIndex, @Buf, SizeOf(buf), 0);

    case Rez of
      ft_fieldempty:
        Result := EmptyStr;
      ft_fulltext:
        begin
          ValueA:= AnsiString(PAnsiChar(@Buf[0]));
          Inc(UnitIndex, Length(ValueA));
          Result := CeSysToUtf8(ValueA);
        end;
      ft_fulltextw:
        begin
          ValueW:= UnicodeString(PWideChar(@Buf[0]));
          Inc(UnitIndex, Length(ValueW) * SizeOf(WideChar));
          Result := UTF16ToUTF8(ValueW);
        end;
      else begin
        Result := EmptyStr;
      end;
    end;
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TPluginWDX.CallContentGetSupportedFieldFlags(FieldIndex: Integer): Integer;
begin
  if assigned(ContentGetSupportedFieldFlags) then
    Result := ContentGetSupportedFieldFlags(FieldIndex);
end;


function TPluginWDX.GetFieldIndex(FieldName: String): Integer;
begin
  Result := FFieldsList.IndexOf(FieldName);
end;


function TPluginWDX.FileParamVSDetectStr(const aFile: TFile): Boolean;
begin
  FParser.DetectStr := Self.DetectStr;
  Result := FParser.TestFileResult(aFile);
end;


{ TLuaWdx }

function TLuaWdx.GetAName: String;
begin
  Result := FName;
end;

function TLuaWdx.GetAFileName: String;
begin
  Result := FFileName;
end;

function TLuaWdx.GetADetectStr: String;
begin
  Result := FDetectStr;
end;

procedure TLuaWdx.SetAName(AValue: String);
begin
  FName := AValue;
end;

procedure TLuaWdx.SetAFileName(AValue: String);
begin
  FFileName := AValue;
end;

procedure TLuaWdx.SetADetectStr(const AValue: String);
begin
  FDetectStr := AValue;
end;

function TLuaWdx.DoScript(AName: String): Integer;
begin
  Result := LUA_ERRRUN;
  if not Assigned(L) then Exit;
  Result := luaL_dofile(L, PChar(AName));
  if Result <> 0 then begin
    DCDebug('TLuaWdx.DoScript: ', lua_tostring(L, -1));
  end;
end;

constructor TLuaWdx.Create;
begin
  inherited Create;
  if not IsLuaLibLoaded then
    LoadLuaLib(gLuaLib); //Todo вынести загрузку либы в VmClass
  FFieldsList := TStringList.Create;
  FParser := TParserControl.Create;
end;

destructor TLuaWdx.Destroy;
begin
  if Assigned(FParser) then
    FParser.Free;

  if Assigned(FFieldsList) then
  begin
    while FFieldsList.Count > 0 do
    begin
      TWdxField(FFieldsList.Objects[0]).Free;
      FFieldsList.Delete(0);
    end;
    FreeAndNil(FFieldsList);
  end;

  Self.UnloadModule;

  //UnloadLuaLib;           //Todo вынести выгрузку либы в VmClass

  inherited Destroy;
end;

function TLuaWdx.LoadModule: Boolean;
begin
  Result := False;
  if not IsLuaLibLoaded then
    exit;

  L := lua_open;
  if not Assigned(L) then
    exit;

  luaL_openlibs(L);

  RegisterPackages(L);

  if DoScript(Self.FFileName) = 0 then
    Result := True
  else
    Result := False;

  CallContentSetDefaultParams;
  CallContentGetSupportedField;
  if Length(Self.DetectStr) = 0 then
    Self.DetectStr := CallContentGetDetectString;
end;

procedure TLuaWdx.UnloadModule;
begin
  WdxLuaContentPluginUnloading;

  if Assigned(L) then
  begin
    lua_close(L);
    L := nil;
  end;
end;

function TLuaWdx.IsLoaded: Boolean;
begin
  Result := IsLuaLibLoaded and Assigned(Self.L);
end;

function TLuaWdx.FieldList: TStringList;
begin
  Result := FFieldsList;
end;

function TLuaWdx.GetFieldIndex(FieldName: String): Integer;
begin
  Result := FFieldsList.IndexOf(FieldName);
end;

function TLuaWdx.FileParamVSDetectStr(const aFile: TFile): Boolean;
begin
  FParser.DetectStr := Self.DetectStr;
  Result := FParser.TestFileResult(aFile);
end;

function TLuaWdx.WdxLuaContentGetSupportedField(Index: Integer; var xFieldName, xUnits: String): Integer;
begin
  Result := ft_nomorefields;
  if not assigned(L) then
    exit;
  lua_getglobal(L, 'ContentGetSupportedField');
  if not lua_isfunction(L, -1) then
    exit;
  lua_pushinteger(L, Index);
  LuaPCall(L, 1, 3);
  xFieldName := lua_tostring(L, -3);
  xUnits := lua_tostring(L, -2);
  Result := Integer(lua_tointeger(L, -1));
  lua_pop(L, 3);
end;

procedure TLuaWdx.WdxLuaContentPluginUnloading;
begin
  if not assigned(L) then
    exit;
  lua_getglobal(L, 'ContentPluginUnloading');
  if not lua_isfunction(L, -1) then
    exit;
  LuaPCall(L, 0, 0);
end;

procedure TLuaWdx.CallContentGetSupportedField;
var
  Index, Rez, tmp: Integer;
  xFieldName, xUnits: String;
begin
  Index := 0;
  repeat
    Rez := WdxLuaContentGetSupportedField(Index, xFieldName, xUnits);
    DCDebug('WDX:CallGetSupFields:' + IntToStr(Rez));
    if Rez <> ft_nomorefields then
    begin
      tmp := FFieldsList.AddObject(xFieldName, TWdxField.Create);
      TWdxField(FFieldsList.Objects[tmp]).FName := xFieldName;
      TWdxField(FFieldsList.Objects[tmp]).FUnits := xUnits;
      TWdxField(FFieldsList.Objects[tmp]).FType := Rez;
    end;
    Inc(Index);

  until Rez = ft_nomorefields;
end;

procedure TLuaWdx.CallContentSetDefaultParams;
begin
  if not assigned(L) then
    exit;
  lua_getglobal(L, 'ContentSetDefaultParams');
  if not lua_isfunction(L, -1) then
    exit;
  lua_pushstring(L, PAnsiChar(mbFileNameToSysEnc(gpCfgDir + WdxIniFileName)));
  lua_pushinteger(L, 1);
  lua_pushinteger(L, 50);
  LuaPCall(L, 3, 0);
end;

procedure TLuaWdx.CallContentStopGetValue(FileName: String);
begin
  if not assigned(L) then
    exit;
  lua_getglobal(L, 'ContentStopGetValue');
  if not lua_isfunction(L, -1) then
    exit;
  lua_pushstring(L, PAnsiChar(mbFileNameToSysEnc(FileName)));
  LuaPCall(L, 1, 0);
end;

function TLuaWdx.CallContentGetDefaultSortOrder(FieldIndex: Integer): Boolean;
var
  x: Integer;
begin
  Result := False;
  if not assigned(L) then
    exit;

  lua_getglobal(L, 'ContentGetDefaultSortOrder');
  if not lua_isfunction(L, -1) then
    exit;
  lua_pushinteger(L, FieldIndex);
  LuaPCall(L, 1, 1);

  x := lua_tointeger(L, -1);
  case x of
    1: Result := False;  //a..z 1..9
    -1: Result := True;  //z..a 9..1
  end;
  lua_pop(L, 1);
end;

function TLuaWdx.CallContentGetDetectString: String;
begin
  Result := '';
  if not assigned(L) then
    exit;

  lua_getglobal(L, 'ContentGetDetectString');
  if not lua_isfunction(L, -1) then
    exit;
  LuaPCall(L, 0, 1);
  Result := lua_tostring(L, -1);
  lua_pop(L, 1);
end;

function TLuaWdx.CallContentGetValueV(FileName: String; FieldIndex,
  UnitIndex: Integer; flags: Integer): Variant;
begin
  EnterCriticalSection(FMutex);
  try
    Result := Unassigned;
    if not Assigned(L) then
      Exit;

    lua_getglobal(L, 'ContentGetValue');
    if not lua_isfunction(L, -1) then
      Exit;
    lua_pushstring(L, PAnsiChar(mbFileNameToSysEnc(FileName)));
    lua_pushinteger(L, FieldIndex);
    lua_pushinteger(L, UnitIndex);
    lua_pushinteger(L, flags);

    LuaPCall(L, 4, 1);

    if not lua_isnil(L, -1) then
    begin
      case TWdxField(FieldList.Objects[FieldIndex]).FType of
        ft_string,
        ft_fulltext:
          Result := StrPas(lua_tostring(L, -1));
        ft_numeric_32:
          Result := Int32(lua_tointeger(L, -1));
        ft_numeric_64:
          Result := Int64(lua_tointeger(L, -1));
        ft_boolean:
          Result := lua_toboolean(L, -1);
        ft_numeric_floating:
          Result := lua_tonumber(L, -1);
      end;
    end;

    lua_pop(L, 1);
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TLuaWdx.CallContentGetValue(FileName: String; FieldIndex, UnitIndex: Integer; flags: Integer): String;
begin
  EnterCriticalSection(FMutex);
  try
    Result := '';
    if not Assigned(L) then
      Exit;

    lua_getglobal(L, 'ContentGetValue');
    if not lua_isfunction(L, -1) then
      Exit;
    lua_pushstring(L, PAnsiChar(mbFileNameToSysEnc(FileName)));
    lua_pushinteger(L, FieldIndex);
    lua_pushinteger(L, UnitIndex);
    lua_pushinteger(L, flags);

    LuaPCall(L, 4, 1);

    if not lua_isnil(L, -1) then
    begin
      case TWdxField(FieldList.Objects[FieldIndex]).FType of
        ft_string,
        ft_fulltext:
          Result := lua_tostring(L, -1);
        ft_numeric_32:
          Result := IntToStr(Int32(lua_tointeger(L, -1)));
        ft_numeric_64:
          Result := IntToStr(Int64(lua_tointeger(L, -1)));
        ft_numeric_floating:
          Result := FloatToStr(lua_tonumber(L, -1));
        ft_boolean:
          Result := BoolToStr(lua_toboolean(L, -1), True);
      end;
    end;

    lua_pop(L, 1);
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TLuaWdx.CallContentGetValue(FileName: String; FieldIndex: Integer; var UnitIndex: Integer): String;
begin
  EnterCriticalSection(FMutex);
  try
    Result := EmptyStr;
    if not Assigned(L) then
      Exit;

    lua_getglobal(L, 'ContentGetValue');
    if not lua_isfunction(L, -1) then
      Exit;
    lua_pushstring(L, PAnsiChar(mbFileNameToSysEnc(FileName)));
    lua_pushinteger(L, FieldIndex);
    lua_pushinteger(L, UnitIndex);
    lua_pushinteger(L, 0);

    LuaPCall(L, 4, 1);

    if not lua_isnil(L, -1) then
    begin
      Result := lua_tostring(L, -1);
      Inc(UnitIndex, Length(Result));
    end;

    lua_pop(L, 1);
  finally
    LeaveCriticalSection(FMutex);
  end;
end;

function TLuaWdx.CallContentGetSupportedFieldFlags(FieldIndex: Integer): Integer;
begin
  Result := 0;
  if not assigned(L) then
    exit;

  lua_getglobal(L, 'ContentGetSupportedFieldFlags');
  if not lua_isfunction(L, -1) then
    exit;
  lua_pushinteger(L, FieldIndex);

  LuaPCall(L, 1, 1);
  Result := lua_tointeger(L, -1);
  lua_pop(L, 1);

end;

{ TEmbeddedWDX }

function TEmbeddedWDX.GetAName: String;
begin

end;

function TEmbeddedWDX.GetAFileName: String;
begin

end;

function TEmbeddedWDX.GetADetectStr: String;
begin

end;

procedure TEmbeddedWDX.SetAName(AValue: String);
begin

end;

procedure TEmbeddedWDX.SetAFileName(AValue: String);
begin

end;

procedure TEmbeddedWDX.SetADetectStr(const AValue: String);
begin

end;

procedure TEmbeddedWDX.AddField(const AName: String; AType: Integer);
var
  I: Integer;
begin
  I := FFieldsList.AddObject(AName, TWdxField.Create);
  with TWdxField(FFieldsList.Objects[I]) do
  begin
    FName := AName;
    FType := AType;
  end;
end;

constructor TEmbeddedWDX.Create;
begin
  inherited Create;
  FParser:= TParserControl.Create;
  FFieldsList:= TStringList.Create;
  CallContentGetSupportedField;
end;

destructor TEmbeddedWDX.Destroy;
begin
  FParser.Free;
  FFieldsList.Free;
  inherited Destroy;
end;

function TEmbeddedWDX.LoadModule: Boolean;
begin
  Result:= True;
end;

procedure TEmbeddedWDX.UnloadModule;
begin

end;

function TEmbeddedWDX.IsLoaded: Boolean;
begin
  Result:= True;
end;

function TEmbeddedWDX.FieldList: TStringList;
begin
  Result:= FFieldsList;
end;

function TEmbeddedWDX.GetFieldIndex(FieldName: String): Integer;
begin
  Result := FFieldsList.IndexOf(FieldName);
end;

function TEmbeddedWDX.FileParamVSDetectStr(const aFile: TFile): Boolean;
begin
  FParser.DetectStr := Self.DetectStr;
  Result := FParser.TestFileResult(aFile);
end;

{ TWDXModule }

constructor TWDXModule.Create;
begin
  InitCriticalSection(FMutex);
end;

destructor TWDXModule.Destroy;
begin
  inherited Destroy;
  DoneCriticalSection(FMutex);
end;

function TWDXModule.WdxFieldType(n: Integer): String;
begin
  case n of
    FT_NUMERIC_32: Result := 'FT_NUMERIC_32';
    FT_NUMERIC_64: Result := 'FT_NUMERIC_64';
    FT_NUMERIC_FLOATING: Result := 'FT_NUMERIC_FLOATING';
    FT_DATE: Result := 'FT_DATE';
    FT_TIME: Result := 'FT_TIME';
    FT_DATETIME: Result := 'FT_DATETIME';
    FT_BOOLEAN: Result := 'FT_BOOLEAN';
    FT_MULTIPLECHOICE: Result := 'FT_MULTIPLECHOICE';
    FT_STRING: Result := 'FT_STRING';
    FT_FULLTEXT: Result := 'FT_FULLTEXT';
    FT_NOSUCHFIELD: Result := 'FT_NOSUCHFIELD';
    FT_FILEERROR: Result := 'FT_FILEERROR';
    FT_FIELDEMPTY: Result := 'FT_FIELDEMPTY';
    FT_DELAYED: Result := 'FT_DELAYED';
    else
      Result := '?';
  end;
end;

function TWDXModule.CallContentGetValueV(FileName: String; FieldName: String;
  UnitName: String; flags: Integer): Variant;
var
  FieldIndex,
  UnitIndex: Integer;
begin
  FieldIndex := GetFieldIndex(FieldName);
  if FieldIndex <> -1 then
  begin
    UnitIndex := TWdxField(FieldList.Objects[FieldIndex]).GetUnitIndex(UnitName);
    Result := CallContentGetValueV(FileName, FieldIndex, UnitIndex, flags);
  end
  else
    Result := Unassigned;
end;

function TWDXModule.CallContentGetValue(FileName: String; FieldName: String;
  UnitName: String; flags: Integer): String;
var
  FieldIndex,
  UnitIndex: Integer;
begin
  FieldIndex := GetFieldIndex(FieldName);
  if FieldIndex <> -1 then
  begin
    UnitIndex := TWdxField(FieldList.Objects[FieldIndex]).GetUnitIndex(UnitName);
    Result := CallContentGetValue(FileName, FieldIndex, UnitIndex, flags);
  end
  else
    Result := EmptyStr;
end;

{ TWdxField }

function TWdxField.GetUnitIndex(UnitName: String): Integer;
var
  sUnits: String;
begin
  Result := -1;
  sUnits := FUnits;
  while sUnits <> EmptyStr do
  begin
    Inc(Result);
    if SameText(UnitName, Copy2SymbDel(sUnits, '|')) then
      Exit;
  end;
  Result := 0;
end;

end.

