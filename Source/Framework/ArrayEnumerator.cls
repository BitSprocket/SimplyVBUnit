VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ArrayEnumerator"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'The MIT License (MIT)
'Copyright (c) 2012 Kelly Ethridge
'
'Permission is hereby granted, free of charge, to any person obtaining a copy
'of this software and associated documentation files (the "Software"), to deal
'in the Software without restriction, including without limitation the rights to
'use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
'the Software, and to permit persons to whom the Software is furnished to do so,
'subject to the following conditions:
'
'The above copyright notice and this permission notice shall be included in all
'copies or substantial portions of the Software.
'
'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
'INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
'PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
'FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
'OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
'DEALINGS IN THE SOFTWARE.
'
'
' Module: ArrayEnumerator
'
Option Explicit
Implements IEnumerator

Private Const INDEX_RESET As Long = -1
Private Const EMPTY_ARRAY As Long = -1

Private Type GuidSafeArray1d
    Guid As VBGUID
    SA As SafeArray1d
End Type

Private mArray  As Variant
Private mSA     As GuidSafeArray1d
Private mIndex  As Long


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Friend Methods
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Friend Sub Init(ByRef Arr As Variant)
    If Not IsArray(Arr) Then _
        Error.ResourceArgument Me, "Init", "Arr", Arg_MustBeArray
        
    Dim pSA As Long
    pSA = GetArrayPointer(Arr)
    
    If ArrayExists(pSA) Then
        CreateProxy Arr, pSA
    Else
        CreateEmptyProxy
    End If
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Private Helpers
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Function ArrayExists(ByVal Ptr As Long) As Boolean
    ArrayExists = (Ptr <> vbNullPtr)
End Function

Private Sub CreateProxy(ByRef Arr As Variant, ByVal PtrSA As Long)
    FillDescriptor PtrSA, VarType(Arr) And &HFF
    
    If HasElements Then
        CreateArrayProxy Arr
    Else
        CreateEmptyProxy
    End If
End Sub

Private Sub FillDescriptor(ByVal Ptr As Long, ByVal ArrayType As VbVarType)
    Const SIZEOF_GUID As Long = 16

    Dim Offset As Long
    Select Case ArrayType
        Case vbObject: Offset = SIZEOF_GUID
        Case vbUserDefinedType: Offset = 4
    End Select
    
    CopyMemory ByVal VarPtr(mSA.SA) - Offset, ByVal Ptr - Offset, LenB(mSA.SA) + Offset
End Sub

Private Function HasElements() As Boolean
    HasElements = (mSA.SA.cDims > 0)
End Function

Private Sub CreateArrayProxy(ByRef Arr As Variant)
    Dim Count As Long
    Count = 1
    
    Dim i As Long
    For i = 1 To mSA.SA.cDims
        Count = Count * (UBound(Arr, i) - LBound(Arr, i) + 1)
    Next i

    VariantType(mArray) = VarType(Arr)
    MemLong(VarPtr(mArray) + VARIANTDATA_OFFSET) = VarPtr(mSA.SA)
    
    mSA.SA.lLbound = 0
    mSA.SA.cElements = Count
    mSA.SA.cDims = ARRAY_DIMENSIONS
    
    mIndex = INDEX_RESET
End Sub

Private Sub CreateEmptyProxy()
    mSA.SA.cElements = EMPTY_ARRAY
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   Class Events
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Sub Class_Terminate()
    ZeroMemory mArray, SIZEOF_VARIANT
End Sub


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'   IEnumerator Interface
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Private Property Get IEnumerator_Current() As Variant
    VariantCopyInd IEnumerator_Current, mArray(mIndex)
End Property

Private Function IEnumerator_MoveNext() As Boolean
    mIndex = mIndex + 1
    IEnumerator_MoveNext = (mIndex < mSA.SA.cElements)
End Function

Private Sub IEnumerator_Reset()
    mIndex = INDEX_RESET
End Sub

