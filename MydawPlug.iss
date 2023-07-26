; -- 64Bit.iss --
; Demonstrates installation of a program built for the x64 (a.k.a. AMD64)
; architecture.
; To successfully run this installation and the program it installs,
; you must have a "x64" edition of Windows.

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

#define AppId "{CB812BFC-5FFF-426E-83F9-75744A80FAB9}"
#define AppName "MyDaw Plug"




[Setup]
AppId={{#AppId}
AppName=MyDaw Plugins
AppVersion=1.0
DefaultDirName={sd}\MyDaw
DefaultGroupName=MyDaw Plug
SetupLogging=yes
Uninstallable=yes
CreateAppDir=no
; Определ¤ет название программы на странице ”становка и удаление программ ѕанели управлени¤
UninstallDisplayName={#AppName}
; ќпредел¤ет папку, в которой будут содержатьс¤ файлы деинсталл¤тора "unins*.*".
UninstallFilesDir={src}
Compression=lzma
SolidCompression=yes
OutputDir=!!Compiled
OutputBaseFilename=MyDawInstall
; "ArchitecturesAllowed=x64" specifies that Setup cannot run on
; anything but x64.
ArchitecturesAllowed=x64
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64
WizardStyle = modern


//[Dirs]
;Name: "{code:GetFolderPath|'Data\!Documents\'|'{userdocs}'|true).name}"; 

//[Files]
;Source: "Data\!Documents\*"; DestDir: "{userdocs}";Flags: ignoreversion recursesubdirs createallsubdirs
; Install the mysql\data, only if it does not exist yet
; Install the mysql\data, only if it does not exist yet

//[Icons]
;Name: "{group}\My Program"; Filename: "{app}\MyProg.exe"

[Run]
FileName: "{src}\Data\Misc\Install.cmd"; Flags: nowait runhidden skipifsilent

[UninstallRun]
Filename: "{src}\Data\Misc\Uninstall.cmd"; Flags: runhidden


[Code]

//////////////////////////////////////INST PROCCES SHOW
  const
  GWL_WNDPROC = -4;
  SB_VERT = 1;
  SB_BOTTOM = 7;
  WM_VSCROLL = $0115;
  WM_ERASEBKGND = $0014;

type
  WPARAM = UINT_PTR;
  LPARAM = LongInt;
  LRESULT = LongInt;

var
  OldStatusLabelWndProc: LongInt;
  OldFilenameLabelWndProc: LongInt;
  OldProgressListBoxWndProc: LongInt;
  ProgressListBox: TNewListBox;
  PrevStatus: string;
  PrevFileName: string;

function CallWindowProc(
  lpPrevWndFunc: LongInt; hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; external 'CallWindowProcW@user32.dll stdcall';  
function SetWindowLong(hWnd: HWND; nIndex: Integer; dwNewLong: LongInt): LongInt;
  external 'SetWindowLongW@user32.dll stdcall';

procedure AddProgress(S: string);
begin
  if S <> '' then
  begin

    ProgressListBox.Items.Add(S);
    ProgressListBox.ItemIndex := ProgressListBox.Items.Count;
    SendMessage(ProgressListBox.Handle, WM_VSCROLL, SB_BOTTOM, 0);

  end;
end;

function StatusLabelWndProc(
  hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  Result := CallWindowProc(OldStatusLabelWndProc, hwnd, uMsg, wParam, lParam);
  if PrevStatus <> WizardForm.StatusLabel.Caption then
  begin
    AddProgress(WizardForm.StatusLabel.Caption);
    PrevStatus := WizardForm.StatusLabel.Caption;
  end;
end;

function FilenameLabelWndProc(
  hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  Result := CallWindowProc(OldFilenameLabelWndProc, hwnd, uMsg, wParam, lParam);
  if PrevFileName <> WizardForm.FilenameLabel.Caption then
  begin
    AddProgress(WizardForm.FilenameLabel.Caption);
    PrevFileName := WizardForm.FilenameLabel.Caption;
  end;
end;

function ProgressListBoxWndProc(
  hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;
begin
  // reduce flicker
  if uMsg = WM_ERASEBKGND then
  begin
    Result := 1;
  end
    else
  begin
    Result :=
      CallWindowProc(OldProgressListBoxWndProc, hwnd, uMsg, wParam, lParam);
  end;
end;



 ////////////////////////////////////////PAUSE BEFORE FINISH


var
  AfterInstallPage: TWizardPage;


procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = AfterInstallPage.ID) and
     // Prevent re-adding "Done" to the ProgressListBox when revisiting the page
     (ProgressListBox.Parent <> AfterInstallPage.Surface) then
  begin
    WizardForm.ProgressGauge.Parent := AfterInstallPage.Surface;
    // prevent reanimating the progress
    WizardForm.ProgressGauge.Position := WizardForm.ProgressGauge.Max - 1;
    WizardForm.ProgressGauge.Position := WizardForm.ProgressGauge.Max;

    ProgressListBox.Parent := AfterInstallPage.Surface;
    WizardForm.StatusLabel.Parent := AfterInstallPage.Surface;
    WizardForm.StatusLabel.Caption := 'Done.';
    AddProgress('Done');
  end;
end;

/////////////////////////////////////////////////////////////////



procedure InitializeWizard();
begin
    ////////////////////////////////////////PAUSE BEFORE FINISH
   AfterInstallPage :=
    CreateCustomPage(wpInstalling, 'Installation done', 'Installation has completed');
   ////////////////////////////////////////PAUSE BEFORE FINISH
  
  OldStatusLabelWndProc :=
    SetWindowLong(WizardForm.StatusLabel.Handle, GWL_WNDPROC,
      CreateCallback(@StatusLabelWndProc));
  OldFilenameLabelWndProc :=
    SetWindowLong(WizardForm.FilenameLabel.Handle, GWL_WNDPROC,
      CreateCallback(@FilenameLabelWndProc));

  WizardForm.ProgressGauge.Top := WizardForm.FilenameLabel.Top;

  ProgressListBox := TNewListBox.Create(WizardForm);
  ProgressListBox.Parent := WizardForm.ProgressGauge.Parent;
  ProgressListBox.Top :=
    WizardForm.ProgressGauge.Top + WizardForm.ProgressGauge.Height + ScaleY(8);
  ProgressListBox.Width := WizardForm.FilenameLabel.Width;
  ProgressListBox.Height :=
    ProgressListBox.Parent.ClientHeight - ProgressListBox.Top - ScaleY(16);
  ProgressListBox.Anchors := [akLeft, akTop, akRight, akBottom];
  OldProgressListBoxWndProc :=
    SetWindowLong(ProgressListBox.Handle, GWL_WNDPROC,
      CreateCallback(@ProgressListBoxWndProc));
  // Lame way to shrink width of labels to client width of the list box,
  // so that particularly when the file paths in FilenameLabel are shortened
  // to fit to the label, they actually fit even to the list box.
  WizardForm.StatusLabel.Width := WizardForm.StatusLabel.Width - ScaleY(24);
  WizardForm.FilenameLabel.Width := WizardForm.FilenameLabel.Width - ScaleY(24);
end;

procedure DeinitializeSetup();
begin
  // In case you are using VCL styles or similar, this needs to be done before
  // you unload the style.
  SetWindowLong(
    WizardForm.StatusLabel.Handle, GWL_WNDPROC, OldStatusLabelWndProc);
  SetWindowLong(
    WizardForm.FilenameLabel.Handle, GWL_WNDPROC, OldFilenameLabelWndProc);
  SetWindowLong(
    ProgressListBox.Handle, GWL_WNDPROC, OldProgressListBoxWndProc);
end;





///////////////////////////////////////////////////////////////////////////////////////











 // вводим новый тип данных SYMLINK_INFO
 type SYMLINK_INFO = record
  name:string;    // им¤ ссылки (полный путь)
  target:string;  // объект (файл или папка), на который указывает ссылка
  create_dir:boolean;   // если true - ссылка на каталог, иначе на файл
  relative:boolean;   // если true - будет создана относительна¤ ссылка, иначе - пр¤ма¤
  end;


   // макрос упрощени¤ обращени¤ с ¤зыковыми строками
function cm(s: String): String;
begin
  Result:= ExpandConstant('{cm:'+s+'}');
end;





const
// константы для WinAPI функций
  INVALID_FILE_ATTRIBUTES = $FFFFFFFF;
 // FILE_ATTRIBUTE_REPARSE_POINT := $400;
 // FILE_ATTRIBUTE_DIRECTORY := $10;
 OPEN_EXISTING =3; 
 VOLUME_NAME_NT=2;
 FILE_FLAG_BACKUP_SEMANTICS=$2000000;
 

 /////===== Начало - ExecAndWait =====\\\\\
var
  lastproc: cardinal;
  LinkBuff: SYMLINK_INFO;

const
  NORMAL_PRIORITY_CLASS           = $00000020;
  REALTIME_PRIORITY_CLASS         = $00000100;

type
  _TStartupInfo = record
  cb: DWORD;
  lpReserved, lpDesktop: Longint;
  lpTitle: PAnsiChar;
  dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags: DWORD;
  wShowWindow, cbReserved2: Word;
  lpReserved2: Byte;
  hStdInput, hStdOutput, hStdError: Longint;
end;
  _TProcessInformation = record
  hProcess, hThread: Longint;
  dwProcessId, dwThreadId: DWORD;
end;
  _TMsg = record
  hWnd: HWND;
  msg, wParam: Word;
  lParam: LongWord;
  Time: TFileTime;
  pt: TPoint;
end;

function OpenProcess(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwProcessId: DWORD): THandle; external 'OpenProcess@kernel32.dll stdcall';
function CloseHandle(hObject: THandle): BOOL; external 'CloseHandle@kernel32.dll stdcall';
procedure GetStartupInfo(var lpStartupInfo: _TStartupInfo); external 'GetStartupInfoA@kernel32.dll stdcall';
function CreateProcess(lpApplicationName: PAnsiChar; lpCommandLine: PAnsiChar; lpProcessAttributes, lpThreadAttributes: DWORD; bInheritHandles: BOOL; dwCreationFlags: DWORD; lpEnvironment: PAnsiChar; lpCurrentDirectory: PAnsiChar; const lpStartupInfo: _TStartupInfo; var lpProcessInformation: _TProcessInformation): BOOL; external 'CreateProcessA@kernel32.dll stdcall';
function WaitForSingleObject(hHandle: Longint; dwMilliseconds: DWORD): DWORD; external 'WaitForSingleObject@kernel32.dll stdcall';
function TerminateProcess(hProcess: Longint; uExitCode: UINT): BOOL; external 'TerminateProcess@kernel32.dll stdcall';
function PeekMessage(var lpMsg: _TMsg; hWnd: HWND; wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL; external 'PeekMessageA@user32.dll stdcall';
function TranslateMessage(const lpMsg: _TMsg): BOOL; external 'TranslateMessage@user32.dll stdcall';
function DispatchMessage(const lpMsg: _TMsg): Longint; external 'DispatchMessageA@user32.dll stdcall';

procedure Application_ProcessMessages;
var
  Msg: _TMsg;
  begin
  while PeekMessage(Msg, 0, 0, 0, 1) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

function ExecAndWait(filename, params, cur_dir: pansichar; showcmd: integer; Wait: boolean; Priority: Smallint): Boolean;
var
  SI : _TStartupInfo;
  PI : _TProcessInformation;
  CMD: string;
  prt: DWORD;
  
  begin
    Result:=false;
	if Length(params)=0 then 
	 CMD:= filename
	else
     CMD:='"' + filename + '" ' + params;

   
    GetStartupInfo(SI);
    SI.wShowWindow := showcmd;
    SI.dwFlags := 1;
  if Priority = 0  then prt:= NORMAL_PRIORITY_CLASS else
  if Priority = 1  then prt:= REALTIME_PRIORITY_CLASS;
    Result:=CreateProcess('', PansiChar(CMD), 0, 0, false, prt,'', cur_dir, SI, PI);
    lastproc:=PI.dwProcessId;
  if wait then
  while WaitforSingleObject(PI.hProcess, 50) = $00000102 do
  Application_ProcessMessages;
  CloseHandle(PI.hProcess);
end;
/////===== Конец - ExecAndWait =====\\\\\


// импорт WinAPI функций

// WinAPI функция для получения списка логических дисков системы в формате массива C:\#0D:\#0E:\#0...#0):
function GetLogicalDriveStrings(nBufferLength: DWORD; lpBuffer: String): DWORD;
 external 'GetLogicalDriveStringsW@kernel32.dll stdcall';

// WinAPI функция для получения MS-DOS имени диска по его букве (например, C: ->\Device\HarddiskVolume1):
function QueryDosDevice(lpDeviceName: String; lpTargetPath: String; ucchMax: DWORD): DWORD;
 external 'QueryDosDeviceW@kernel32.dll stdcall';

// WinAPI функция для создания или открытия файла:
function CreateFile(
    lpFileName             : String;
    dwDesiredAccess        : Cardinal;
    dwShareMode            : Cardinal;
    lpSecurityAttributes   : Cardinal;
    dwCreationDisposition  : Cardinal;
    dwFlagsAndAttributes   : Cardinal;
    hTemplateFile          : Integer
): THandle;
 external 'CreateFileW@kernel32.dll stdcall'; 

// WinAPI функция для  закрытия хэндла (закрытия открытого файла):
//function CloseHandle(hHandle: THandle): BOOL;
//external 'CloseHandle@kernel32.dll stdcall';

// WinAPI функция для получения пути к объекту, на который указывает симлинк по хэндлу открытого симлинка:
function GetFinalPathNameByHandle(
    hFile: THandle;
    pszFilePath: String;
    cchFilePath, dwFlags:DWORD
): DWORD;
external 'GetFinalPathNameByHandleW@kernel32.dll stdcall';
 
//  WinAPI функция для получения аттрибутов файла/папки:
//  lpFileName - путь и имя файла/папки
//  нас интересует аттрибут FILE_ATTRIBUTE_REPARSE_POINT = 0x400, чтобы отличить реальный файл от симлинка
function GetFileAttributes(lpFileName: string): DWORD;
  external 'GetFileAttributesW@kernel32.dll stdcall';

//  WinAPI функция для создания симлинка:
//  lpFileName - путь и имя связи
//  lpExistingFileName - путь (абсолютный или относительный к связи) и имя целевого файла
//  dwFlags - если = 0 ссылка для файла, если = 1 ссылка для папки
//  возвращает true если ссылка создана
function CreateSymbolicLink(lpFileName, lpExistingFileName: String; dwFlags: Integer): Boolean;
  external 'CreateSymbolicLinkW@kernel32.dll stdcall';

//  WinAPI функция для получения пути к 'To' относительно 'From' 
//  Out - выходной относительный путь
//  From, To - входные пути
//  AttrFrom, AttrTo - атрибуты входных файлов (если содержат атрибут FILE_ATTRIBUTE_DIRECTORY, то рассматриваются как папки) 
function PathRelativePathTo(szOut:string; szFrom:string; AttrFrom:DWORD; szTo:string; AttrTo:DWORD): BOOLEAN;
  external 'PathRelativePathToW@Shlwapi.dll stdcall';

  
// регистронезависимое сравнение путей (возвращает True, если пути совпадают)
function IsPathsEqual(path1,path2:string):boolean;
begin
Result:=(0 = CompareText(RemoveBackslashUnlessRoot(Trim(path1)), RemoveBackslashUnlessRoot(Trim(path2))) )
end;

//wrapper (удобная обёртка для WinAPI функции CreateSymbolicLink)
// возвращает true если Link.name успешно создан]
// ErrMsg - текст ошибки при неудачном завершении
function CreateSymLink(Link: SYMLINK_INFO; var ErrMsg:string): boolean;

var ErrDesc: string; 
		Err:boolean;
		dwFlags:Integer;
		Attrs: DWORD;
		buffer, RelLink:string;
		
begin

ErrMsg:='';
ErrDesc:='';
Err:=false;
if Link.create_dir then begin 
	dwFlags:=1;
	Attrs:=FILE_ATTRIBUTE_DIRECTORY;
	end
else 	begin
	dwFlags:=0;
	Attrs:=0;
	end;
if not Link.create_dir and not FileExists(Link.target) then begin
	Err:=true;
	ErrDesc:=cm('FilePointFailed');
	end;
	
if not Err and Link.create_dir and not DirExists(Link.target) then begin
	Err:=true;
	ErrDesc:=cm('FolderPointFailed');
	end;

if not Err and not ForceDirectories(ExtractFileDir(Link.name)) then begin
	Err:=true;
	ErrDesc:=cm('CreateParentFailed');
	end;	
	
if not Err and Link.relative then begin
	RelLink:=ExtractFilePath(Link.name);
	if Attrs=0 then RelLink:=ExtractFilePath(RelLink);
	SetLength(buffer, 1024);
	if not PathRelativePathTo(buffer, RelLink, Attrs,Link.target, Attrs) then begin
		Err:=true;
		ErrDesc:=cm('RelPathFailed');
		end;
	Link.target:=Buffer;
	end;

	
if not Err and not CreateSymbolicLink(Link.name, Link.target, dwFlags) then begin
	Err:=true;
	ErrDesc:=SysErrorMessage(DLLGetLastError);
	end;

if Err then begin

	ErrMsg:=cm('LinkCreateFailed') + #13#13 + Link.name + #13#13 ;
	if Link.create_dir then ErrMsg:=ErrMsg+cm('ToTheFolder')
	else ErrMsg:=ErrMsg+cm('ToTheFile');
	ErrMsg:=ErrMsg + ':' + #13#13 + Link.target +#13#13 + ErrDesc;
	Result:=false;
	exit;
	end;
	
Result:=True; // ссылка успешно  создана

end;


// удаляет файл/папку Link только, если это симлинк
// возвращает true если Link не существует или успешно удалён
//function DeleteSymLink(LinkName: String): boolean;
//var Attrs: DWORD;
//begin
//	 Result:=false;
//	 Attrs := GetFileAttributes(LinkName);
//	 if (Attrs <> INVALID_FILE_ATTRIBUTES)  then begin
//		 if  Attrs and FILE_ATTRIBUTE_REPARSE_POINT <> 0 then
		 // это ссылка и её можно без плачевных для пользователя последствий удалить
//		 begin
//			if (Attrs and FILE_ATTRIBUTE_DIRECTORY<>0) then // это ссылка на каталог
//				Result:=RemoveDir(LinkName)
//			else  // это ссылка на файл
//				Result:=DeleteFile(LinkName);
//		 end;
//	 end else if (DLLGetLastError()=2) or (DLLGetLastError()=3) then begin Result:=true; exit; end; // Link не существует
//
//end;

// замена имени MS-DOS устройства в пути,  на букву диска 
function ReplaceDeviceNameToLogicalDrive( var DevicePath:string ):boolean;
var  szDrives, szDeviceName,sDeviceName: string;
    iLen, DeviceNameSize: DWORD;
	Letter:string;
begin 
			Result:=false;
			SetLength(szDeviceName, 1024);
			iLen := GetLogicalDriveStrings(0, #0);
			if iLen = 0 then Exit;
			SetLength(szDrives, iLen);
			if GetLogicalDriveStrings(Length(szDrives), szDrives) = 0 then Exit;
			szDrives := TrimRight(szDrives) + #0;
			iLen := Pos(#0, szDrives);
			while iLen > 0 do
			begin
			//SetLength(Letter,iLen - 2);
				Letter := Copy(szDrives, 1, iLen - 2);
				DeviceNameSize:=QueryDosDevice(Letter, szDeviceName, Length(szDeviceName));
               if DeviceNameSize > 0 then
                begin
					sDeviceName:=Copy(szDeviceName,1,DeviceNameSize-2);
                    if (DeviceNameSize-2<=Length(DevicePath)) and (Pos(sDeviceName, DevicePath) = 1) then
                    begin					
                        StringChangeEx(DevicePath, sDeviceName, Letter, True);
						Result:=true;
                        Break;
                    end;
                end;				
				
		        Delete(szDrives, 1, iLen);
				iLen := Pos(#0, szDrives);
			end;
end;


// получение пути к файлу/папке, на который указывает ссылка
function GetSymlinkTargetPath(Link:string; var TargetPath:string):boolean;
var hFile: THandle;
PathLen:DWORD;
begin
	Result:=false;
    hFile := CreateFile(Link,               // file to open
                       0,          // open for reading GENERIC_READ
                       2,       // share for reading FILE_SHARE_READ
                       0,                  // default security
                       OPEN_EXISTING,         // existing file only
                       FILE_FLAG_BACKUP_SEMANTICS, // normal file
                       0);  // no attr. template
	if hFile = THandle(-1) then exit;
	
	PathLen:=GetFinalPathNameByHandle( hFile, TargetPath, 0, VOLUME_NAME_NT );
	if PathLen=0 then exit;
	SetLength(TargetPath, PathLen);	
	if (0 <> GetFinalPathNameByHandle( hFile, TargetPath, PathLen, VOLUME_NAME_NT ) ) 
		and ReplaceDeviceNameToLogicalDrive(TargetPath) then begin
		Result:=true;
		end;	
	CloseHandle(hFile);

	

end;

// определяем свободно ли имя Link.name
// если папка, файл или симлинк, который указывает на файл, отличный от Link.target
// уже существует, то функция возвращает True (надо удалять)
// и кидает мессидж пользователю с предложением удалить/переместить/переименовать существующий файл/папку
// если имя свободно возвращает False (можно создавать симлинк)

function NeedDelLnkMsg(Link:SYMLINK_INFO):boolean;
var Attrs: DWORD; TargetPath:string; ErrorCode:integer;
begin
	Attrs := GetFileAttributes(Link.name);
	if (Attrs <> INVALID_FILE_ATTRIBUTES)  then begin		
		if  (Attrs and FILE_ATTRIBUTE_REPARSE_POINT <> 0) and // это симлинк
			((Attrs and FILE_ATTRIBUTE_DIRECTORY<>0)=Link.create_dir)  and// атрибут "папка" у создаваемого и существующего объектов совпадают 
			GetSymlinkTargetPath(Link.name, TargetPath) and
			(0 = CompareText(RemoveBackslashUnlessRoot(Trim(TargetPath)),
			RemoveBackslashUnlessRoot(Trim(Link.target))) )  // путь существующего объекта ссылки и создаваемого совпадают
		 then begin
			Result:=false; // необходимая ссылка уже создана
			exit;
		 end;
	end
	else if (DLLGetLastError()=2) or (DLLGetLastError()=3) then begin 
			Result:=false; // Link.name не существует - свободное имя для ссылки - можно создавать
			exit;
			end;
	Result:=true; // не выяснили, что за объект находится по пути Link.name, либо это не наша ссылка - нужно кидать мессидж пользователю
	MsgBox(cm('NeedDelete') + Link.name + cm('NeedDeletePost'),mbError, mb_OK);
	ShellExec('', 'explorer', '/select,'+Link.name, '', SW_SHOW, ewNoWait, ErrorCode);
end;











// процедура создани¤ симлинков
var SymlinkCreateError:boolean; // SymlinkCreateError=true - не продолжать интеграцию, если уже произошла критическа¤ ошибка
procedure ReplaceWithSymlink(LinkID: SYMLINK_INFO);
var LinkInfo: SYMLINK_INFO; ErrMsg:string;
begin
  if SymlinkCreateError then exit;
  LinkInfo:=LinkID;

  RemoveDir(LinkInfo.name); // удал¤ем миражную папку симлинка, созданную в секции [Dirs]
  if not CreateSymLink(LinkInfo, ErrMsg) then begin

    MsgBox(SetupMessage(msgSetupAborted) + #13#13 + ErrMsg, mbCriticalError, mb_ok);
    WizardForm.Close;  // откат
    SymlinkCreateError:=true;
    end;

end;






procedure CreateSymForPath(sor_pth: string; des_pth: string; isfolder: Boolean);
var
  FindRec: TFindRec;
  RootPath: string;
  Path: string;
  LinkNfo: SYMLINK_INFO;
begin
 
RootPath := ExpandConstant(sor_pth);

  if FindFirst(RootPath + '\*', FindRec) then
  begin
    repeat    
      
      if ((FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) and
         (FindRec.Name <> '.') and
         (FindRec.Name <> '..') then

      begin
             Path := RootPath + '\' + FindRec.Name;

             DelTree(ExpandConstant(des_pth + '\' + FindRec.Name),true,true,true);

             if (CreateDir(ExpandConstant(des_pth + '\' + FindRec.Name)))
             then begin
           
             WizardForm.StatusLabel.Caption:= ExpandConstant('Symlink from: '+'{src}' + '\' + sor_pth + FindRec.Name);
             WizardForm.StatusLabel.Caption:= ExpandConstant('To: '+ des_pth + '\' + FindRec.Name);
               end
               else
               begin
               WizardForm.StatusLabel.Caption:= ExpandConstant('Symlink not created')
               end;


             Log(ExpandConstant(des_pth + '\'  + FindRec.Name));
             Log(ExpandConstant('{src}' + '\' + sor_pth + FindRec.Name));

            
            LinkNfo.name:=ExpandConstant(des_pth + '\' + FindRec.Name);
            LinkNfo.target:=ExpandConstant('{src}' + '\' + sor_pth + FindRec.Name); 
            LinkNfo.create_dir:=isfolder;
            LinkNfo.relative:=false;
           
           ReplaceWithSymlink(LinkNfo)

        
        { LoadStringFromFile can handle only ascii/ansi files, no Unicode }
              
        
      end;
    until not FindNext(FindRec);
  end;

end;



procedure DeleteSymForPath(sor_pth: string; des_pth: string; isfolder: Boolean);
var
  FindRec: TFindRec;
  RootPath: string;
  Path: string;
begin
 
RootPath := ExpandConstant(ExtractFilePath(ExpandConstant('{uninstallexe}')) + sor_pth);


  if FindFirst(RootPath + '\*', FindRec) then
  begin
    repeat    
      
        

      if ((FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) and
         (FindRec.Name <> '.') and
         (FindRec.Name <> '..') then

      begin
             Path := RootPath + '\' + FindRec.Name;

              Log(ExpandConstant(des_pth + '\'  + FindRec.Name));

             RemoveDir(ExpandConstant(des_pth + '\' + FindRec.Name));
        
      end;
    until not FindNext(FindRec);
  end;

end;




function ParseMyDawConfig(FileName: string; Act: Boolean): Boolean;
var
  Lines: TArrayOfString;
  I: Integer;
  Line: string;
  P: Integer;
  Key: string;
  Value: string;

begin

  // MsgBox('Act: = ' + IntToStr(Integer(Act)), mbInformation, MB_OK);

  // MsgBox('FileName: = ' + FileName, mbInformation, MB_OK);

  Result := LoadStringsFromFile(FileName, Lines);
    
   //MsgBox('Act: = ' + IntToStr(GetArrayLength(Lines)), mbInformation, MB_OK); 
    

  

  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    Line := Trim(Lines[I]);
    if Copy(Line, 1, 1) = '"' then
    begin
      Delete(Line, 1, 1);
      P := Pos('"', Line);
      if P > 0 then
      begin
        Key := Trim(Copy(Line, 1, P - 1));
        Delete(Line, 1, P);
        Line := Trim(Line);
        

          Delete(Line, 1, 1);
          P := Pos('"', Line);
          if P > 0 then
          begin
            Value := Trim(Copy(Line, 1, P - 1));
            

             //MsgBox('Found key = ' + Key, mbInformation, MB_OK);
             Log(Format('Found key "%s"', [Key]));
             Log(Format('Found val "%s"', [Value]));

             if Act then
              CreateSymForPath(Key,Value,true)
             else 
              DeleteSymForPath(Key,Value,true);



         
          
          
       end;   
      end;
    end;
  end;
end;     
  




 procedure CurStepChanged(CurrentStep: TSetupStep);
 //≈сли CurStep=ssInstall, процедура вызываетс¤ только перед стартом установки,
 //если CurStep=ssPostInstall - только после завершени¤ установки,
 //CurStep=ssDone - перед выходом установщика после успешного окончани¤ установки.
begin

  if (CurrentStep = ssInstall) then //после завершени¤ установки
         



         ParseMyDawConfig(ExpandConstant('{src}\Data\Misc\config'),true);

         if not DirExists(ExpandConstant('{sd}\Mydaw')) then begin
         CreateDir(ExpandConstant('{sd}\Mydaw')); 
         end;
        // CreateSymForPath('Data\!AppData\Local\','{localappdata}', true); // Create AppData/Local
        // CreateSymForPath('Data\!AppData\Roaming\','{userappdata}', true); // Create AppData/Roaming
        // CreateSymForPath('Data\!Documents\','{userdocs}', true); // Create Docs
        // CreateSymForPath('Data\!Program Files\Common Files\','{commoncf64}', true); // Create Common Files in PF
        // CreateSymForPath('Data\!Program Files\','{commonpf64}', true); // Create Program Files
        // CreateSymForPath('Data\!Program Files (x86)\','{commonpf32}', true); // Create Program Files (x86)
        // CreateSymForPath('Data\!ProgramData\','{commonappdata}', true); // Create ProgramData
       //  CreateSymForPath('Data\!Windows\','{win}', true); // Create Windows


     
         
         
 end;





 procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of
    usUninstall:
      begin
             //MsgBox('CurUninstallStepChanged:' #13#13 'Uninstall is about to start.', mbInformation, MB_OK)
              // ...insert code to perform pre-uninstall tasks here...
            
               ParseMyDawConfig(ExpandConstant(ExtractFilePath(ExpandConstant('{uninstallexe}')) + 'Data\Misc\config'),false);

            //DeleteSymForPath('Data\!AppData\Local\','{localappdata}', true); // Delete AppData/Local
            //DeleteSymForPath('Data\!AppData\Roaming\','{userappdata}', true); // Delete AppData/Roaming
            //DeleteSymForPath('Data\!Documents\','{userdocs}', true); // Delete Documents
            //DeleteSymForPath('Data\!Program Files\Common Files\','{commoncf64}', true); // Delete Common Files in PF
            //DeleteSymForPath('Data\!Program Files\','{commonpf64}', true); // Delete Program Files
            //DeleteSymForPath('Data\!Program Files (x86)\','{commonpf32}', true); // Delete Program Files (x86)
            //DeleteSymForPath('Data\!ProgramData\','{commonappdata}', true); // Delete ProgramData
            //DeleteSymForPath('Data\!Windows\','{win}', true); // Delete Windows

      end;
    usPostUninstall:
      begin
        //MsgBox('CurUninstallStepChanged:' #13#13 'Uninstall just finished.', mbInformation, MB_OK);
        // ...insert code to perform post-uninstall tasks here...
      end;
  end;
end;









