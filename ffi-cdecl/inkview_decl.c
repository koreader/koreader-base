// Needs inkview.h and inkinternal.h encompassing full 4.x-6.x API:
// wget -P SDK-6.5 https://raw.githubusercontent.com/pocketbook/SDK_6.3.0/refs/heads/6.5/SDK-B288/usr/arm-obreey-linux-gnueabi/sysroot/usr/local/include/{hwconfig.h,inkinternal.h,inkview.h}
// make TARGET=pocketbook freetype2 ffi-cdecl
// ./build/arm-pocketbook-linux-gnueabi/staging/bin/ffi-cdecl -d freetype2 -I SDK-6.5 -o ffi/inkview_h.lua -f -std=gnu11 ffi-cdecl/inkview_decl.c

#include <freetype/freetype.h>

#include "inkview.h"
#include "inkinternal.h"

#include "ffi-cdecl.h"

cdecl_const(MSG_REBOOT)

cdecl_const(EVT_ACTIVATE)
cdecl_const(EVT_BACKGROUND)
cdecl_const(EVT_BT_RXCOMPLETE)
cdecl_const(EVT_BT_TXCOMPLETE)
cdecl_const(EVT_CALLBACK)
cdecl_const(EVT_CONFIGCHANGED)
cdecl_const(EVT_DIC_CLOSED)
cdecl_const(EVT_EXIT)
cdecl_const(EVT_EXT_KB)
cdecl_const(EVT_FOCUS)
cdecl_const(EVT_FOREGROUND)
cdecl_const(EVT_FSCHANGED)
cdecl_const(EVT_FSINCOMING)
cdecl_const(EVT_GLOBALACTION)
cdecl_const(EVT_GLOBALREQUEST)
cdecl_const(EVT_HIDE)
cdecl_const(EVT_INIT)
cdecl_const(EVT_KEYPRESS)
cdecl_const(EVT_KEYRELEASE)
cdecl_const(EVT_KEYREPEAT)
cdecl_const(EVT_LETTER)
cdecl_const(EVT_MP_STATECHANGED)
cdecl_const(EVT_MP_TRACKCHANGED)
cdecl_const(EVT_MTSYNC)
cdecl_const(EVT_NEXTPAGE)
cdecl_const(EVT_OBREEY_CONFIG_CHANGED)
cdecl_const(EVT_OPENDIC)
cdecl_const(EVT_ORIENTATION)
cdecl_const(EVT_PANEL)
cdecl_const(EVT_PANEL_BLUETOOTH)
cdecl_const(EVT_PANEL_BLUETOOTH_A2DP)
cdecl_const(EVT_PANEL_CLOCK)
cdecl_const(EVT_PANEL_FRONT_LIGHT)
cdecl_const(EVT_PANEL_ICON)
cdecl_const(EVT_PANEL_MPLAYER)
cdecl_const(EVT_PANEL_NETWORK)
cdecl_const(EVT_PANEL_OBREEY_SYNC)
cdecl_const(EVT_PANEL_PROGRESS)
cdecl_const(EVT_PANEL_SETREADINGMODE)
cdecl_const(EVT_PANEL_SETREADINGMODE_INVERT)
cdecl_const(EVT_PANEL_TASKLIST)
cdecl_const(EVT_PANEL_TEXT)
cdecl_const(EVT_PANEL_USBDRIVE)
cdecl_const(EVT_POINTERDOWN)
cdecl_const(EVT_POINTERDRAG)
cdecl_const(EVT_POINTERHOLD)
cdecl_const(EVT_POINTERLONG)
cdecl_const(EVT_POINTERMOVE)
cdecl_const(EVT_POINTERUP)
cdecl_const(EVT_PREVPAGE)
cdecl_const(EVT_QN_BORDER)
cdecl_const(EVT_QN_MOVE)
cdecl_const(EVT_QN_RELEASE)
cdecl_const(EVT_REPAINT)
cdecl_const(EVT_SAVESTATE)
cdecl_const(EVT_SCANPROGRESS)
cdecl_const(EVT_SCANSTOPPED)
cdecl_const(EVT_SCROLL)
cdecl_const(EVT_SDIN)
cdecl_const(EVT_SDOUT)
cdecl_const(EVT_SHOW)
cdecl_const(EVT_SNAPSHOT)
cdecl_const(EVT_STARTSCAN)
cdecl_const(EVT_STOPSCAN)
cdecl_const(EVT_SUBTASKCLOSE)
cdecl_const(EVT_SYNTH_ENDED)
cdecl_const(EVT_TAB)
cdecl_const(EVT_TEXTCLEAR)
cdecl_const(EVT_TOUCHDOWN)
cdecl_const(EVT_TOUCHMOVE)
cdecl_const(EVT_TOUCHUP)
cdecl_const(EVT_UNFOCUS)

