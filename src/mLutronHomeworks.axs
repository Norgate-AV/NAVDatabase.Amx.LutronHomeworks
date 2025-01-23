MODULE_NAME='mLutronHomeworks'      (
                                        dev vdvObject,
                                        dev dvPort
                                    )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.SocketUtils.axi'

/*
 _   _                       _          ___     __
| \ | | ___  _ __ __ _  __ _| |_ ___   / \ \   / /
|  \| |/ _ \| '__/ _` |/ _` | __/ _ \ / _ \ \ / /
| |\  | (_) | | | (_| | (_| | ||  __// ___ \ V /
|_| \_|\___/|_|  \__, |\__,_|\__\___/_/   \_\_/
                 |___/

MIT License

Copyright (c) 2023 Norgate AV Services Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

constant long TL_IP_CHECK = 1

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
volatile integer iSemaphore
volatile char cRxBuffer[NAV_MAX_BUFFER]
volatile integer iModuleEnabled

volatile char cArea[NAV_MAX_CHARS]
volatile char cIntegrationID[NAV_MAX_CHARS]

volatile integer iRequiredScene

volatile char cIPAddress[15]
volatile integer iIPConnected

volatile long ltIPCheck[] = { 3000 }

volatile char cLink[NAV_MAX_CHARS]
volatile char cAddress[NAV_MAX_CHARS]
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
define_function Send(char cParam[]) {
    send_string dvPort,"cParam,NAV_CR,NAV_LF"
    send_string 0, "cParam,NAV_CR,NAV_LF"
}

define_function Scene(integer iParam) {
    //send_string dvPort,"'#DEVICE,',cAddress,',',itoa(iParam),',3',NAV_CR,NAV_LF"
    Send("'#DEVICE,',cAddress,',',itoa(iParam),',3'")
}

define_function Build(char cCmd[], char cProcessor[], char cLink[], char cAddress[], char cVal[]) {
    Send("cCmd,', [',cProcessor,':',cLink,':',cAddress,'], ',cVal")
}

define_function MaintainIPConnection() {
    if (!iIPConnected) {
    NAVClientSocketOpen(dvPort.PORT, cIPAddress, NAV_TELNET_PORT, IP_TCP)
    }
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
create_buffer dvPort,cRxBuffer
iModuleEnabled = true
rebuild_event()
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
data_event[dvPort] {
    online: {
    if (iModuleEnabled && data.device.number != 0) {
        send_command data.device,"'SET BAUD 9600,N,8,1 485 DISABLE'"
        send_command data.device,"'B9MOFF'"
        send_command data.device,"'CHARD-0'"
        send_command data.device,"'CHARDM-0'"
        send_command data.device,"'HSOFF'"
    }

    if (iModuleEnabled) {
        //SendStringRaw("NAV_ESC,'1CV',NAV_CR")    //Set Verbose Mode
        //#warn 'Enable all RS232 Inserts!!!'
        //if (1) {
        //stack_var integer x
        //for (x = 1; x <= 16; x++) {
            //SendStringRaw("NAV_ESC,itoa(x),'*1Lrpt',NAV_CR")    //Enable all RS232 Inserts
        //}
        //}

        //wait 10 Init()
        //NAVTimelineStart(TL_DRIVE,ltDrive,timeline_absolute,timeline_repeat)
    }

    if (iModuleEnabled && data.device.number == 0) {
        //NAVErrorLog(NAV_LOG_LEVEL_DEBUG, 'EXTRON_DVS_ONLINE')
        iIPConnected = true; //iIPAuthenticated = true;
    }
    }
    string: {
    if (iModuleEnabled) {
        /*
        iCommunicating = true
        [vdvObject,DATA_INITIALIZED] = true
        TimeOut()
         NAVErrorLog(NAV_LOG_LEVEL_DEBUG, NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_STRING_FROM, dvPort, data.text))
        if (!iSemaphore) { Process() }
        */
        send_string 0, "data.text"
        select {
        active (NAVContains(data.text,'login:')): {
            send_string data.device,"'AMX',NAV_CR,NAV_LF"
        }
        active (NAVContains(data.text,'password:')): {
            send_string data.device,"'AMX',NAV_CR,NAV_LF"
        }
        }
    }
    }
    offline: {
    if (data.device.number == 0) {
        //NAVErrorLog(NAV_LOG_LEVEL_DEBUG, 'EXTRON_DVS_OFFLINE')
        NAVClientSocketClose(dvPort.port)
        iIPConnected = false
        //iIPAuthenticated = false
        //iCommunicating = false
        //if (timeline_active(TL_HEARTBEAT)) {
        //NAVTimelineStop(TL_HEARTBEAT)
        //}
    }
    }
    onerror: {
    if (data.device.number == 0) {
        //NAVErrorLog(NAV_LOG_LEVEL_DEBUG, 'EXTRON_DVS_ONERROR')
        iIPConnected = false
        //iIPAuthenticated = false
        //iCommunicating = false
        //if (timeline_active(TL_HEARTBEAT)) {
        //NAVTimelineStop(TL_HEARTBEAT)
        //}
    }
    }
}

data_event[vdvObject] {
    command: {
    stack_var char cCmdHeader[NAV_MAX_CHARS]
    stack_var char cCmdParam[3][NAV_MAX_CHARS]
    if (iModuleEnabled) {
        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM, data.device, data.text))
        cCmdHeader = DuetParseCmdHeader(data.text)
        cCmdParam[1] = DuetParseCmdParam(data.text)
        cCmdParam[2] = DuetParseCmdParam(data.text)
        cCmdParam[3] = DuetParseCmdParam(data.text)
        switch (cCmdHeader) {
        case 'PROPERTY': {
            switch (cCmdParam[1]) {
            case 'IP_ADDRESS': {
                cIPAddress = cCmdParam[2]
                NAVTimelineStart(TL_IP_CHECK,ltIPCheck,timeline_absolute,timeline_repeat)
            }
            //case 'LINK': {
                //cID = format('%02d',atoi(cCmdParam[2]))
            //    cLink = cCmdParam[2]
            //}
            case 'ADDRESS': {
                cAddress = cCmdParam[2]
            }
            }
        }
        //case 'PASSTHRU': { SendStringRaw(cCmdParam[1]) }

        case 'KEYPAD_BUTTON_PRESS': {
            if (iIPConnected) {
            //Build('KBP', '1', cLink, cAddress, cCmdParam[1])
            Scene(atoi(cCmdParam[1]))
            }
        }
        //case 'KEYPAD_BUTTON_RELEASE': {
        //    if (iIPConnected) {
        //    Build('KBR', '1', cLink, cAddress, cCmdParam[1])
        //    }
        //}
        }
    }
    }
}

define_event channel_event[vdvObject,0] {
    on: {
    if (iModuleEnabled) {
        //Build('KBP', '1', cLink, cAddress, itoa(channel.channel))
    }
    }
    off: {
    //Build('KBR', '1', cLink, cAddress, itoa(channel.channel))
    }
}

define_event timeline_event[TL_IP_CHECK] {
    MaintainIPConnection()
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
