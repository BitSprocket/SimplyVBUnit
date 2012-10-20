VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "StringBuilder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
' Copyright 2009 Kelly Ethridge
'
' Licensed under the Apache License, Version 2.0 (the "License");
' you may not use this file except in compliance with the License.
' You may obtain a copy of the License at
'
'     http://www.apache.org/licenses/LICENSE-2.0
'
' Unless required by applicable law or agreed to in writing, software
' distributed under the License is distributed on an "AS IS" BASIS,
' WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' See the License for the specific language governing permissions and
' limitations under the License.
'
' Module: StringBuilder
'

''
' A class to help build complex strings.
'
' @remarks This is a helper class that provides services to build complex strings
' used during the testing process.
'
Option Explicit

Private Const DEF_CAPACITY      As Long = 128
Private Const MIN_LENGTH        As Long = 0
Private Const FIRST_ARGUMENT    As Long = 0
Private Const SECOND_ARGUMENT   As Long = FIRST_ARGUMENT + 1


Private mBuffer             As String
Private mLength             As Long
Private mRequiredCapacity   As Long
Private mNewCapacity        As Long



''
' Formats text by replacing indices with arguments, then appends the result to the string buffer.
'
' @param Text The text that contains indices to be formatted.
' @param Args A list of arguments to replace the indices with.
'
Public Sub AppendFormat(ByRef Format As String, ParamArray Args() As Variant)
    Dim LocalArgs() As Variant
    LocalArgs = Args
    AppendFormatArray Format, LocalArgs
End Sub

''
' Formats text by replacing indices with arguments, then appends the result to the string buffer.
'
' @param Text The text that contains indices to be formatted.
' @param Args A list of arguments to replace the indices with.
'
Public Sub AppendFormatArray(ByRef Format As String, ByRef Args() As Variant)
    Dim Segments() As String
    Segments = Split(Format, "{{")

    Dim j As Long
    For j = 0 To UBound(Segments)
        Dim i As Long
        For i = 0 To UBound(Args)
            Segments(j) = Replace$(Segments(j), "{" & i & "}", GetStringValue(Args(i)))
        Next
    Next

    Dim Result As String
    Result = Join(Segments, "{")
    Result = Replace$(Result, "}}", "}")
    
    AppendText Result
End Sub

Public Sub AppendFormatArrayEx(ByRef TextAndArgs() As Variant)
    Dim UpperBound As Long
    UpperBound = UBound(TextAndArgs)
    
    If HasOneArgument(UpperBound) Then
        AppendText CStr(TextAndArgs(FIRST_ARGUMENT))
    ElseIf HasMultipleArguments(UpperBound) Then
        Dim LocalArgs() As Variant
        LocalArgs = TextAndArgs
        WriteFormattedText CStr(LocalArgs(FIRST_ARGUMENT)), LocalArgs(SECOND_ARGUMENT), UpperBound
    End If
End Sub

Private Function HasOneArgument(ByVal UpperBound As Long) As Boolean
    HasOneArgument = (UpperBound = 0)
End Function

Private Function HasMultipleArguments(ByVal UpperBound As Long) As Boolean
    HasMultipleArguments = (UpperBound > 0)
End Function

Private Function HasNoArguments(ByVal UpperBound As Long) As Boolean
    HasNoArguments = (UpperBound < 0)
End Function

Private Sub WriteFormattedText(ByRef Text As String, ByRef FirstArgument As Variant, ByVal ArgumentCount As Long)
    Dim Proxy As ArrayProxy
    InitArrayProxy Proxy, FirstArgument, ArgumentCount
    AppendFormatArray Text, Proxy.Data
End Sub

''
' Appends text to the end of the current string buffer.
'
' @param Text The string to be appended to the buffer.
'
Public Sub Append(ByVal Value As String)
    AppendText Value
End Sub

''
' Returns the current length of the string buffer.
'
' @return A Long indicating the length of the internal string buffer.
'
Public Property Get Length() As Long
    Length = mLength
End Property

''
' Sets the length for the current string buffer.
'
' @param RHS The length to set the string buffer to.
'
Public Property Let Length(ByVal RHS As Long)
    If RHS < MIN_LENGTH Then _
        Error.CannotBeNegative Me, "Length", "Length"
    
    If RHS > mLength Then
        Dim FillSpace As String
        FillSpace = Space$(RHS - mLength)
        
        Append FillSpace
    Else
        mLength = RHS
    End If
End Property

''
' Returns the current string buffer.
'
' @return The current string buffer.
'
Public Function ToString() As String
    ToString = Left$(mBuffer, mLength)
End Function


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function GetStringValue(ByRef Value As Variant) As String
    Dim Result As String
    
    If IsArray(Value) Or IsObject(Value) Then
        Result = MsgUtils.GetTypeRepresentation(Value)
    Else
        Result = CStr(Value)
    End If
    
    GetStringValue = Result
End Function

Private Sub AppendText(ByRef Text As String)
    EnsureCapacity Length + Len(Text)
    AppendToBuffer Text
End Sub

Private Sub EnsureCapacity(ByVal RequiredCapacity As Long)
    mRequiredCapacity = RequiredCapacity
    
    If NeedsMoreCapacity Then
        CalculateNewCapacity
        ExpandCapacity
    End If
End Sub

Private Function NeedsMoreCapacity() As Boolean
    NeedsMoreCapacity = (mRequiredCapacity > CurrentCapacity)
End Function

Private Sub CalculateNewCapacity()
    Dim NewCapacity As Long
    NewCapacity = CurrentCapacity
    
    Do While mRequiredCapacity > NewCapacity
        NewCapacity = NewCapacity * 2
    Loop
    
    mNewCapacity = NewCapacity
End Sub

Private Function CurrentCapacity() As Long
    CurrentCapacity = Len(mBuffer)
End Function

Private Sub ExpandCapacity()
    Dim NewBuffer As String
    NewBuffer = String$(mNewCapacity, vbNullChar)
    
    CopyMemory ByVal StrPtr(NewBuffer), ByVal StrPtr(mBuffer), Length * 2
    mBuffer = vbNullString
    
    StringPtr(mBuffer) = StringPtr(NewBuffer)
    StringPtr(NewBuffer) = vbNullPtr
End Sub

Private Sub AppendToBuffer(ByRef Text As String)
    CopyMemory ByVal StrPtr(mBuffer) + (Length * 2), ByVal StrPtr(Text), LenB(Text)
    SetLength Text
End Sub

Private Sub SetLength(ByRef Text As String)
    mLength = mLength + Len(Text)
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_Initialize()
    mBuffer = String$(DEF_CAPACITY, vbNullChar)
End Sub