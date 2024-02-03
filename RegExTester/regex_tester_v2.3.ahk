#Requires AutoHotkey v2.0
ScriptName := "AHK RegexTester"
Version := "v2.3"
;#include <darkmodegui> ;comment for no darkmode
;Changed to include darkmodegui and created credit for https://github.com/jNizM/jNizM
/*
 Original Design by toralf
 www.autohotkey.com/forum/topic17844.html
 Redesign and conversion by TacocaT
 Eric Clark contratempts@gmail.com

  Version history:
  V2)  Updated to AHK V2.0 for longevity
  V2.2)  Initial Release of the regex

*/

/**
 * Init Global vars 
 */

global GuiH := 653
global GuiW := 900
global helpW := 410
global CT_H := 12   ;in rows
global CT_W := GuiW - 20  ;in nums
global GuiX := ""
global GuiY := ""
global SettingsMap := Map()
global csizes := Map()
global IniFile := 'regexproject.ini'

fontsz := '9,10,11,12,13,14,15,16,17,18'
fontsizes := StrSplit(fontsz, ',')

SplitPath(A_ScriptFullPath, , , , &inifilename)
HelpFile := FileRead('regex_helpfile.txt')

SeparatorChars := '@µ§&#°¤¶®©¡¦'
DefaultSeparator := '@'
DefaultRegex := "The (.*?) (?P<Name>.*?) (.*?) (.*?) the"
DefaultHaystack := "The quick brown fox jumps over the street 2 times for 4 days"
Separator := '@'
regexstr := IniRead(IniFile, "RegEx", 'Regexvals', DefaultRegex)

