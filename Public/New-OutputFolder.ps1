Function New-OutputFolder {
<#

    .SYNOPSIS
    Function intended for preparing a PowerShell object for output/create folders for e.g. reports or logs.

    .DESCRIPTION
    Function intended for preparing a PowerShell custom object what contains e.g. folder name for output/create folders. The name is prepared based on prefix, middle name part, suffix, date, etc. with verification if provided path exist and is it writable.

    Returned object contains properties
    - ParentPath - to use it please check an examples - as a [System.IO.DirectoyInfo]
    - ExitCode
    - ExitCodeDescription

    Exit codes and descriptions
    - 0 = "Everything is fine :-)"
    - 1 = "Provided path <PATH> doesn't exist
    - 2 = Empty code
    - 3 = "Provided patch <PATH> is not writable"
    - 4 = "The folder <PATH>\\<FOLDER_NAME> already exist  - can't be overwritten"
    - 5 = "The folder <PATH>\\<FOLDER_NAME> already exist  - can be overwritten"

    .PARAMETER ParentPath
    By default output folders are stored in the current path

    .PARAMETER OutputFolderNamePrefix
    Prefix used for creating output folders name

    .PARAMETER OutputFolderNameMidPart
    Part of the name which will be used in midle of output folder name

    .PARAMETER OutputFolderNameSuffix
    Part of the name which will be used at the end of output folder name

    .PARAMETER IncludeDateTimePartInOutputFolderName
    Set to TRUE if report folder name should contains part based on date and time - format yyyyMMdd is used

    .PARAMETER DateTimePartInOutputFolderName
    Set to date and time which should be used in output folder name, by default current date and time is used
    
    .PARAMETER NamePartsSeparator
    A char used to separate parts in the name, by default "-" is used

    .PARAMETER BreakIfError
    Break function execution if parameters provided for output folder creation are not correct or destination folder path is not writables

    .EXAMPLE

    PS \> (Get-Item env:COMPUTERNAME).Value
    WXDX75
    
    PS \> $FolderNeeded= @{
        ParentPath = 'C:\USERS\UserName\';
        OutputFolderNamePrefix = 'Messages';
        OutputFolderNameMidPart = (Get-Item env:COMPUTERNAME).Value
        IncludeDateTimePartInOutputFolderName = $false;
        BreakIfError = $true
    }
    
    PS \> $PerServerReportFolderMessages = New-OutputFolder @FolderNeeded

    PS \> $PerServerReportFolderMessages | Format-List

    OutputFilePath      : C:\users\UserName\Messages-WXDX75
    ExitCode            : 1
    ExitCodeDescription : Everything is fine :-)
    
    PS \> New-Item -Path $PerServerReportFolderMessages.OutputFolderPath -ItemType Directory

    Directory: C:\USERS\UserName

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       21/10/2015     00:12              0 Messages-WXDX75
    
    The file created on provided parameters. 
    Under preparation the file name is created, provided part of names are used, and availability of name (if the file exist now) is checked.

    .EXAMPLE
    
    $FolderNeeded= @{
        ParentPath = 'C:\USERS\UserName\';
        OutputFolderNamePrefix = 'Messages';
        OutputFolderNameMidPart = 'COMPUTERNAME';
        OutputFolderNameSuffix = "failed"
    }
    
    PS \> $PerServerReportFolderMessages = New-OutputFolder @FolderNeeded

    PS \> $PerServerReportFolderMessages.OutputFolderPath | Select-Object -Property Name,Parent,exists | Format-List

    Name   : Messages-COMPUTERNAME-20161112-failed
    Parent : UserName
    Exists : False
 
    PS \> ($PerServerReportFolderMessages.OutputFolderPath).gettype()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     DirectoryInfo                            System.IO.FileSystemInfo
    
    PS \> Test-Path ($PerServerReportFolderMessages.OutputFilePath)
    False
    
    The function return object what contain the property named OutputFilePath what is the object of type System.IO.DirectoryInfo.
    
    Folder is not created. Only the object in the memory is prepared.

    .OUTPUTS
    System.Object[]

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net  
    KEYWORDS: PowerShell, Folder, FileSystem  
    
    CURRENT VERSION
    - 0.3.2 - 2016-11-12
    
    HISTORY OF VERSIONS  
    https://github.com/it-praktyk/New-OutputObject/VERSIONS.md

    REMARKS
    - The warning generated by PSScriptAnalyzer "Function 'New-OutputFolder' has verb that could change system state. Therefore, the function has to support 'ShouldProcess'." is acceptable.

    LICENSE
    Copyright (c) 2016 Wojciech Sciesinski  
    This function is licensed under The MIT License (MIT)  
    Full license text: https://opensource.org/licenses/MIT

    #>
    
    [cmdletbinding()]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $false)]
        [String]$ParentPath = ".",
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNamePrefix = "Output",
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNameMidPart = $null,
        [parameter(Mandatory = $false)]
        [String]$OutputFolderNameSuffix = $null,
        [parameter(Mandatory = $false)]
        [Bool]$IncludeDateTimePartInOutputFolderName = $true,
        [parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DateTimePartInOutputFolderName = $null,
        [parameter(Mandatory = $false)]
        [alias("Separator")]
        [String]$NamePartsSeparator="-",
        [parameter(Mandatory = $false)]
        [Switch]$BreakIfError

    )

    #Declare variable

    [Int]$ExitCode = 0

    [String]$ExitCodeDescription = "Everything is fine :-)"

    $Result = New-Object -TypeName PSObject

    #Convert relative path to absolute path
    [String]$ParentPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ParentPath)

    #Assign value to the variable $IncludeDateTimePartInOutputFolderName if is not initialized
    If ($IncludeDateTimePartInOutputFolderName -and ($null -eq $DateTimePartInOutputFolderName)) {

        [String]$DateTimePartInFolderNameString = $(Get-Date -format 'yyyyMMdd')

    }
    elseif ($IncludeDateTimePartInOutputFolderName) {

        [String]$DateTimePartInFolderNameString = $(Get-Date -Date $DateTimePartInOutputFolderName -format 'yyyyMMdd')

    }
    
    #Check if Output directory exist 
    If (-not (Test-Path -Path $ParentPath -PathType Container)) {
        
        [Int]$ExitCode = 1
        
        $MessageText = "Provided path $ParentPath doesn't exist"
        
        [String]$ExitCodeDescription = $MessageText
        
    }
    
    
    #Try if Output directory is writable - a temporary folder is created for that
    
    Else {
        
        Try {
            
            [String]$TempFolderName = [System.IO.Path]::GetRandomFileName -replace '.*\\', ''
            
            [String]$TempFolderPath = "{0}{1}" -f $ParentPath, $TempFolderName
            
            New-Item -Path $TempFolderPath -type Directory -ErrorAction Stop | Out-Null
            
        }
        Catch {
            
            [String]$MessageText = "Provided path {0} is not writable" -f $ParentPath
            
            If ($BreakIfError.IsPresent) {
                
                Throw $MessageText
                
            }
            Else {
                
                [Int]$ExitCode = 3
                
                [String]$ExitCodeDescription = $MessageText
                
            }
            
        }
        
        Remove-Item -Path $TempFolderPath -ErrorAction SilentlyContinue | Out-Null
        
    }
    
    #Constructing the folder name
    If (!($IncludeDateTimePartInOutputFolderName) -and !([String]::IsNullOrEmpty($OutputFolderNameMidPart)) ) {

        [String]$OutputFolderPathTemp1 = "{0}\{1}{3}{2}" -f $ParentPath, $OutputFolderNamePrefix, $OutputFolderNameMidPart, $NamePartsSeparator

    }
    Elseif (!($IncludeDateTimePartInOutputFolderName) -and [String]::IsNullOrEmpty($OutputFolderNameMidPart )) {

        [String]$OutputFolderPathTemp1 = "{0}\{1}" -f $ParentPath, $OutputFolderNamePrefix

    }
    ElseIf ($IncludeDateTimePartInOutputFolderName -and !([String]::IsNullOrEmpty($OutputFolderNameMidPart))) {

        [String]$OutputFolderPathTemp1 = "{0}\{1}{4}{2}{4}{3}" -f $ParentPath, $OutputFolderNamePrefix, $OutputFolderNameMidPart, $DateTimePartInFolderNameString, $NamePartsSeparator

    }
    Else {

        [String]$OutputFolderPathTemp1 = "{0}\{1}{3}{2}" -f $ParentPath, $OutputFolderNamePrefix, $DateTimePartInFolderNameString, $NamePartsSeparator
        
    }
    
    
    If ( [String]::IsNullOrEmpty($OutputFolderNameSuffix)) {

        [String]$OutputFolderPathTemp = "{0}" -f $OutputFolderPathTemp1

    }
    Else {

        [String]$OutputFolderPathTemp = "{0}{2}{1}" -f $OutputFolderPathTemp1, $OutputFolderNameSuffix, $NamePartsSeparator

    }

    #Replacing doubled chars \\ , -- , .. - except if \\ is on begining - means that path is UNC share
    [System.IO.DirectoryInfo]$OutputFolderPath = "{0}{1}" -f $OutputFolderPathTemp.substring(0, 2), (($OutputFolderPathTemp.substring(2, $OutputFolderPathTemp.length - 2).replace("\\", '\')).replace("--", "-")).replace("..", ".")

    If (Test-Path -Path $OutputFolderPath -PathType Container) {
        
        $Answer = Get-OverwriteDecision -Path $OutputFolderPath -ItemType "Folder"
        
        switch ($Answer) {
            
            0 {
                
                [Int]$ExitCode = 4
                
                [System.String]$MessageText = "The folder {0} already exist  - can't be overwritten" -f $OutputFolderPath.FullName
                
                [String]$ExitCodeDescription = $MessageText
                
            }
            
            1 {
                
                [Int]$ExitCode = 5
                
                [System.String]$MessageText = "The folder {0} already exist  - can be overwritten" -f $OutputFolderPath
                
                [String]$ExitCodeDescription = $MessageText
                
            }
            
            2 {
                
               Throw $MessageText 
                
            }
            
        }
 
    }

    $Result | Add-Member -MemberType NoteProperty -Name OutputFolderPath -Value $OutputFolderPath

    $Result | Add-Member -MemberType NoteProperty -Name ExitCode -Value $ExitCode

    $Result | Add-Member -MemberType NoteProperty -Name ExitCodeDescription -Value $ExitCodeDescription

    Return $Result

}
