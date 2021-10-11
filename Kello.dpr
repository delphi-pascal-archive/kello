//Немного оптимизации
{$R-} {проверка диапазона}
{$S-} {проверка стека}
{$A+} {"выравнивание слов"}
program Kello;

uses
  Windows,
  Messages,
  SysUtils,
  ShlObj;

{$R *.res}

const
 StdInterval = 1000;
 AppData = $001A;//ID для ApplicationData
 Alpha = 220;//прозрачность..

 CF = $100;  //Фон..

  //палочки циферок..
 NUM:Array [0..9, 0..9] of Byte =  ((6,4,2,3,12,14,13,4,0,0),{0}
                                    (4,15,13,14,2,1,0,0,0,0),{1}
                                    (6,4,1,3,9,10,13,15,0,0),{2}
                                    (4,1,3,7,9,13,0,0,0,0),{3}
                                    (4,1,7,9,3,15,0,0,0,0),{4}
                                    (6,3,1,7,9,12,14,13,0,0),{5}
                                    (7,3,2,4,13,14,12,9,7,0),{6}
                                    (4,4,1,3,8,14,0,0,0,0),{7}
                                    (8,1,3,6,10,13,15,12,4,1),{8}
                                    (6,13,14,12,3,1,7,9,0,0));{9}

 PenCount = 6;
 BrushCount = 2;
 AppName = 'Clock 8.0';

var
 App: HWND; //Хендл приложения
 Wnd: HWND; //локальный хендл
 F: Integer; //хэндл CFG файла.
 Msg : TMSG; //сообщения

 WP:TWindowPlacement; //Описалово положения окна..
 WC: TWndClass; //Описалово свойств окна..

 MainDC: HDC;  //Полотно..

 //Цвета..
 CM :Integer; //Яркий
 CD :Integer; // Полуяркий
 CB :Integer; //Тусклый

 //Наборы карандашей и кисточек..
 Pen: Array [0..PenCount] of HPen;
 Brush: Array [0..BrushCount] of HBrush;

 //Переменные..
 WDS,WDX,WDL,WDY,DL,SX,SY,PosY,PosX,DW,NW,X0,Y0,W,SizeX,SizeY,ScrX,ScrY:Integer;

 //Хранилище координат..
 TX:Array  [0..15] Of Integer;
 TY:Array  [0..15] Of Integer;

 DX:Array  [0..1] Of Integer;
 DY:Array  [0..1] Of Integer;

 //Прочее..
 Path:String;
 Buff:Array [0..10] of Integer;

 DrawAll:Boolean = True;

procedure ShutDown; //процедура выхода из программы..
Var
 I:Byte;
Begin
 //вырубаем надоевший будильник..
 KillTimer(Wnd,1);

 //Возвращаем авторские кисть и карандаш..
 SelectObject (MainDC, Brush[0]);
 SelectObject (MainDC, Pen[0]);

 //Выкидываем свои кисти и карандаши..
 For I := 1 To PenCount do
  DeleteObject(Pen[I]);

 For I := 1 To BrushCount do
  DeleteObject(Brush[I]);

  //Выкидываем полотно..
 ReleaseDC (Wnd, MainDC);

  //Запоминаем место на столе, где стоит планшет..
  GetWindowPlacement(Wnd,@WP);
  Buff[0] := WP.rcNormalPosition.Left;
  Buff[1] := WP.rcNormalPosition.Top;
  Buff[2] := W;

  //Пишем..
  If (not FileExists(Path)) Then
    F := FileCreate(Path)
   Else
    F := FileOpen(Path,$41);
   If (F <> -1) Then
    begin
     FileWrite(F,Buff,SizeOf(Buff));
     FileClose(F);
    end;

 //убираем планшет со стола..
 If (not DestroyWindow(Wnd))Then
   MessageBox(0, 'Unable to Window!', AppName, MB_OK or MB_ICONERROR);
 //Отменяем сертификацию планшета..
 If UnRegisterClass(AppName, App) = False Then
   MessageBox(0, 'Unable to unregister Window Class!', AppName, MB_OK or MB_ICONERROR);

 ExitProcess(App); //всем пока..
 Halt;//на всякий пожарный..
end;

//Звенит будильник, пора рисовать..
procedure OnTimer;
 Function IsScr:Boolean;
 Var
  Running: LongBool;
 begin
   Result:= False;
   If( SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @Running, 0) )then
      Result:= Running;
  end;