/*
parse the regexstr and return the list
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

loop parse regexstr, '@'
{
  if A_LoopField != ""
    list .= A_LoopField '@'
}

list := Trim(list, Separator)
Rlist := StrSplit(list, Separator)
list := ""
HayStack := IniRead(Inifile, "HayStack", "HayStack", DefaultHaystack)

/*
Initialize Gui
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

guiOpen

global rGui := Gui('+Resize')
SetWindowAttribute(rgui, true) ;sets darkmode as initial mode
rgui.SetFont('s12 cffffff')
/*
  initialize the tabs
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

global tablist := ["*Match", "Replace", "Options"] ;used for renaming the tabs later
C_Tab := rGui.AddTab("section +border buttons r3 vTabRegexType w" CT_w, tablist)
C_Tab.UseTab

/*
Funct
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
Rhelpt := rgui.AddText('Section ys vRegexhelpT w400', 'Quick Reference')
RHelp := rgui.AddEdit(' xs vRegexHelp wp +vScroll h650', HelpFile)

/*
Tab1
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

C_Tab.UseTab(1)
rGUi.AddText('Section vTM_Match', "Regext Match")
rGui.AddText('Section vTM_OutVar', 'OutputVar')
C_EM_OutVar := rgui.AddEdit("ys vEM_OutVar", "Out")
rGui.AddText("ys vTM_StartPos ys", "StartingPos")
C_E_Spos := rGui.AddEdit("ys vEM_StartPos", 1)
rgui.AddText('ys vTM_SubPatN', 'SubPattern')
C_E_SubPatN := Rgui.AddEdit("ys vEM_SubPatN", 5)

/*
Tab2
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

C_Tab.UseTab(2)
rGUi.AddText('Section vTR_Label', 'RegexReplace')
rGui.AddText("ys vTR_StartPos", "StartingPos")
C_ER_StartPos := rGui.AddEdit('ys vER_StartPos', '1')
C_ER_StartPos.OnEvent("Change", EvalRegX)
rgui.addText('ys vTR_Count', 'Count')
C_ER_Count := rgui.AddEdit('ys vER_Count', 1)
rGui.AddText("ys vTR_Limit", 'Limit')
C_ER_Limit := rGui.AddEdit('ys wp vER_Limit', -1)
rGui.AddText("Section xs vTR_Repl ", "Replacement")
C_ER_Repl := rGui.AddEdit("ys w" CT_W - 150 " vER_Repl", "$1 $2")

/*
Tab3
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
cbw := 200 ;cbw is used for positioning.
C_Tab.UseTab(3)
rGui.MarginX := 1
rGui.MarginY := 5
C_O_L_FontSize := rGUi.AddText('section vFSText w' (CT_W / 12), 'Font Size')
C_O_FontSize := rGui.AddDropDownList('ys w50', fontsizes)
C_TSpacer1 := rGUi.AddText('vSpace1 ys w' CT_W / 8 - 5, '')
C_O_Darkmode := rGui.AddCheckbox('w' cbw ' ys', 'Darkmode')
;had to put this here to push the tabs down
C_TSPACER := rgUI.AddText('vSpacer h60 section xs wp', '=========================================') ;spacer for the_Tab.UseTab()
C_Tab.UseTab()

/*
Main Controls
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

CT_T_RX := rgui.AddText("Section xs vT_Rx", 'Needle (RegEx)`nNote: Use \n instead of ``n, etc.')
CT_T_Rx2 := rGui.AddText("Section vT_Rx2 w" CT_W - 63, 'Unlike in AHK quotes (") must not be escaped.')
/*
Store Buttons
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
Global C_CB_RegEx_Add := rgui.AddButton('vBtnStoRegex ys w20 h20', '+')
global C_CB_Regex_put := rgui.AddButton('vBTNPutRegex ys w20 h20', '^')
global C_CB_Regex_Min := rgui.AddButton('vBtnDelRegex ys wp hp', '-')

rgui.MarginX := 20
rgui.marginY := 5
/*
Regex Boxes
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
global C_CB_Regex_Curr := rGui.AddEdit('Section xs vCB_Regex_Curr w' CT_W, DefaultRegex)
global C_CB_RegEx := rGui.AddComboBox("Section xs r10 vCB_Regex w" CT_W, Rlist)
/*
Haystack and Result
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
CT_Haystack := rGui.AddText('section vT_Haystack w' CT_W, "Haystack")
C_Haystack := rGui.AddEdit("wp Section r8 vE_Haystack", HayStack)
CT_REsult := Rgui.AddText('wp Section vT_Result', "Result")
C_Result := Rgui.AddEdit("wp r8 vE_Result")

/*
Lower Buttons AutoUpdate and ShowHelp
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

C_B_STO := rGui.AddButton('Section vBtnStRegex w' (CT_W / 3), "Store")
C_B_COP := rGui.AddButton('ys vBtnCopytoCB w' (CT_W / 3), "Copy")
C_Auto := rgui.AddCheckbox('vAutoUpdate ys +Checked', "AutoUpdate")
C_Help := rgui.AddCheckbox('vShowHelp +Checked', 'ShowHelp')

/*
ShowGui
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/
SetWindowAttribute(rgui, True)
SetWindowTheme(rGui, True)
rGui.Title := ScriptName ' ' Version
rgui.show('Autosize') ;'w' GuiW 'h' guiH)

EvalRegX(rgui, '')

ControlFocus(C_CB_RegEx_Curr) ;sets the main focused control to the current regex

/*
Events
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

rgui.OnEvent('Close', GuiClose)
C_Tab.OnEvent('Change', Tab_Function)
C_O_FontSize.OnEvent('Change', FontSize)
C_EM_OutVar.OnEvent("Change", EvalRegX)
C_E_Spos.OnEvent("Change", EvalRegX)
C_E_SubPatN.OnEvent("Change", EvalRegX)
C_ER_Count.OnEvent('Change', EvalRegX)
C_O_Darkmode.OnEvent("Click", darkmodetoggle)
C_ER_Limit.OnEvent("Change", EvalRegX)
C_ER_Repl.OnEvent("Change", EvalRegX)
C_Result.OnEvent("Change", EvalRegX)
C_Haystack.OnEvent("Change", EvalRegX)
C_CB_Regex_Curr.OnEvent('Change', EvalRegX)
C_Help.OnEvent('Click', showhelp_func)
C_CB_RegEx_Add.OnEvent('Click', BtnStoreRegex)
C_CB_Regex_Min.OnEvent('Click', BtnDeleteRegex)
C_CB_Regex_put.OnEvent('Click', pop)
C_B_STO.OnEvent("Click", BtnStoreRegex)
C_B_COP.OnEvent("Click", BtnCopyToCb)
C_Auto.OnEvent('Click', EvalRegX)

FontSize(*) {
  for cntrl in rGui
    cntrl.SetFont('s' C_O_FontSize.text)

  rgui.SetFont('s' C_O_FontSize.text)
  rgui.Submit(false)
  rGui.Show('AutoSize')
}

darkmodetoggle(toggle, *)
{
  if toggle.value = 1 {
    SetWindowAttribute(rGui)
    SetWindowTheme(rGui)
    color := 'white'

  }

  if toggle.value = 0
  {
    SetWindowAttribute(rGui, False)
    SetWindowTheme(rGUi, False)
    color := 'black'
    Rgui.SetFont('c000000')
  }
  for cntrl in RGui
    cntrl.SetFont('c' color)
}


/*
Showhelp function
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/


Tab_Function(*) {
  global tablist
  loop tablist.Length
    C_Tab.SetTabText(A_INdex, StrReplace(tablist[A_Index], '*', ''))

  C_tab.SetTabText(c_tab.value, "*" c_tab.Text)
  EvalRegX(rgui, "")
}


pop(*) {
  C_CB_Regex_Curr.value := C_CB_RegEx.text
  EvalRegX(C_CB_regex, "")
  C_CB_RegEx.choose(0)
  ControlFocus(C_CB_Regex_Curr)
}

EvalRegX(guibj, info, *) {
  ;msgbox guibj.name
  result := ""
  str := ""
  pre := ""

  if C_Auto.value = 0
    return
  gl := ""
  if pre != ')'
    gl := pre

  if C_tab.value = 2 {
    CT_REsult.value := 'Regex Replace:   ' gl C_CB_Regex_Curr.value ', ' C_ER_Repl.value ' , ' C_ER_Count.value ' , ' C_ER_StartPos.value '`n'
    result := ""
    try {
      str := RegExReplace(C_Haystack.value, gl C_CB_Regex_Curr.value, C_ER_Repl.value, &Count := C_ER_Count.value, C_ER_StartPos.value)

    }
    catch
    {
      result .= A_LastError
    }
    result .= str
  }
  if C_tab.value = 1
  {
    CT_REsult.value := 'Result:  MatchMode enabled [' C_E_SubPatN.value '] SubPatterns Requested'

    i := 0
    try
      len := RegExMatch(C_Haystack.value, C_CB_Regex_Curr.value, &OutVar := C_EM_Outvar.value, C_E_Spos.value)
    loop C_E_SubPatN.value
    {
      try {
        result .= 'Out[' A_Index '] = ' OutVar[A_Index] ' `n'
      }
      catch as e
        result .= 'Out[' A_Index '] = [Error]' '`n'
    }

  }

  C_Result.value := result
  rgui.Submit(false)
}

/*
 Gui Buttons Etc
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/


BtnCopyToCb(GuiObj, Item, *) {
  if C_tab.value = 0  ;Match
  {
    str := 'val := RegexReplace(' haystack.value, '"(' C_CB_Regex_Curr.value ')"', '"(' C_ER_Repl.value ')"', C_ER_Count.value, C_ER_Limit.value := -1, C_ER_StartPos.value := 1

  }  ;RegExReplace(haystack, nedle, replacement, count, limit, startingposition)

  if C_Tab.value = 1  ;replace
  {
    str := 'len := RegexMatch( haystack  , "(' C_CB_Regex_Curr.value ')",  &outvar ,' C_E_Spos.value ' := -1)'
  }
  A_Clipboard := str
  msgbox str
  ;EvalRegX(GuiObj, Item)

  rGui.Submit(false)
}

BtnDeleteRegex(GuiOBj, Item, *) {
  global rGui
  global C_CB_Regex
  global Rlist
  global DefaultRegex
  if C_CB_RegEx.value <= 3
    return
  if Rlist.Length = 1
    return false

  if C_CB_RegEx.value >= 4
  {
    MsgBox 'Are you sure you want to delete this regex?', , "YesNo"
    if Msgbox = "No"
      return
    Loop Rlist.Length
    {
      if Rlist[A_Index] = C_CB_Regex_Curr.value
      try{
          Rlist.RemoveAt(A_Index)
          C_CB_RegEx.Delete(C_Cb_Regex.value)
        StoreRegEx
      }
    }
    C_CB_Regex.Choose(1)
  }
}

BtnStoreRegex(GuiObj, item, *) {
  global rGui
  global Rlist
  TList := ""
  TList := Rlist
  if C_CB_Regex_Curr.value = ""
  {
    return false
  }
  loop Tlist.Length
  {
    if Tlist[A_Index] = C_CB_Regex_Curr.Value
      return false
  }
  global Separator  ;primary for storing regex (not for the cbregex)
  Tlist.InsertAt(Tlist.Length, C_CB_RegEx_Curr.value)
  str := ""
  loop Tlist.Length {
    try
      if Tlist[A_Index] = "" {
        Tlist.RemoveAt(A_INDex)
      }
      else
      {
        str .= Tlist[A_Index] Separator
      }
  }

  Rlist := TList
  C_CB_RegEx.Delete
  C_CB_RegEx.Add(Rlist)
  StoreRegEx
  Return true
}

showhelp_func(*) {
  global csizes
  global guiH
  if C_Help.value = 1
  {
    for ctrl in rGui {
      ctrl.GetPos(&x, &y, &w, &h)
      csizes.Set(ctrl.name, 'x=' x ',y=' y ',w=' w ',h=' h)
    }
    rgui.Show('w' GuiW + 410 'h' GuiH)
    ControlShow(Rhelp)
    ControlShow(Rhelpt)

  }
  if C_Help.value = 0
  {
    ControlHide(RHelp)
    ControlHide(Rhelpt)
  }
  rgui.Show("AutoSize")
}


/*
Storage Functions
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

StoreListInIni(Name, List) {
  Global SeparatorChars
  global Separator
  Loop Parse SeparatorChars
  {
    If (InStr(List, A_LoopField) = 0) {
      lSeparator := %A_LoopField%
      Break
    }
  }
  List := StrReplace(List, '`n', %lSeparator%)
  WriteIniKey(Name, "Separator", lSeparator)
  WriteIniKey(Name, Name, List)
}

StoreRegEx() {
  global Separator  ;primary for storing regex (not for the cbregex)
  global Rlist ;this is an array
  str := ""
  loop Rlist.Length
    try
      str .= Rlist[A_Index] Separator

  str := Trim(str, '@')
  IniWrite(str, inifile, 'RegEx', 'RegexVals')
  Return true
}


ReadIniKey(Section, Key, Default := "") {
  global IniFile
  DefaultTestValue := "kbcewlkj1u234z98hr2310587fh"
  IniRead(IniFile, Section, Key, DefaultTestValue)
  If (KeyValue != DefaultTestValue) {
    WriteIniKey(Section, Key, Default)
    KeyValue := Default
  }
  Return KeyValue
}


WriteIniKey(Section, Key, KeyValue) {
  global IniFile
  IniWrite(KeyValue, IniFile, Section, Key)
}

StoreGuiPosSize(G_UUID, GuiID := 1) {
  Global IniFile
  WinGetPos(&lGuiX, &lGuiY, &lGuiW, &lGuiH, rgui.Hwnd)
  IniWrite(lGuiX, IniFile, "Gui", 'GuiX')
  IniWrite(lGuiY, IniFile, "Gui", 'GuiY')
  IniWrite(lGuiW, IniFile, "Gui", 'GuiW')
  IniWrite(lGuiH, IniFile, "Gui", 'GuiH')
}

RestoreGuiPosSize(GuiUniqueID, GuiID := 1) {
  Global IniFile
  global CT_H
  global CT_W
  global GuiX
  global GuiY
  global GuiH
  global GuiW
  GuiX := IniRead(IniFile, "Gui", "GuiX", "")
  GuiY := IniRead(IniFile, "Gui", "GuiY", "")
  CT_W := GuiW := IniRead(IniFile, "Gui", "GuiW", "")
  CT_H := GuiH := IniRead(IniFile, "Gui", "GuiH", "")
  DetectHiddenWindows(1)
  WinMove(GuiX, GuiY, GuiW, GuiH, WinGetID(GuiUniqueID))
  DetectHiddenWindows(0)
}

#Hotif WinActive(rGui)
Enter::
{
  ctl := ControlGetFocus(rgui.hwnd)
  ctl := GuiCtrlFromHwnd(ctl).name
  if Ctl = 'CB_Regex'
  {
    pop
  }

}
#Hotif
/*
Resize Functions
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*/

