<#  
        .VERSION 1.0
    
        .GUID 99ddbe95-5f75-4191-81d2-33e9e038118e
    
        .DESCRIPTION
        Enumerate user profiles on local and remote computers, and then retrieve users' mapped drives. 

        .AUTHOR
        Richard West
        
        .PROJECTURI 'https://github.com/richardwestseattle/Get-RemoteMappedDrive'
#>

$moduleDefinition =
{
    Function GetUsersList()
    {
            Param([String]$ComputerName)
                 
                #Open HKLM Key.
                $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
                $RegPath = "Software\Microsoft\Windows NT\CurrentVersion\ProfileList";
                $RegKey= $Reg.OpenSubKey($RegPath);

                $userList = @();

                #Enumerate User Profiles
                ForEach($Profile in $RegKey.GetSubKeyNames())
                {
                    #GetSID
                    $SID = $Profile.ToString()

                    #GetUsername
                    $subkey = $RegKey.OpenSubKey($Profile)
                    $bytes = [System.Text.Encoding]::Ascii.GetBytes($subkey.GetValue("ProfileImagePath")) 
                    $username = ([System.Text.Encoding]::ASCII.GetString($bytes)).Split("\")[2]

                    #Create a psobject (associative array) and assign values.
                    $item = New-Object psobject
                    $item | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $ComputerName
                    $item | Add-Member -NotePropertyName "SID" -NotePropertyValue $SID
                    $item | Add-Member -NotePropertyName "USERNAME" -NotePropertyValue $username

                    $userList += $item;
            }
            return $userList;
    }

    Function GetMappedDrives()
    {    
        Param([String]$ComputerName)
         
        $DrivesScanResults = @()
        $userList = GetUsersList -ComputerName $ComputerName

        ForEach($UserProfile in $userList)
        {
                    try
                    {
                        #Open User's Registry Hive.
                        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', $UserProfile.ComputerName)
                        $RegPath = "$($UserProfile.SID)\NETWORK";
                        $RegKey= $Reg.OpenSubKey($RegPath);
                    }
                    catch
                    {
                        continue;
                    }

                    #If the key is not null.
                    if($RegKey)
                    {
                        #Iterate over all subkeys.
                        ForEach($key in $RegKey.GetSubKeyNames())
                        {
                            try
                            {
                                $DriveKey = $Reg.OpenSubKey("$($RegPath)\$($key)");

                                #Create a psobject (associative array) and assign values.
                                $item = New-Object psobject;
                                $item | Add-Member -NotePropertyName "ScanDate" -NotePropertyValue (Get-Date -Format yyyy-MM-dd-HH-mm-ss).ToString() 
                                $item | Add-Member -NotePropertyName "UserName" -NotePropertyValue $UserProfile.USERNAME;
                                $item | Add-Member -NotePropertyName "SID" -NotePropertyValue $UserProfile.SID;
                                $item | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $UserProfile.ComputerName;
                                $item | Add-Member -NotePropertyName "Letter" -NotePropertyValue $key;
                                $item | Add-Member -NotePropertyName "RemotePath" -NotePropertyValue $DriveKey.GetValue("RemotePath");
                                                              
                                #Append to the array of Results.
                                $DrivesScanResults += $item;
                            }
                            catch
                            {
                                continue;
                            }
                        }
                    }

                    if($Reg)
                    {
                        $Reg.Close();
                    }
                    else
                    {
                        #nothing;
                    }
            
        }
        return $DrivesScanResults;
    }
}

Function PrintStatus()
{
    Param([int]$NumOfItems,
    [Parameter(Mandatory = $false)][int]$runningjobsCount)

    $completedjobs = (get-job -State Completed).Count

    if(!$runningjobsCount)
    {
        $runningjobsCount = (get-job -State Running).Count
    }

    Write-Host "[Running Jobs: $($runningjobsCount)]/[Completed Jobs: $($completedjobs)])" 
}

Function ThrottleJobs()
{
    Param([Parameter(Mandatory=$true)][int]$NumOfItems,
    [Parameter(Mandatory=$true)][int]$maxConcurrentJobs,
    [Parameter(Mandatory=$true)][int]$timeLimitperJob)

    while((Get-Job -State Running).Count -ge $maxConcurrentJobs)
    {               
        $runningjobs = get-job -State Running

        PrintStatus -NumOfItems $NumOfItems

        foreach($job in $runningjobs)
        {
            #dispose of jobs that are stuck. Time limit is defined at start of script. 
            if(((get-date).AddMinutes(-$timeLimitperJob) -ge $job.PSBeginTime))
            {
                $job.StopJob();
                $job.Dispose();
            }
        }
        start-sleep 1
    }
}

function WaitforCompletion()
{
    Param([Parameter(Mandatory=$true)][int]$NumOfItems,
    [Parameter(Mandatory=$true)][int]$timeLimitperJob,
    [Parameter(Mandatory=$true)][bool]$showStatus)

    #Wait for running jobs to complete.
    while(get-job -State Running)
    {
        $runningjobs = (get-job -State Running)

        if($showStatus)
        {
            PrintStatus -NumOfItems $NumOfItems -runningjobsCount ($runningjobs).Count
        }

        foreach($job in $runningjobs)
        {
            #dispose of jobs that are stuck. Time limit is defined at start of script. 
            if(((get-date).AddMinutes(-$timeLimitperJob) -ge $job.PSBeginTime))
            {
                $job.StopJob();
                $job.Dispose();
            }
        }
        Start-Sleep 1
    }
}

Function CancelOutStandingJobs()
{
    $runningjobs = get-job -State Running

    foreach($job in $runningjobs)
    {
        $job.StopJob();
        $job.Dispose();
    }
    get-job | remove-job
}

Function Get-RemoteMappedDrive()
{
<#  
        .SYNOPSIS
        Enumerate user profiles on local and remote computers, and retrieve the users' mapped drives.

        .DESCRIPTION
        Enumerate user profiles on local and remote computers, and retrieve the users' mapped drives. 

        Author: Richard West

        Contact: richard@premiumsource.solutions

        .INPUTS
        [String[]] #Computer Name(s).

        .OUTPUTS
        [PSOBJECT]
            #Properties:
                [String]ScanDate #Format yyyy-MM-dd-HH-mm-ss
                [String]UserName
                [String]SID
                [String]ComputerName
                [String]Letter
                [String]RemotePath

        .PARAMETER ComputerList
        String, or String[] of computer names.

        .PARAMETER maxConcurrentJobs
        [int]Max number of allowed parallel background jobs. Default value is 20.

        .PARAMETER timeLimitperJob
        [int]Max number of minutes allowed for each background job. Jobs that exceed threshold are cancelled. Default value is 1.

        .PARAMETER showStatus
        [switch]Write scan status to console. 

        .EXAMPLE
        Get All Users' Mapped Drives on Computer, "MyComputerName". Format output as a table.
    
        PS> Get-RemoteMappedDrive -ComputerName "MyComputerName"| Select-Object UserName, ComputerName, Name, Value, ScanDate | Format-Table


        .EXAMPLE
        Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2".
    
        PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" | Select-Object UserName, ComputerName, Name, Value, ScanDate | Format-Table


        .EXAMPLE
        Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2". Export to CSV.
    
        PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" | Select-Object UserName, ComputerName, Name, Value, ScanDate | Export-CSV -NoTypeInformation -Path "$($PSScriptRoot)\drives.csv"


        .EXAMPLE
        Get All Users' Mapped Drives on Computers, "ComputerName1" and "ComputerName2". Configure [int]maxConcurrentJobs and [int]timeLimitperJob.
    
        PS> Get-RemoteMappedDrive -ComputerName "ComputerName1", "ComputerName2" -maxConcurrentJobs 10 -timeLimitperJob 2

        .EXAMPLE
        Pipe computer names into Get-RemoteMappedDrive
    
        PS> $ComputerList = "Computer1", "Computer2", "Computer3"
        PS> $ComputerList | Get-RemoteMappedDrive -showStatus

        .LINK
        Project URI: 'https://github.com/richardwestseattle/Get-RemoteMappedDrive'
        Website: 'http://premiumsource.solutions'
        Contact: 'richard@premiumsource.solutions'

#>


    [cmdletbinding()]

    Param([Parameter(Mandatory=$true, ValueFromPipeline = $true,Position=0, ValueFromPipelineByPropertyName)][Alias('MachineName', 'ComputerNames')][String[]]$ComputerName,
    [Parameter(Mandatory=$false)][int]$maxConcurrentJobs,
    [Parameter(Mandatory=$false)][int]$timeLimitperJob,
    [switch]$showStatus)

    Begin
        {
        if(!$maxConcurrentJobs)
        {
            [int]$maxConcurrentJobs = 20
        }
        if($null -eq $showStatus)
        {
            $showStatus = $FALSE;
        }
        if(!$timeLimitperJob)
        {
            [int]$timeLimitperJob = 1
        }

        $arrayofJobs = @();
        $arrayofData = @();      

        CancelOutStandingJobs
    }
    Process
        {
        ForEach($computer in $ComputerName)
        {
            if(Test-Connection $computer -Quiet -Count 1)
            {
                if($showStatus -and ($computer.Length)%5 -eq 0)
                {
                   PrintStatus -NumOfItems $ComputerName.Length
                }

                #Call function to assess job count, and throttle if applicable.   
                ThrottleJobs -NumOfItems $ComputerName.Length -maxConcurrentJobs $maxConcurrentJobs -timeLimitperJob $timeLimitperJob

                #Call the GetMappedDrives function.
                    $arrayofJobs += 
                    Start-Job -Name $computer -ScriptBlock{
                        $modDef = [ScriptBlock]::Create($Using:moduleDefinition)    
                        New-Module -Name MyFunctions -ScriptBlock $modDef | out-null; 

                        GetMappedDrives @args
                    } -ArgumentList $computer
            }
            else
            {
                if($showStatus)
                {
                    Write-Host "`nComputer: '$($computer)' is offline"
                }
                
                continue;
            }
        }
    }
    End
        {
        WaitforCompletion -NumOfItems ($ComputerName.Length) -timeLimitperJob $timeLimitperJob -showStatus $showStatus;

        if($showStatus)
        {
            PrintStatus -NumOfItems $ComputerName.Length
        }

            foreach($job in $arrayofJobs)
            {
            
                $arrayofData += Receive-Job -Name $job.Name       
            }
    
        CancelOutStandingJobs
        return $arrayofData | Select-Object UserName, SID, ComputerName, Letter, RemotePath, ScanDate;
    }
}

Export-ModuleMember -Function Get-RemoteMappedDrive