#if (POCKETBOOK_VERSION >= 505)
cdecl_const(EVT_CONTROL_PANEL_ABOUT_TO_OPEN)
cdecl_const(EVT_NET_CONNECTED)
cdecl_const(EVT_NET_DISCONNECTED)
cdecl_const(EVT_NET_FOUND_NEW_FW)
cdecl_const(EVT_POSTPONE_TIMED_POWEROFF)
#endif

#if (POCKETBOOK_VERSION >= 507)
cdecl_const(EVT_FRAME_ACTIVATED)
cdecl_const(EVT_FRAME_DEACTIVATED)
cdecl_const(EVT_POINTERCANCEL)
#endif

#if (POCKETBOOK_VERSION >= 511)
cdecl_const(EVT_READ_PROGRESS_CHANGED)
#endif

#if (POCKETBOOK_VERSION >= 519)
cdecl_const(EVT_ASYNC_TASK_FINISHED)
cdecl_const(EVT_AUDIO_CHANGED)
cdecl_const(EVT_AVRCP_COMMAND)
cdecl_const(EVT_DUMP_BITMAPS_DEBUG_INFO)
cdecl_const(EVT_STOP_PLAYING)
cdecl_const(EVT_SYNTH_POSITION)
cdecl_const(EVT_UPDATE)
#endif

#if (POCKETBOOK_VERSION >= 605)
cdecl_const(EVT_CUSTOM)
cdecl_const(EVT_KEYPRESS_EXT)
cdecl_const(EVT_KEYRELEASE_EXT)
cdecl_const(EVT_KEYREPEAT_EXT)
cdecl_const(EVT_PACKAGE_JOB_CHANGED)
cdecl_const(EVT_POINTERCHANGED)
cdecl_const(EVT_USBSTORE_IN)
cdecl_const(EVT_USBSTORE_OUT)
#endif

#if (POCKETBOOK_VERSION < 517)
#define IV_KEY_0               KEY_0
#define IV_KEY_1               KEY_1
#define IV_KEY_2               KEY_2
#define IV_KEY_3               KEY_3
#define IV_KEY_4               KEY_4
#define IV_KEY_5               KEY_5
#define IV_KEY_6               KEY_6
#define IV_KEY_7               KEY_7
#define IV_KEY_8               KEY_8
#define IV_KEY_9               KEY_9
#define IV_KEY_BACK            KEY_BACK
#define IV_KEY_COVERCLOSE      KEY_COVERCLOSE
#define IV_KEY_COVEROPEN       KEY_COVEROPEN
#define IV_KEY_DELETE          KEY_DELETE
#define IV_KEY_DOWN            KEY_DOWN
#define IV_KEY_HOME            KEY_HOME
#define IV_KEY_KEYBOARDCLOSE   KEY_KEYBOARDCLOSE
#define IV_KEY_LANGUAGECHANGE  KEY_LANGUAGECHANGE
#define IV_KEY_LEFT            KEY_LEFT
#define IV_KEY_MENU            KEY_MENU
#define IV_KEY_MINUS           KEY_MINUS
#define IV_KEY_MUSIC           KEY_MUSIC
#define IV_KEY_NEXT            KEY_NEXT
#define IV_KEY_NEXT2           KEY_NEXT2
#define IV_KEY_OK              KEY_OK
#define IV_KEY_PLUS            KEY_PLUS
#define IV_KEY_POWER           KEY_POWER
#define IV_KEY_PREV            KEY_PREV
#define IV_KEY_PREV2           KEY_PREV2
#define IV_KEY_RIGHT           KEY_RIGHT
#define IV_KEY_SHIFT           KEY_SHIFT
#define IV_KEY_UP              KEY_UP
#define IV_KEY_ZOOMIN          KEY_ZOOMIN
#define IV_KEY_ZOOMOUT         KEY_ZOOMOUT
#endif