guiOpen() {
  global GuiX := IniRead(IniFile, 'Gui', 'GuiX')
  global GuiY := Iniread(IniFile, 'Gui', 'GuiY')
  global GuiH := IniRead(IniFile, 'Gui', 'GuiH')
  Global guiW := IniRead(IniFile, 'Gui', 'GUIW')
}

GuiClose(*)
{
  Global IniFile
  rGui.Submit
  WinGetPos(&lGuiX, &lGuiY, &lGuiW, &lGuiH, A_ScriptHwnd)
  IniWrite(lGuiX, IniFile, "Gui", "GuiX",)
  IniWrite(lGuiY, IniFile, "Gui", "GuiY",)
  IniWrite(lGuiW, IniFile, "Gui", "GuiW",)
  IniWrite(lGuiH, IniFile, "Gui", "GuiH",)

  A_Clipboard := "GuiX " lGuiX " GuiY " lGuiY " GuiW " lGuiW " GuiH " lGuiH
  StoreRegEx
  ExitApp
  return
}

/**
 * Code Written by nperovic
 * https://github.com/nperovic 
 */

class _TabEx extends Gui.Tab
{
  static __New()
  {
    this.TCIF_TEXT := 0x0001,
      this.TCM_GETITEMCOUNT := 0x1304,
      this.TCM_SETITEM := 0x133D,
      super.Prototype.SetTabText := ObjBindMethod(this, "SetTabText"),
      super.Prototype.GetCount := ObjBindMethod(this, "GetCount")
  }