Const
 DotW:Array [0..3] Of Byte =(0,0,1,1);
 //Приводим в порядок нумерацию дней недели..
 WDD:Array [0..6]of Byte  =(1,2,3,4,5,6,0);
Var
 SystemTime: TSystemTime;
 TA:Array [0..3] of Word;//хранилище цифирок..
 I, J:Byte;
Begin
  GetLocalTime(SystemTime);

  TA[0] := Trunc(SystemTime.wHour/10);
  TA[1] := SystemTime.wHour - TA[0]*10;
  TA[2] := Trunc(SystemTime.wMinute/10);
  TA[3] := SystemTime.wMinute - TA[2]*10;

 //Проверка - авось ScreenSaver пашет..
If (not IsScr) Then
 begin//1

 //Плещем на полотно растворитель..
 If (SystemTime.wSecond in [0,1]) Or (DrawAll) Then
  begin
   DrawAll := False;
   SelectObject(MainDC,Brush[1]);
   ExtFloodFill(MainDC,X0,Y0,CM,FloodFillBorder);

   //и начинаем творить, надышавшись паров..

   //Проводим тонкую полоску секунд..
   SelectObject(MainDC,Pen[4]);
   MoveToEx(MainDC,SX,SY,Nil);
   LineTo(MainDC,SX + Trunc(W * 59 / 2),SY);

  //Рисуем точки..
  For J := 0 TO 1 Do
   begin//2
    SelectObject(MainDC,Pen[3]);
     MoveToEx(MainDC,DX[J],DY[J],nil);
     LineTo(MainDC,DX[J],DY[J]-DL);

    SelectObject(MainDC,Pen[2]);
     MoveToEx(MainDC,DX[J],DY[J],nil);
     LineTo(MainDC,DX[J],DY[J]-DL);
   end;//2

 //Переходим к цифрам..
  For J := 0 TO 3 Do
   begin//4
   //TA[J] := 8;  //для тестов
    SelectObject(MainDC,Pen[3]);
    MoveToEx(MainDC,TX[Num[TA[J],1]]+NW*J+DW*DotW[J],TY[Num[TA[J],1]],nil);
   For I := 2 To Num[TA[J],0]+1 Do
     LineTo(MainDC,TX[Num[TA[J],I]]+NW*J+DW*DotW[J],TY[Num[TA[J],I]]);

    SelectObject(MainDC,Pen[2]);
    MoveToEx(MainDC,TX[Num[TA[J],1]]+NW*J+DW*DotW[J],TY[Num[TA[J],1]],nil);
   For I := 2 To Num[TA[J],0]+1 Do
     LineTo(MainDC,TX[Num[TA[J],I]]+NW*J+DW*DotW[J],TY[Num[TA[J],I]]);
   end;//4

    //Рисуем дни недели..
  For I := 0 to 6 do
   begin//5
    MoveToEx(MainDC,WDX + I*WDL,WDY,nil);
   If SystemTime.wDayOfWeek = WDD[I]
    Then SelectObject(MainDC,Pen[6])
     Else SelectObject(MainDC,Pen[5]);

    LineTo(MainDC,WDX + (I + 1)*WDL - WDS,WDY);
   end;//5
  end;//2

   //а вот секунды надо рисовать каждый раз..
   SelectObject(MainDC,Pen[5]);
   MoveToEx(MainDC,SX,SY,Nil);
  If SystemTime.wSecond > 0 Then
   LineTo(MainDC,SX + Trunc(W * SystemTime.wSecond / 2),SY);

 end;//1
End;

//Изменение размеров планшета..
Procedure ResizePaint;
Var
 P :Byte;
Begin
 // Вытираем полотно тряпкой..
  SelectObject(MainDC,Brush[2]);
  ExtFloodFill(MainDC,X0,Y0,01,FloodFillBorder);
  //Рисуем рамочку..
  SelectObject(MainDC,Brush[1]);
  SelectObject(MainDC,Pen[1]);
  RoundRect(MainDC,0,0,SizeX, SizeY, DW,DW);

  //Перетачиваем карандаши..
  Pen[1] := CreatePen(PS_Solid,1,CM);       //рамка
  Pen[2] := CreatePen(PS_Solid,W or 1,CM-1);     //цифры..
  Pen[3] := CreatePen(PS_Solid,(W+2) or 1,CB-1);   //Обводка..
  Pen[4] := CreatePen(PS_Solid,(W Shr 2) Or 1,CD);   //тонкая секунд

  //Чистим кисточки..
  P:= Trunc(W * 0.8)  Or 1;
  Pen[5] := CreatePen(PS_Solid,P,CD);   // Дни недели..
  Pen[6] := CreatePen(PS_Solid,P,CM-1);   // Дни недели..

  //чтобы не забыть перерисовать все по будильнику..
  DrawAll := True;