cdecl_const(IV_KEY_0)
cdecl_const(IV_KEY_1)
cdecl_const(IV_KEY_2)
cdecl_const(IV_KEY_3)
cdecl_const(IV_KEY_4)
cdecl_const(IV_KEY_5)
cdecl_const(IV_KEY_6)
cdecl_const(IV_KEY_7)
cdecl_const(IV_KEY_8)
cdecl_const(IV_KEY_9)
cdecl_const(IV_KEY_BACK)
cdecl_const(IV_KEY_COVERCLOSE)
cdecl_const(IV_KEY_COVEROPEN)
cdecl_const(IV_KEY_DELETE)
cdecl_const(IV_KEY_DOWN)
cdecl_const(IV_KEY_HOME)
cdecl_const(IV_KEY_KEYBOARDCLOSE)
cdecl_const(IV_KEY_LANGUAGECHANGE)
cdecl_const(IV_KEY_LEFT)
cdecl_const(IV_KEY_MENU)
cdecl_const(IV_KEY_MINUS)
cdecl_const(IV_KEY_MUSIC)
cdecl_const(IV_KEY_NEXT)
cdecl_const(IV_KEY_NEXT2)
cdecl_const(IV_KEY_OK)
cdecl_const(IV_KEY_PLUS)
cdecl_const(IV_KEY_POWER)
cdecl_const(IV_KEY_PREV)
cdecl_const(IV_KEY_PREV2)
cdecl_const(IV_KEY_RIGHT)
cdecl_const(IV_KEY_SHIFT)
cdecl_const(IV_KEY_UP)
cdecl_const(IV_KEY_ZOOMIN)
cdecl_const(IV_KEY_ZOOMOUT)

#if (POCKETBOOK_VERSION >= 519)
cdecl_const(IV_KEY_MENU_POWER)
#endif

#if (POCKETBOOK_VERSION >= 605)
cdecl_const(IV_KEY_MAX)
#endif

cdecl_const(NET_CONNECTED)
cdecl_const(NET_OK)

cdecl_const(REQ_KEYLOCK)

#if (POCKETBOOK_VERSION >= 505)
cdecl_enum(input_dev_e)
#endif

#if (POCKETBOOK_VERSION >= 611)
cdecl_type(hw_event_data_slot)
#endif

#if (POCKETBOOK_VERSION >= 505)
cdecl_struct(hw_event_data_common_s)
cdecl_type(hw_event_data_common)
cdecl_struct(hw_event_data_pointer_s)
cdecl_type(hw_event_data_pointer)
cdecl_struct(hw_event_s)
cdecl_type(hw_event)
#endif

cdecl_struct(icanvas_s)
cdecl_type(icanvas)

cdecl_type(iv_handler)
#if (POCKETBOOK_VERSION <= 610)
cdecl_struct(iv_mtinfo_s)
#endif
cdecl_type(iv_mtinfo)

cdecl_type(PANEL_FLAGS)

#if (POCKETBOOK_VERSION < 514)
// Provided by inkview-compat.
void ClearOnExit();
void PrepareForLoop(iv_handler);
#endif

cdecl_func(ClearOnExit)
cdecl_func(DynamicUpdate)
cdecl_func(FullUpdate)
cdecl_func(FullUpdateHQ)
cdecl_func(GetBatteryPower)
cdecl_func(GetCurrentProfile)
cdecl_func(GetCurrentTask)
cdecl_func(GetDeviceModel)
cdecl_func(GetFrontlightState)
cdecl_func(GetGlobalConfig)
cdecl_func(GetSleepmode)
cdecl_func(GetSoftwareVersion)
cdecl_func(GetTaskFramebuffer)
cdecl_func(GoSleep)
cdecl_func(IsCharging)
cdecl_func(IsTaskActive)
cdecl_func(MultitaskingSupported)
cdecl_func(NetConnect)
cdecl_func(NetDisconnect)
cdecl_func(OpenBook)
cdecl_func(OpenScreen)
cdecl_func(PageSnapshot)
cdecl_func(PartialUpdate)
cdecl_func(PartialUpdateHQ)
cdecl_func(PowerOff)
cdecl_func(PrepareForLoop)
cdecl_func(ProcessEventLoop)
cdecl_func(QueryGSensor)
cdecl_func(QueryNetwork)
cdecl_func(ReadString)
cdecl_func(SendGlobalRequest)
cdecl_func(SetFrontlightState)
cdecl_func(SetPanelType)
cdecl_func(SetSubtaskInfo)
cdecl_func(WaitForUpdateComplete)
cdecl_func(WiFiPower)
cdecl_func(hw_close)
cdecl_func(hw_get_keylock)
cdecl_func(hw_init)
cdecl_func(iv_ipc_request)
cdecl_func(iv_setup_gsensor)
cdecl_func(iv_setup_touchpanel)
cdecl_func(iv_sleepmode)
cdecl_func(iv_update_orientation)

#if (POCKETBOOK_VERSION >= 505)
cdecl_func(GetTouchInfoI)
#endif

#if (POCKETBOOK_VERSION >= 508)
cdecl_func(NetMgrPing)
#endif

#if (POCKETBOOK_VERSION >= 519)
cdecl_func(GetFrontlightColor)
cdecl_func(GetFrontlightEnabled)
cdecl_func(GetGSensorOrientation)
cdecl_func(SetFrontlightColor)
cdecl_func(SetFrontlightEnabled)
#endif

#if (POCKETBOOK_VERSION >= 605)
cdecl_func(adjustAreaDefault)
#endif