  static GetCount(obj) => SendMessage(this.TCM_GETITEMCOUNT, 0, 0, , obj.Hwnd)

  /**
   * Change a tab control's name.
   * @param {Gui.Tab} [_this=@this] This tab control object.
   * @param index tab index.
   * @param newTabName New tab name.
   * @returns {number|integer} 
   */
  static SetTabText(_this, index, newTabName)
  {
    static OffTxP := (3 * 4) + (A_PtrSize - 4)
      , Size := (5 * 4) + (2 * A_PtrSize) + (A_PtrSize - 4)

    if (index < 0) || (index > _this.GetCount())
      return false

    NumPut("UInt", this.TCIF_TEXT, TCITEM := Buffer(Size, 0), 0)
    NumPut("Ptr", StrPtr(newTabName), TCITEM, OffTxP)
    return SendMessage(this.TCM_SETITEM, (index - 1), TCITEM, , _this.Hwnd)
  }
}

/**
 * 
 * Darkmode GUi 
 * Written By  jNizM? https://www.autohotkey.com/boards/viewtopic.php?p=516799#p516799
 * https://github.com/jNizM/jNizM
 * 
 */
;Important  Set following code 
/*
; call dark mode for window title + menu
SetWindowAttribute(Main)

;insert your code between these lines

; call dark mode for controls
SetWindowTheme(Main)

;optional radio button for selecting the darkmode 

ToggleTheme(GuiCtrlObj, *)
{
	switch GuiCtrlObj.Text
	{
		case "DarkMode":
		{
			SetWindowAttribute(Main)
			SetWindowTheme(Main)
		}
		default:
		{
			SetWindowAttribute(Main, False)
			SetWindowTheme(Main, False)
		}
	}
}

*/