End;

//Математический модуль..
Procedure Recalc;
Var
 I,J,P:Byte;
Begin
 //Расчет координат..
 // Цифры..
 NW := W*7;
 DW := W*3;
 X0 := 3*W;
 Y0 := 5*W;
 //Полотно..
 SizeX := 4*NW + 6*W;
 SizeY := 18*W;
 //Дни недели..
 WDY := Trunc(15.7*W);
 WDL := Trunc(4.4*W);
 WDS := Trunc(1.7*W);
 WDX := (SizeX - (7*WDL - WDS)) Shr 1;
//Секунды..
 SX := (SizeX - Trunc(W * 59 / 2)) Shr 1;
 SY := Trunc(2.3*W);
//Точки..
 DX[0] := X0 + 2*NW ;
 DX[1] := DX[0];
 DY[0] := Y0 + 2*W + 1;
 DY[1] := DY[0] + 4*W;

 DL := Trunc(W * 0.75);
If DL < 2 Then DL := 2;

 P:=1;

//Генерим координатную сетку 3 на 5..
 For J := 0 to 4 do
  For I := 0 To 2 Do
   begin
    TX[P] := X0 + I*W*2;
    TY[P] := Y0 + J*W*2;
    P := P+1;
   end;

    //оцениваем размеры стола..
  ScrX := GetSystemMetrics(SM_CXSCREEN);
  ScrY := GetSystemMetrics(SM_CYSCREEN);

 //Если стол маловат..
 If (PosX + SizeX ) > ScrX Then PosX := ScrX - SizeX;
 If (PosY  + SizeY + 32) > ScrY Then Posy := ScrY - SizeY - 32;

 //или планшет стоял криво..
 If PosX < 0 Then PosX := 0;
 If PosY < 0 Then PosY := 0;

End;

//Обработчик сообщений..
Function WindowProc(hWnd, Msg, wParam, lParam: longint): longint; stdcall; //обработчик сообщений
Begin
 Result := DefWindowProc(HWND, Msg, wParam, lParam);
Case Msg of
//Меняем размер..
 WM_MOUSEWHEEL:
 If (wParam And MK_Control <> 0) Then
  begin
  If wParam > 0 Then W := W + 1 Else
   If W > 3 Then  W := W - 1;
   GetWindowPlacement(Wnd,@WP);
   PosX := WP.rcNormalPosition.Left;
   PosY := WP.rcNormalPosition.Top;
   Recalc;
    //Выравнивание правого края..
   If ((PosX + SizeX) < WP.rcNormalPosition.Right) And
    (WP.rcNormalPosition.Right <= ScrX) Then
      PosX := WP.rcNormalPosition.Right - SizeX;
   MoveWindow(Wnd,PosX,PosY,SizeX,SizeY,False);
   ResizePaint;
   OnTimer;
  end;
 //Нас кажеться хотят убить..
 WM_DESTROY,  WM_RBUTTONUP:ShutDown;
 //Таскание по левой кнопке..
 WM_LBUTTONDOWN:
   Result := DefWindowProc(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, lparam);
 WM_LBUTTONUP:
  Result := DefWindowProc(hwnd, WM_NCLBUTTONUP, HTCAPTION, lparam);
end;//Case 1
End;

//Собственно сама программа начинается тут..
Procedure Body;
 function GetSpecialPath(CSIDL: word): string;
 var
  S: string;
 begin
  SetLength(S, MAX_PATH);
 If (not SHGetSpecialFolderPath(0, PChar(s), CSIDL, true))
 then S := '';
  result := PChar(s);
 end;

Var
 I:Byte;
 MyParam,TempStr:String;
Begin
//Проверка на шизофрению..
 If (FindWindow(AppName, AppName)<>0) then
  begin
   MessageBox(0,'Program is already running!',AppName,$10);
   Exit;
  end;
