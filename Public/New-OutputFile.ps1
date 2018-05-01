Function New-OutputFile {
<#

    .SYNOPSIS
    Function intended for preparing a PowerShell object for output files like reports or logs.

    .DESCRIPTION
    Function intended for preparing a PowerShell custom object what contains e.g. file name for output/create files like reports or log. The name is prepared based on prefix, middle name part, suffix, date, etc. with verification if provided path exist and is it writable.

    Returned object contains properties
    - OutputFilePath - to use it please check examples - as a [System.IO.FileInfo]
    - ExitCode
    - ExitCodeDescription

    Exit codes and descriptions
    - 0 = "Everything is fine :-)"
    - 1 = "Provided parent path <PATH> doesn't exist"
    - 2 = "The result name contains unacceptable chars"
    - 3 = "Provided patch <PATH> is not writable"
    - 4 = "The file <PATH>\\<FILE_NAME> already exist - can be overwritten"
    - 5 = "The file <PATH>\\<FILE_NAME> already exist - can't be overwritten"
    - 6 = "The file <PATH>\\<FILE_NAME> already exist - can be overwritten due to used the Force switch"

    .PARAMETER ParentPath
    The folder path what will be used as the parent path for the new created object.
    When non existing path will be provided the error code will be returned.

    By default output files are stored in the current path.

    .PARAMETER OutputFileNamePrefix
    Prefix used for creating output files name

    .PARAMETER OutputFileNameMidPart
    Part of the name which will be used in midle of output file name

    .PARAMETER OutputFileNameSuffix
    Part of the name which will be used at the end of output file name

    .PARAMETER IncludeDateTimePartInOutputFileName
    Set to TRUE if report file name should contains part based on date and time - format yyyyMMdd-HHmm is used

    .PARAMETER DateTimePartInOutputFileName
    Set to date and time which should be used in output file name, by default current date and time is used

    .PARAMETER DateTimePartFormat
    Format string used to format date and time in output file name.

    .PARAMETER OutputFileNameExtension
    Set to extension which need to be used for output file, by default ".txt" is used

    .PARAMETER NamePartsSeparator
    A char used to separate parts in the name, by default "-" is used

    .PARAMETER BreakIfError
    Break function execution if parameters provided for output file creation are not correct or destination file path is not writables

    .PARAMETER Force
    If used the function Doesn't ask for an overwrite decission, assumes that the file can be overwritten

    .EXAMPLE

    PS \> (Get-Item env:COMPUTERNAME).Value
    WXDX75

    PS \> $FileNeeded = @{
        ParentPath = 'C:\USERS\UserName\';
        OutputFileNamePrefix = 'Messages';
        OutputFileNameMidPart = (Get-Item env:COMPUTERNAME).Value;
        IncludeDateTimePartInOutputFileName = $true;
        BreakIfError = $true
    }

    PS \> $PerServerReportFileMessages = New-OutputFile @FileNeeded

    PS \> $PerServerReportFileMessages | Format-List

    OutputFilePath      : C:\users\UserName\Messages-WXDX75-20151021-001205.txt
    ExitCode            : 0
    ExitCodeDescription : Everything is fine :-)

    PS \> New-Item -Path $PerServerReportFileMessages.OutputFilePath -ItemType file

    Directory: C:\USERS\UserName

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    -a----       21/10/2015     00:12              0 Messages-WXDX75-20151021-001205.txt

    The file created on provided parameters.
    Under preparation the file name is created, provided part of names are used, and availability of name (if the file exist now) is checked.

    .EXAMPLE

    $FileNeeded = @{
        ParentPath = 'C:\USERS\UserName\';
        OutputFileNamePrefix = 'Messages';
        OutputFileNameMidPart = 'COMPUTERNAME';
        IncludeDateTimePartInOutputFileName = $false;
        OutputFileNameExtension = "csv";
        OutputFileNameSuffix = "failed"
    }

    PS \> $PerServerReportFileMessages = New-OutputFile @FileNeeded

    PS \> $PerServerReportFileMessages.OutputFilePath | Select-Object -Property Name,Extension,Directory | Format-List

    Name      : Messages-COMPUTERNAME-failed.csv
    Extension : .csv
    Directory : C:\USERS\UserName

    PS \> ($PerServerReportFileMessages.OutputFilePath).gettype()

    IsPublic IsSerial Name                                     BaseType
    -------- -------- ----                                     --------
    True     True     FileInfo                                 System.IO.FileSystemInfo

    PS \> Test-Path ($PerServerReportFileMessages.OutputFilePath)
    False

    The funciton return object what contain the property named OutputFilePath what is the object of type System.IO.FileSystemInfo.

    File is not created. Only the object in the memory is prepared.

    .OUTPUTS
    System.Object[]

    .LINK
    https://github.com/it-praktyk/New-OutputObject

    .LINK
    https://www.linkedin.com/in/sciesinskiwojciech

    .NOTES
    AUTHOR: Wojciech Sciesinski, wojciech[at]sciesinski[dot]net
    KEYWORDS: PowerShell, File, FileSystem

    CURRENT VERSION
    - 0.9.12 - 2018-05-01

    HISTORY OF VERSIONS
    https://github.com/it-praktyk/New-OutputObject/CHANGELOG.md

    LICENSE
    Copyright (c) 2016 Wojciech Sciesinski
    This function is licensed under The MIT License (MIT)
    Full license text: https://opensource.org/licenses/MIT

    #>

    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([System.Object[]])]
    param (
        [parameter(Mandatory = $false)]
        [String]$ParentPath = ".",
        [parameter(Mandatory = $false)]
        [String]$OutputFileNamePrefix = "Output",
        [parameter(Mandatory = $false)]
        [String]$OutputFileNameMidPart = $null,
        [parameter(Mandatory = $false)]
        [String]$OutputFileNameSuffix = $null,
        [parameter(Mandatory = $false)]
        [Bool]$IncludeDateTimePartInOutputFileName = $true,
        [parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DateTimePartInOutputFileName = $null,
        [Parameter(Mandatory = $false)]
        [String]$DateTimePartFormat = "yyyyMMdd-HHmmss",
        [parameter(Mandatory = $false)]
        [String]$OutputFileNameExtension = ".txt",
        [parameter(Mandatory = $false)]
        [alias("Separator")]
        [String]$NamePartsSeparator = "-",
        [parameter(Mandatory = $false)]
        [Switch]$BreakIfError,
        [parameter(Mandatory = $false)]
        [Switch]$Force
    )


    $params = @{

        ObjectType = 'File'

        ParentPath = $ParentPath

        OutputObjectNamePrefix = $OutputFileNamePrefix

        OutputObjectNameMidPart = $OutputFileNameMidPart

        OutputObjectNameSuffix = $OutputFileNameSuffix

        IncludeDateTimePartInOutputObjectName = $IncludeDateTimePartInOutputFileName

        DateTimePartInOutputObjectName = $DateTimePartInOutputFileName

        DateTimePartFormat = $DateTimePartFormat

        OutputFileNameExtension = $OutputFileNameExtension

        NamePartsSeparator = $NamePartsSeparator

        BreakIfError = $BreakIfError

        Force = $Force

    }

    $Result = New-OutputObject @params

    Return $Result
}