SetWindowAttribute(GuiObj, DarkMode := True)
{
	global DarkColors          := Map("Background", "0x202020", "Controls", "0x404040", "Font", "0xE0E0E0")
	global TextBackgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", DarkColors["Background"], "Ptr")
	static PreferredAppMode    := Map("Default", 0, "AllowDark", 1, "ForceDark", 2, "ForceLight", 3, "Max", 4)

	if (VerCompare(A_OSVersion, "10.0.17763") >= 0)
	{
		DWMWA_USE_IMMERSIVE_DARK_MODE := 19
		if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
		{
			DWMWA_USE_IMMERSIVE_DARK_MODE := 20
		}
		uxtheme := DllCall("kernel32\GetModuleHandle", "Str", "uxtheme", "Ptr")
		SetPreferredAppMode := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
		FlushMenuThemes     := DllCall("kernel32\GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")
		switch DarkMode
		{
			case True:
			{
				DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", True, "Int", 4)
				DllCall(SetPreferredAppMode, "Int", PreferredAppMode["ForceDark"])
				DllCall(FlushMenuThemes)
				GuiObj.BackColor := DarkColors["Background"]
			}
			default:
			{
				DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", False, "Int", 4)
				DllCall(SetPreferredAppMode, "Int", PreferredAppMode["Default"])
				DllCall(FlushMenuThemes)
				GuiObj.BackColor := "Default"
			}
		}
	}
}