//Осматриваемся, ищем листик с настройками..
 Path := GetSpecialPath(AppData);
 If (Path <> '') Then
  begin
   If (not DirectoryExists(Path + '\Kello')) Then
    CreateDir(Path + '\Kello');
    Path := Path + '\Kello\Kello.Pos';
  end
  Else
   Path := ExtractFilePath(Paramstr(0)) + 'Kello.Pos';

  //Пытаемся прочесть настройки..
 If (FileExists(Path)) Then
  begin
   F := FileOpen(Path,0);
  If (F <> -1) Then
   begin
    FileSeek(F,0,0);
    FileRead(F,Buff,SizeOf(Buff));
    FileClose(F);
    PosX := Buff[0];
    PosY := Buff[1];
    W := Buff[2];
   If W < 3 Then W := 3;
   end;
  end
 Else //Если листик не нашелся, придумываем цифры на ходу..
  begin
   PosX := 100;
   PosY := 100;
   W := 3;
  end;

 //Вызываем на помощь математический модуль..
 Recalc;

//Ищем главный цвет в командной строке..
 If ParamCount > 0 Then
  begin
   TempStr := ParamStr(1);
   MyParam := '';
  For I := 1 To Length(TempStr) Do
   If TempStr[I] in ['0'..'9'] Then
    MyParam := MyParam + TempStr[I];
  end;

  //Прикидываем тональность нашего шедевра..
  CM := StrToIntDef(MyParam,$FF88);
  CD := (CM And $FF) Shr 1 + (((CM Shr 8) And $FF) Shr 1) SHL 8
        + (((CM Shr 16) And $FF) Shr 1) SHL 16;
  CB := (CM And $FF) Shr 2 + (((CM Shr 8) And $FF) Shr 2) SHL 8
        + (((CM Shr 16) And $FF) Shr 2) SHL 16;

 If CM = 0 Then CM := $100;
 If CD = 0 Then CD := $100;
 If CB = 0 Then CB := $100;

 //начинаем танцы с бубном вокруг планшета..
  App := hInstance;
 With WC do
  begin
   Style := 0; //стиль класса
   hIcon := LoadIcon(App, 'MAINICON'); //иконка программы
   lpfnWndProc := @WindowProc; //назначение обработчика сообщений
   hInstance := App;
   hbrBackground := 0; //цвет окна
   lpszClassName := AppName; //класс окна
    hCursor := LoadCursor(0,IDC_Arrow); //активный курсор
  end;

//сертифицируем планшет как класс..
 If (RegisterClass(WC) = 0) Then
  begin
   MessageBox(0,'Window Class registration failed!',AppName,$10);
   Exit;
  end;

//Пытаемся положить планшет на стол..
  Wnd := CreateWindowEx(WS_EX_TOPMOST
                          or WS_EX_LAYERED or WS_EX_TOOLWINDOW,
                           AppName,
                           AppName,
                           WS_SYSMENU or
                           WS_VISIBLE or WS_POPUP,
                           PosX, PosY, SizeX, SizeY, 0, 0, App, nil);

 SetLayeredWindowAttributes(Wnd,0,Alpha, LWA_ALPHA or LWA_COLORKEY);

 If (Wnd = 0) Then
  begin
   MessageBox(0,'Window Creating!',AppName,$10);
   UnregisterClass(AppName,App);
   Exit;
  end;

//Достаем полотно, кисти и карандаши..
 MainDC := GetDC(Wnd);

 Pen[1] := CreatePen(PS_Solid,1,CM);       //рамка
 Brush[1] := CreateSolidBrush(CF);//фон..
 Brush[2] := CreateSolidBrush(0);//растворитель..

 //Откладываем кисть и карандаш, которые шли с полотном в комплекте..
 Brush[0] := SelectObject(MainDC,Brush[1]);
 Pen[0] := SelectObject(MainDC,Pen[1]);

 //Приводим все в готовность..
 ResizePaint;

 OnTimer;//Рисуем для пробы..

//Ставим будильник, чтобы не забыть порисовать позже..
  If SetTimer(Wnd, 1, StdInterval, @OnTimer) = 0 Then ShutDown;

 //Дремлем, посматривая на проплывающие сообщения..
While(GetMessage(Msg, Wnd, 0, 0)) do
 begin
  TranslateMessage(Msg); //приём сообщений..
 // If (GetAsyncKeyState(vk_Escape ) <> 0) then ShutDown;
  DispatchMessage(Msg); //удаление сообщений из очереди
 end;
End;

BEGIN

 Body;

END.

