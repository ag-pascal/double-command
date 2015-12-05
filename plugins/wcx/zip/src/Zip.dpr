library Zip;



uses
  FPCAdds,
  SysUtils,
  Classes,
  ZipFunc in 'ZipFunc.pas';

exports
  { Mandatory }
  OpenArchive,
  OpenArchiveW,
  ReadHeader,
  ReadHeaderExW,
  ProcessFile,
  ProcessFileW,
  CloseArchive,
  SetChangeVolProc,
  SetChangeVolProcW,
  SetProcessDataProc,
  SetProcessDataProcW,
  { Optional }
  PackFilesW,
  DeleteFilesW,
  GetPackerCaps,
  ConfigurePacker,
  CanYouHandleThisFileW,
  { Extension API }
  ExtensionInitialize;

{$R *.res}

begin
{$IFDEF UNIX}
WriteLN('Zip plugin is loaded');
{$ENDIF}
end.