SetWindowTheme(GuiObj, DarkMode := True)
{
	static GWL_WNDPROC        := -4
	static GWL_STYLE          := -16
	static ES_MULTILINE       := 0x0004
	static LVM_GETTEXTCOLOR   := 0x1023
	static LVM_SETTEXTCOLOR   := 0x1024
	static LVM_GETTEXTBKCOLOR := 0x1025
	static LVM_SETTEXTBKCOLOR := 0x1026
	static LVM_GETBKCOLOR     := 0x1000
	static LVM_SETBKCOLOR     := 0x1001
	static LVM_GETHEADER      := 0x101F
	static GetWindowLong      := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
	static SetWindowLong      := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
	static Init               := False
	static LV_Init            := False
	global IsDarkMode         := DarkMode

	Mode_Explorer  := (DarkMode ? "DarkMode_Explorer"  : "Explorer" )
	Mode_CFD       := (DarkMode ? "DarkMode_CFD"       : "CFD"      )
	Mode_ItemsView := (DarkMode ? "DarkMode_ItemsView" : "ItemsView")

	for hWnd, GuiCtrlObj in GuiObj
	{
		switch GuiCtrlObj.Type
		{
			case "Button", "CheckBox", "Tab", "Tab3","ListBox", "UpDown":
			{
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
			}
			case "ComboBox", "DDL":
			{
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
			}
			case "Edit":
			{
				if (DllCall("user32\" GetWindowLong, "Ptr", GuiCtrlObj.hWnd, "Int", GWL_STYLE) & ES_MULTILINE)
				{
					DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
				}
				else
				{
					DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_CFD, "Ptr", 0)
				}
			}
			case "ListView":
			{
				if !(LV_Init)
				{
					static LV_TEXTCOLOR   := SendMessage(LVM_GETTEXTCOLOR,   0, 0, GuiCtrlObj.hWnd)
					static LV_TEXTBKCOLOR := SendMessage(LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
					static LV_BKCOLOR     := SendMessage(LVM_GETBKCOLOR,     0, 0, GuiCtrlObj.hWnd)
					LV_Init := True
				}
				GuiCtrlObj.Opt("-Redraw")
				switch DarkMode
				{
					case True:
					{
						SendMessage(LVM_SETTEXTCOLOR,   0, DarkColors["Font"],       GuiCtrlObj.hWnd)
						SendMessage(LVM_SETTEXTBKCOLOR, 0, DarkColors["Background"], GuiCtrlObj.hWnd)
						SendMessage(LVM_SETBKCOLOR,     0, DarkColors["Background"], GuiCtrlObj.hWnd)
					}
					default:
					{
						SendMessage(LVM_SETTEXTCOLOR,   0, LV_TEXTCOLOR,   GuiCtrlObj.hWnd)
						SendMessage(LVM_SETTEXTBKCOLOR, 0, LV_TEXTBKCOLOR, GuiCtrlObj.hWnd)
						SendMessage(LVM_SETBKCOLOR,     0, LV_BKCOLOR,     GuiCtrlObj.hWnd)
					}
				}
				DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_Explorer, "Ptr", 0)
				
				; To color the selection - scrollbar turns back to normal
				;DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", Mode_ItemsView, "Ptr", 0)

				; Header Text needs some NM_CUSTOMDRAW coloring
				LV_Header := SendMessage(LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
				DllCall("uxtheme\SetWindowTheme", "Ptr", LV_Header, "Str", Mode_ItemsView, "Ptr", 0)
				GuiCtrlObj.Opt("+Redraw")
			}
		}
	}

	if !(Init)
	{
		; https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm#ExSubclassGUI
		global WindowProcNew := CallbackCreate(WindowProc)  ; Avoid fast-mode for subclassing.
		global WindowProcOld := DllCall("user32\" SetWindowLong, "Ptr", GuiObj.Hwnd, "Int", GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
		Init := True
	}
}



WindowProc(hwnd, uMsg, wParam, lParam)
{
	critical
	static WM_CTLCOLOREDIT    := 0x0133
	static WM_CTLCOLORLISTBOX := 0x0134
	static WM_CTLCOLORBTN     := 0x0135
	static WM_CTLCOLORSTATIC  := 0x0138
	static DC_BRUSH           := 18

	if (IsDarkMode)
	{
		switch uMsg
		{
			case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
			{
				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
				DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Controls"], "UInt")
				return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
			}
			case WM_CTLCOLORBTN:
			{
				DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Background"], "UInt")
				return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
			}
			case WM_CTLCOLORSTATIC:
			{
				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
				return TextBackgroundBrush
			}
		}
	}
	return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}