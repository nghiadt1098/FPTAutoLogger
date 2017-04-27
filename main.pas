unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, httpsend,base64, process,lclintf, Menus,shlobj,portalForm,
  ActiveX, ComObj,windows,registry,pingsend;
const
     cae='ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789!#$%&()[<=?@]^_|0123456789!#$%&()[<=?@]^_|' ;
     flag='CH';
     Private_key=69;
type

  { TForm1 }

  TForm1 = class(TForm)
    PopupMenu1: TPopupMenu;
    SystrayIcon: TTrayIcon;
    unametext: TEdit;
    pwordtext: TEdit;
    portaltext: TEdit;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Timer1: TTimer;
    UnClkBtn: TImage;
    ClkBtn: TImage;
    procedure ClkBtnClick(Sender: TObject);
    procedure ShowForm(Sender: TObject);
    procedure Quit(Sender: TObject);
    procedure ClkBtnMouseLeave(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure OpenPortalManager(Sender:TOBject);
    procedure SystrayIconMouseUp(Sender: TObject; Button: TMouseButton);
    procedure Timer1Timer(Sender: TObject);
    procedure UnClkBtnMouseEnter(Sender: TObject);
    procedure CloseMenu(sender:TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  AppDataPath: Array[0..MaxPathLen] of Char;
  SSID:String;
  isInAlpha:Boolean;
  username,password:String;
  portalMan:String;
  portalList:Tstringlist;
  nPortal:integer;
  PopupItem:TMenuItem;
implementation

{$R *.lfm}

{ TForm1 }

function ranEncode(x:String):ansistring;//Own algorithm to encrypt data
Var
   temp:ansistring;
   i,j:longint;
   k:byte;
begin

     temp:='';
     x:=encodeStringBase64(x);
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     for i:=1 to Private_key do
         begin
              temp:=flag+temp;
              k:=random(25)+1;
              for j:=1 to length(temp) do
                  begin
                       temp[j]:=cae[pos(temp[j],cae)+k];
                  end;
         end;
     x:='';
     for i:=length(temp) downto 1 do
         x:=x+temp[i];
     temp:='';
     ranencode:=x;
end;

function ranDecode(x:String):ansistring;//Own algorithm to decrypt data
var
   st,temp:ansistring;
   i,j:longint;
   k:byte;
begin
     temp:='';
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     x:=temp;
     temp:='';
     for i:=1 to Private_key do
         begin
         for k:=1 to 25 do
                       begin
                            temp:=x;
                            for j:=1 to length(temp) do
                            temp[j]:=cae[pos(temp[j],cae)+k];
                            st:=copy(temp,1,length(FLAG));
                            if st=FLAG then begin x:=copy(temp,length(FLAG)+1,length(temp)-length(FLAG));break; end;
                       end;
         end;
     temp:='';
     for i:=length(x) downto 1 do
         temp:=temp+x[i];
     randecode:=decodeStringBase64(temp);
end;

procedure TForm1.ClkBtnMouseLeave(Sender: TObject);
begin
  //Create some small effect
  ClkBtn.Visible:=false;
end;

function getSSID:String;
var
  AStringList: TStringList;
  AProcess: TProcess;
begin
  //Check ssid using netsh WLAN show interfaces
  try
     AProcess:=TProcess.create(nil);
     AStringlist:=TStringlist.create();
     AProcess.Executable:='netsh';
     Aprocess.Parameters.Add('WLAN');
     Aprocess.Parameters.Add('show');
     Aprocess.Parameters.Add('interfaces');
     AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes,poNoConsole];

     AProcess.Execute;

     AStringlist.LoadFromStream(AProcess.Output);
     if Astringlist.count<9 then result:='Not in Wifi.'
     else
     if (pos('SSID',AStringlist.Strings[8])<>0) then
        result:=Copy(AStringlist.Strings[8],30,length(AStringlist.Strings[8])-29)
     else
         result:='Not in Wifi';
  finally
     AStringlist.free;
     Aprocess.free;
  end;
end;

procedure getAppDatapath;
begin
     AppDataPath:='';
     SHGetSpecialFolderPath(0,AppDataPath,CSIDL_LOCAL_APPDATA,false);
end;

function checkConnection:boolean;
var
   return:integer;
begin
     //ping to google.com.vn If error return will get -1
  checkConnection:=true;
  return:=pinghost('google.com.vn');
  if return=-1 then
      checkConnection:=false

end;

procedure SaveAcc;
var
   data:TStringlist;
begin
     //At first time we need to save the account to file.
    data:=TStringlist.create;
    data.add(ranencode(username));
    data.add(ranencode(password));
    data.savetofile(AppDataPath+'\.account');
    data.free;
end;

procedure LoadAcc;
var
   data:TStringlist;
begin
  //if account file is exist Load_it
  data:=TStringlist.create;
    if FileExists(AppDataPath+'\.account') then
       data.loadfromfile(AppDataPath+'\.account');
    username:=randecode(data.Strings[0]);
    password:=randecode(data.strings[1]);
    data.free;
end;

procedure SavePortalData;
var
   data:TStringlist;
begin
  //At first time we need to save the portal list.
    data:=TStringlist.create;
    data.add(ranencode(portalMan));
    data.savetofile(AppDataPath+'\.portal');
    data.free;
end;

procedure LoadPortalData;
begin
     //Load the list of Portal
    portalList:=TStringlist.create;
    if FileExists(AppDataPath+'\.portal') then
       portalList.loadfromfile(AppDataPath+'\.portal');

end;

function login(portalMan,unametext,pwordtext:String;data:TMemoryStream):boolean;
var
    injectString:Ansistring;
begin
     //This thing to bypass the magic CSRF of portal
   
   injectString:='__csrf_magic=sid%3A4d081935e8bb614e78a880650143293ee897aa04%2C1369301777&'
   +'__csrf_magic=sid%3Ad7093ce3ac57317a23c34163c627506a7eb234f2%2C1369300478&'
   +'__csrf_magic=sid%3A8d5d0afa62686d7cda3b2d1a9c8315ec894e6fa1%2C1369283024&'
   +'__csrf_magic=sid%3A453e39dfc02d36d0fb2d60de1168e87dd7975423%2C1369273016&'
   +'__csrf_magic=sid%3Aa6ba7557217602a4e1cbde0620188609080512ec%2C1369214375&'
   +'__csrf_magic=sid%3Af1e3822e610ee4cb7649255b9435e368275a3611%2C1369211376&'
   +'__csrf_magic=sid%3Ad028474708d22fdbed4b5e1c5987b66d4302d8c1%2C1369190175&'
   +'__csrf_magic=sid%3A462dbf7995b1342e1a516aa4a0807c2fa048d6dd%2C1369131132&'
   +'__csrf_magic=sid%3A30c1db18e28eb4c4b6b7a2b4be85107712c25647%2C1369043456&'
   +'__csrf_magic=sid%3A82a31585ce588e6230b5c8a12f5e755497d74ef8%2C1369041021&'
   +'__csrf_magic=sid%3A9652898b27ab4c916b5e8ed2d90c0eae43889ccc%2C1368438450&'
   +'__csrf_magic=sid%3Ad14133c21cd4fb303647e25c1bfe2e7036fadc0a%2C1368415003&'
   +'__csrf_magic=sid%3A9d73666ad6ad842423cc292094e97e5fb83b2ba8%2C1368169443&'
   +'__csrf_magic=sid%3A7a3e553af6e88f92de4394ed870a07af5522e3d2%2C1368156691&'
   +'__csrf_magic=sid%3Afbd81f19cab1ffedd3e512b1e7bbd190dd50ce3e%2C1368072090&'
   +'__csrf_magic=sid%3A41c0a58dc1cdca183e17a3b8a2d1bd630f42a879%2C1364978702&'
   +'__csrf_magic=sid%3A7465716204ec89c1e60cf98980d358666fb7fdf6%2C1363853126&'
   +'__csrf_magic=sid%3A3d8c43a241925aee09ff44e791fd633f7250b747%2C1363770997&'
   +'__csrf_magic=sid%3Af57485082db01c0ce1fd3af021f5c1a575b0ad11%2C1363603238&'
   +'__csrf_magic=sid%3A077412139b4c4f126af45760a9563bc5707bf191%2C1362748829&'
   +'__csrf_magic=sid%3A5ddbabe51849d39e579063135444d8056c84c533%2C1362746343&'
   +'__csrf_magic=sid%3A2bd762876c168c2898a0c37f740abe035ad37993%2C1362732925&'
   +'__csrf_magic=sid%3A53c486ec00bcc03b53cb3aa1844784708e4592bb%2C1362715048&'
   +'__csrf_magic=sid%3Aa6ff345b691b2f2e091c2117bcb1ab03b2a51bb9%2C1349415940&'
   +'__csrf_magic=sid%3A208acbaf72d72073e299445c84dd5024ea773674%2C1349414979&'
   +'redirurl=&auth_user='+unametext+'&auth_pass='+pwordtext+'&accept=.';

   result:=HttpPostURL(portalMan,injectString,data);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
     //Prevent user resize
    Form1.Width:=image1.width;
    Form1.height:=image1.height;
end;

procedure TForm1.SystrayIconMouseUp(Sender: TObject; Button: TMouseButton);
begin
    if (Button=mbRight) then
     systrayicon.PopUpMenu.PopUp;

end;

procedure TForm1.ShowForm(Sender:TObject);
begin
    Form1.show;
    //Systrayicon.hide;
    timer1.Enabled:=false;
    if FileExists(AppDataPath+'\.account') then
       SysUtils.DeleteFile(AppDataPath+'\.account');
    if FileExists(AppDataPath+'\.portal') then
       SysUtils.DeleteFile(AppDataPath+'\.portal');
end;

procedure Tform1.Quit(Sender:TObject);
begin
  Systrayicon.Hide;
  Application.Terminate;
end;

procedure Tform1.OpenPortalManager(sender:TObject);
begin
      Form2.show;
end;

procedure Tform1.CloseMenu(sender:TObject);
begin
      popupMenu1.close;
end;

procedure CreateStartupShortCut(Target, TargetArguments, ShortcutName: string);
var
  IObject: IUnknown;
  ISLink: IShellLink;
  IPFile: IPersistFile;
  PIDL: PItemIDList;
  InFolder: array[0..MAX_PATH] of Char;
  TargetName: String;
  LinkName: WideString;
begin
  //Creates an instance of IShellLink
  IObject := CreateComObject(CLSID_ShellLink);
  ISLink := IObject as IShellLink;
  IPFile := IObject as IPersistFile;

  ISLink.SetPath(pChar(Target));
  ISLink.SetArguments(pChar(TargetArguments));
  ISLink.SetWorkingDirectory(pChar(ExtractFilePath(Target)));

  // Get the desktop location
  SHGetSpecialFolderLocation(0, CSIDL_STARTUP, PIDL);
  SHGetPathFromIDList(PIDL, InFolder);
  LinkName := InFolder + PathDelim + ShortcutName+'.lnk';

  // Create the link
  IPFile.Save(PWChar(LinkName), false);
end;

Procedure EnableProxy;
var
Reg : TRegistry;
begin
  try
     Reg := TRegistry.Create;
     Reg.RootKey:=HKEY_CURRENT_USER;
     if not (Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\InternetSettings',False)) Then
        if not Reg.CreateKey('\Software\Microsoft\Windows\CurrentVersion\InternetSettings') then
    // process here error 1
       else
           if not (Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\InternetSettings',False)) Then
      // process here error 2
         else
      begin
        // add your entries
        Reg.WriteBool('ProxyEnable',True);

      end;
     Reg.CloseKey;
  finally
       Reg.Free;
  end;

end;

Procedure DisableProxy;
var
Reg : TRegistry;
begin
  try
     Reg := TRegistry.Create;
     Reg.RootKey:=HKEY_CURRENT_USER;
     Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\InternetSettings',False);
     Reg.WriteBool('ProxyEnable',False);
     Reg.CloseKey;
  finally
     Reg.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);

begin
   isInAlpha:=false;

  //Create startup shortcut.
    CreateStartupShortCut(ParamStr(0),'','AutoLogger');
    //create Appdata folder
     getAppDatapath;

     //Set tray icon
     systrayicon.PopUpMenu:=PopupMenu1;

      //Set tray Popup menu
      PopupItem:=TMenuitem.create(Form1);
      Popupitem.Caption:='Show Login form';
      popupitem.OnClick:=@ShowForm;
      popupMenu1.Items.Add(PopupItem);

      PopupItem:=TMenuitem.create(Form1);
      Popupitem.Caption:='Open Portal Manager';
      popupitem.OnClick:=@OpenPortalManager;
      popupMenu1.Items.Add(PopupItem);

      PopupItem:=TMenuitem.create(Form1);
      Popupitem.Caption:='Quit.';
      popupitem.OnClick:=@Quit;
      popupMenu1.Items.Add(PopupItem);

      PopupItem:=TMenuitem.create(Form1);
      Popupitem.Caption:='Close menu';
      popupitem.OnClick:=@CloseMenu;
      popupMenu1.Items.Add(PopupItem);

     //it can be set in Object Inspector but i put this in here, for sure.
     timer1.Enabled:=false;

     AppDataPath:=AppDataPath+'\fptudomlogger';
     if not DirectoryExists(AppDataPath) then
        CreateDir(AppDataPath);
     form1.Show;
     label3.caption:=getssid;

     if FileExists(AppDataPath+'\.account') then
        begin //if it's account already
             timer1.Enabled:=true;
             form1.hide;
             //Show tray
             SystrayIcon.Show;
             //Load Information
             loadacc;
             LoadPortalData;
        end
     else //Register new account.
         form1.show;

end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
   i:integer;
   temp:TMemoryStream;
begin

 //Update Portal data every 2s
 loadPortalData;

  if form1.visible=false then
   begin
     if (checkConnection=false) and (isInAlpha=false) then
         begin
           //Test each portal in list
           for i:=0 to portalList.Count-1 do
                 begin
                      temp:=TmemoryStream.create;
                      portalMan:=randecode(portalList.Strings[i]);
                      login(portalMan,username,password,temp);
                      temp.free;
                 end;
         end;
     if (getSSID='DH FPT') and (isInAlpha=false) then
        begin
            showmessage('You are in Alpha');
            isInAlpha:=true;
        end;
     if (isInAlpha = true ) and (getSSID<>'DH FPT') then
        begin
          isinalpha:=false;
        end;
   end;

end;

procedure NonFillRect(CVas:TCanvas;X1,y1,x2,y2:integer);
begin
     Cvas.Line(X1,y1,x1,y2);
     Cvas.Line(X1,y1,x2,y1);
     Cvas.line(X2,y2,X1,y2);
     Cvas.line(x2,y2,x2,y1);
end;

procedure TForm1.ClkBtnClick(Sender: TObject);
var
  returnStream:TMemoryStream;
  statusString:TStringlist;
  return:boolean;
begin
  //Get data from text
  username:=unametext.text;
  password:=pwordtext.text;
  portalMan:=portaltext.text;

  //Some effect on event onClick
  image1.Canvas.Pen.Color:=clBlue;
  NonFillRect(image1.Canvas,ClkBtn.left-5,ClkBtn.top-5,ClkBtn.left+ClkBtn.width+5,ClkBtn.top+ClkBtn.height);

  //Stream contain data from portal
  returnStream:=TMemoryStream.create;
  statusString:=TStringlist.create;

  //login
  return:=login(portalMan,username,password,returnStream);

  if return then//If connect success
     begin
       //Convert data Stream to TStringlist
       statusString.LoadFromStream(returnStream);

       if (statusString.Count>0)  then
             label1.Caption:=copy(statusString.Strings[128],51,length(statusString.Strings[128])-61)
       else
           begin
                label1.caption:='Login Successful';

                //Save Account & portal
                SaveAcc;
                SavePortalData;

                //Show message
                Showmessage(label1.caption);

                //Start Automatic mode
                timer1.Enabled:=true;
                form1.hide;
                Systrayicon.Show;
           end;
     end
  else
      label1.caption:='Not in FPTU Dom or Not connected to network.'+chr($0a)+'Please check your internet connection.';

   //Some effect on event onClick
   image1.Canvas.Pen.Color:=RGB(238,238,238);
   NonFillRect(image1.Canvas,ClkBtn.left-5,ClkBtn.top-5,ClkBtn.left+ClkBtn.width+5,ClkBtn.top+ClkBtn.height);

   //Clear memory
   returnStream.Free;
   statusString.free;


end;

procedure TForm1.UnClkBtnMouseEnter(Sender: TObject);
begin
  //Some effect
  ClkBtn.Visible:=true;
end;

end.

