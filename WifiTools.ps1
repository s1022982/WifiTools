﻿class WiFiState
{
    [string]$IPv4Address
    [string]$IPv6Address
    [string]$SSID
    [string]$BSSID
    [string]$State
    [string]$Authentication
    [string]$Channel
    [string]$Signal
    [string]$RxRate
    [string]$TxRate
    [datetime]$StateTime
}


function Show-WifiState()
{
<#

.DESCRIPTION
   This function will diplay the current wireless connection state.
   Displayed information based on built in Windows command:
   netsh wlan show interfaces


.EXAMPLE
    Show-WifiState
#>



    $SelectedAdapter=netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}} | Where-Object {$_.Name -like "Wi*"}
    #$SelectedAdapter=Get-NetAdapter | Where-Object {$_.Name -like "Wi*"}
        [WifiState]$CurrentState=[WiFiState]::new()
        $CurrentState.StateTime=get-date
        $FullStat=$(netsh wlan show interfaces)
        $CurrentState.IPv4Address=(Get-InterfaceIP $SelectedAdapter.Name).IPv4Address
        $CurrentState.IPv6Address=(Get-InterfaceIP $SelectedAdapter.Name).IPv6Address
        $FullStat=$FullStat.split("`n")
        foreach($nextLine in $FullStat)
        {
            if($nextLine -match "^    SSID\s{10,35}:\s(.*)"){$CurrentState.SSID=$Matches[1]}
            if($nextLine -match "^    BSSID\s{10,35}:\s(.*)"){$CurrentState.BSSID=$Matches[1]}
            if($nextLine -match "^    State\s{10,35}:\s(.*)"){$CurrentState.State=$Matches[1]}
            if($nextLine -match "^    Authentication\s{5,35}:\s(.*)"){$CurrentState.Authentication=$Matches[1]}
            if($nextLine -match "^    Channel\s{10,35}:\s(.*)"){$CurrentState.Channel=$Matches[1]}
            if($nextLine -match "^    Signal\s{10,35}:\s(.*)"){$CurrentState.Signal=$Matches[1]}
            if($nextLine -match "^    Receive\srate\s\(Mbps\)\s{2,15}:\s(.*)"){$CurrentState.RxRate=$Matches[1]}
            if($nextLine -match "^    Transmit\srate\s\(Mbps\)\s{2,15}:\s(.*)"){$CurrentState.TxRate=$Matches[1]}


        }


        return $CurrentState

}




function Monitor-WifiState()
{
<#

.DESCRIPTION
   This function will help you to monitor wireless connection.

.PARAMETER refreshTime
   Set refresh time.

.PARAMETER LogMode
    Switch between monitor and log mode.

.EXAMPLE
   Monitor-WifiState 5
   Monitor-WifiState -refreshTime 5

   Will dispaly and refresh wirless connection state in every 5 sec.

.EXAMPLE
   Monitor-WifiState 5 -LogMode
   Monitor-WifiState -refreshTime 5 -LogMode

   Will dispaly and refresh a log about wirless connection state in every 5 sec.


#>

    param([Parameter(Mandatory=$true)][int]$refreshTime, [switch]$LogMode=$false)


        while($true)
        {

             $CurrentState=Show-WifiState

             if($LogMode -eq $true)
             {
                $($CurrentState | Format-Table -HideTableHeaders | Out-String).trim() | DateEcho

             }
             else
             {
                Clear-host
                $CurrentState | Write-Output
             }


            sleep $refreshTime
        }

}

Function Get-PublicIP()
{
<#

.DESCRIPTION
   This function will return with IPv4 public address

   This function need live internet connection, otherwise will throw an exception.

.EXAMPLE
    Get-PublicIP

    Get-PublicIP -ipv6

#>
	param([Switch]$ipv6=$false)

	if(-not $ipv6)
	{
		$Uri = 'ipv4bot.whatismyipaddress.com'
		Invoke-WebRequest -Uri $Uri -UseBasicParsing -DisableKeepAlive | Select-Object -ExpandProperty Content
	}
	else
	{
		$Uri = 'ipv6bot.whatismyipaddress.com'
		Invoke-WebRequest -Uri $Uri -UseBasicParsing -DisableKeepAlive | Select-Object -ExpandProperty Content

	}

}
function Export-WifiProfiles
{
<#

.DESCRIPTION
   This function can help you to export all stored wifi profile to current folder

.EXAMPLE
   It will export all profile to current folder
   Export-WifiProfiles

   It will export only the specified profile to current folder.
   Export-WifiProfiles -ProfileName SSID_profile_name
#>
    [CmdletBinding()]
    param()
    DynamicParam {
        $ParameterName="ProfileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        return $RuntimeParameterDictionary

    }
    begin{
        $ProfileName = $PsBoundParameters[$ParameterName]
    }
    process{
        if($ProfileName -ne $null){
            netsh wlan export profile name="$ProfileName" folder=$((get-location).path)
        }
        else{
            netsh wlan export profile folder=$((get-location).path)
        }
    }

    

}

function Import-WifiProfiles
{
<#

.DESCRIPTION
   This function can help you to import all stored wifi profile from current folder

.EXAMPLE
   It will Import all profile to current folder
   Import-WifiProfiles

   It will Import only the specified profile to current folder.
   Import-WifiProfiles -ProfileNameXml WiFi-SSID_Name.xml
#>

    [CmdletBinding()]
    param()
    DynamicParam {
        $ParameterName="ProfileNameXml"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = (ls *.xml).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        return $RuntimeParameterDictionary

    }
    begin{
        $ProfileNameXml = $PsBoundParameters[$ParameterName]
    }
    process{
        if($ProfileNameXml -ne $null){
            ls $ProfileNameXml | &{process{netsh wlan add profile filename="$($_.fullname)" user=all}}
        }
        else{
            
            ls *.xml | &{process{netsh wlan add profile filename="$($_.fullname)" user=all}}
        }
    }
}

function Disable-WifiProfiles
{
<#
.DESCRIPTION
   This function can help you to disable all stored wifi profile. 
   The will be exported and stored under temp folder as xml than delete from Windows.

.EXAMPLE
   It will Disable all profile to current folder
   Disable-WifiProfiles
#>

   $currentlocation=Get-Location
   cd $env:TEMP
   mkdir DisabledWifiProfiles  -ErrorAction Ignore
   cd DisabledWifiProfiles

   Export-WifiProfiles
   Delete-WifiProfiles
      
   cd $currentlocation
}

function Enable-WifiProfiles
{
<#
.DESCRIPTION
   This function can help you to enable all previously disabled wifi profile. 
   The will be import profiles from previously stored location.

.EXAMPLE
   It will Enable all profile to current folder
   Enable-WifiProfiles
#>

   $currentlocation=Get-Location
   cd $env:TEMP
   cd DisabledWifiProfiles  

   Import-WifiProfiles
   rm *
    
   cd $currentlocation
}

Function Show-WifiProfilePassword
{
    <#

.DESCRIPTION
   This function can show the password for specified wifi profile

.EXAMPLE
   It will export all profile to current folder
   Export-WifiProfiles

   It will export only the specified profile to current folder.
   Export-WifiProfiles -ProfileName SSID_profile_name
#>
    [CmdletBinding()]
    param()
    DynamicParam {
        $ParameterName="ProfileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        return $RuntimeParameterDictionary

    }
    begin{
        $ProfileName = $PsBoundParameters[$ParameterName]
    }
    process{
        $currentlocation=Get-Location
        cd $env:TEMP
        mkdir TempWifiProfiles -ErrorAction Ignore
        cd TempWifiProfiles
    
        netsh wlan export profile name="$ProfileName" folder=$((get-location).path) key=clear >$null 2>&1
        [XML]$WifiProfileXmlDoc = (ls *$ProfileName* | Get-Content)
        $ssidPwd=$WifiProfileXmlDoc.WLANProfile.MSM.security.sharedKey.keyMaterial

        rm *$ProfileName*
        cd $currentlocation
        return $ssidPwd
    }
   
}
function Disable-NetworkInterface()
{
<#

.DESCRIPTION
   This function can help you to disable wifi or ethernet interface


.PARAMETER InterfaceName
   You can specify the exact interface name, that need to be disabled

.EXAMPLE
   Disable-NetworkInterface -InterfaceName "WiFi 3"

   
#>

    [CmdletBinding()]
    param()

    DynamicParam {
     
        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        #$arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $arrSetInterface=(netsh interface show interface | select-string -Pattern "([a-zA-Z0-9]*\s{2,}){3}(.*)" | Select-Object -Skip 1| &{process{[pscustomobject]@{Name=$_.matches[0].groups[2].value}}}).Name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)

        return $RuntimeParameterDictionary
    }
    begin{
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process{
        netsh interface set interface "$SelectedInterface" disable
      
    }
}
function Enable-NetworkInterface()
{
<#

.DESCRIPTION
   This function can help you to enable already disabled wifi or ethernet interface


.PARAMETER InterfaceName
   You can specify the exact interface name, that need to be enabled

.EXAMPLE
   Enable-NetworkInterface -InterfaceName "WiFi 3"

   
#>

    [CmdletBinding()]
    param()

    DynamicParam {
     
        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        #$arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $arrSetInterface=(netsh interface show interface | select-string -Pattern "([a-zA-Z0-9]*\s{2,}){3}(.*)" | Select-Object -Skip 1| &{process{[pscustomobject]@{Name=$_.matches[0].groups[2].value}}}).Name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)

        return $RuntimeParameterDictionary
    }
    begin{
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process{
        netsh interface set interface "$SelectedInterface" enable
      
    }
}



function Connect-WiFi()
{
<#

.DESCRIPTION
   This function can help you to connet specified wireless network.


.PARAMETER ProfileName
   You can specify the exact profile name, where you want to connect.

.EXAMPLE
   Connect-WiFi -ProfileName TP007

   Connection will be proceed only if profile exists.

.EXAMPLE
   Connect-WiFi -ProfileName TP007 -InterfaceName Wi-Fi

   Connection will be procced, if profile exists on the specified interface.
#>
    [CmdletBinding()]
    param()

    DynamicParam {
        $ParameterName="ProfileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{
        $ProfileName = $PsBoundParameters[$ParameterName]
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process{
        $allProfiles=$(netsh wlan show profiles)
        $IsProfileExist=$false
        foreach($nextline in $allProfiles)
        {
            if($nextline -match "^.*Profile\s*:\s$ProfileName$")
            {
                $IsProfileExist=$true
            }
        }
        if($IsProfileExist)
        {
            if($SelectedInterface -eq $null)
            {
                #$SelectedInterface=get-netadapter  | where-Object {$_.PhysicalMediaType -eq "Native 802.11"}|Select-Object -First 1 | & {process{return $_.Name}}
                $SelectedInterface=netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}} | Where-Object {$_.Name -like "Wi*"}|Select-Object -First 1 | & {process{return $_.Name}}
            }
            netsh wlan connect name=$ProfileName interface=$SelectedInterface
        }
        else
        {
            Write-host "Network profile does not exists."
        }
    }
}
function Connect-WifibyBssid()
{
<#

.DESCRIPTION
   This function can help you to connet specified wireless network based on BSSID


.PARAMETER ProfileName
   You can specify the exact profile name and the BSSID where you want to connect.

.EXAMPLE
   Connect-WiFi -ProfileName TP007 -

   Connection will be proceed only if profile exists.

.EXAMPLE
   Connect-WifibyBssid -ProfileName TP007 -InterfaceName Wi-Fi -APMac AA:BB:CC:DD:EE:FF

   Connection will be procced, if profile exists on the specified interface and BSSID is available.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=3,HelpMessage="Please provide mac address for targeted AP")][string]$APMac
    )

    DynamicParam {
        $ParameterName="ProfileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{
        $ProfileName = $PsBoundParameters[$ParameterName]
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process{

        $managedwifilib=[Reflection.Assembly]::LoadFile("$PSScriptRoot\ManagedWifi.dll")


        $wificlient = New-Object NativeWifi.WlanClient
        $selectedIf=$null

        foreach($nextif in $wificlient.Interfaces)
        {
            if($nextif.InterfaceName -eq $SelectedInterface)
            {
                $selectedIf=$nextif
            }
        }
        $selectedIf.Connect($APMac, $ProfileName)

    }


}

function Clear-WifiLog()
{
<#

.DESCRIPTION
   This function will wifi related logs from Windows under "Microsoft-Windows-WLAN-AutoConfig/Operational"


.EXAMPLE
   Clear-WifiLog

#>
    [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog("Microsoft-Windows-WLAN-AutoConfig/Operational") 

}


function Export-WifiLog()
{
<#

.DESCRIPTION
   This function will export all wifi related logs stored on Windows Under 


.PARAMETER StartTime
   You can speficy start time where log will be exported from. The default value is "1970-01-01 00:00"

.PARAMETER EndTime
   You can speficy end time where log will be exported till. The default value is Current time

.PARAMETER FileName
   You can speficy a file name without extension where log will be exported to. The default value is "WifiLogs"

.PARAMETER FileName
   You can speficy a file name without extension where log will be exported to. The default value is "WifiLogs"

.PARAMETER Xml
   You can export log to XML, the default is csv.


.EXAMPLE
   Export-WifiLog
   Export-WifiLog -Xml
   Export-WifiLog -Xml -FileName WifiLogFile
   Export-WifiLog -FileName WifiLogFile -StartTime "2019-01-01 00:00"
#>

    param(
        [Parameter(Mandatory=$false, HelpMessage="Please define the start time when wifi log can be deleted")][String]$StartTime="1970-01-01 00:00", 		
        [Parameter(Mandatory=$false, HelpMessage="Please define the end time when wifi log can be deleted")][String]$EndTime=$true, 
        [Parameter(Mandatory=$false, HelpMessage="Please define the name of the file where log will be stored")][String]$FileName="WifiLogs", 
	    [Parameter()][switch]$Xml
	)
    
    $StartTime = [datetime]::ParseExact($StartTime,'yyyy-MM-dd HH:mm',$null)
    
    if($EndTime -eq $true){
        $EndTime=Get-Date
    }
    else{
        $EndTime = [datetime]::ParseExact($EndTime,'yyyy-MM-dd HH:mm',$null)
    }

    if($Xml){
        Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational |Where-Object { $_.TimeCreated -ge $StartTime -and $_.TimeCreated -lt $EndTime }| &{process{[pscustomobject]@{TimeCreated = $_.TimeCreated; Id = $_.Id; LevelDisplayName= $_.LevelDisplayName; Message=$_.Message }}}|  Export-Csv -Path $FileName".csv" -NoTypeInformation
    }
    else{
        Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational |Where-Object { $_.TimeCreated -ge $StartTime -and $_.TimeCreated -lt $EndTime }| &{process{[pscustomobject]@{TimeCreated = $_.TimeCreated; Id = $_.Id; LevelDisplayName= $_.LevelDisplayName; Message=$_.Message }}}|  Out-File -FilePath $FileName".txt"
    }
}


function Get-WifiLog()
{
<#

.DESCRIPTION
   This function will list all wifi related logs stored on Windows Under 


.PARAMETER ProfileName
   You can speficy if only errors need to be displayed

.EXAMPLE
   Get-WifiLog

   Get-WifiLog -OnlyError
#>


    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=1,HelpMessage="Filtering to error with this log")][switch]$OnlyError=$false

    )

    if($OnlyError)
    {
        Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational | where LevelDisplayName -EQ Error
    }
    else
    {
        Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational
    }
}



function Monitor-WifiLog()
{
 <#

.DESCRIPTION
   This function will monitor all wifi related logs being created from start time.


.PARAMETER ProfileName
   You can speficy if only errors need to be displayed

.EXAMPLE
   Monitor-WifiLog

   Monitor-WifiLog -OnlyError
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=1,HelpMessage="Filtering to error with this log")][switch]$OnlyError=$false

    )
    $lastevent=Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational | select -first 1

    #for($i=0; $i -lt 3600;$i++)
    while($true)
    {
        $newevent=Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational | select -first 1

        if ($lastevent.TimeCreated -ne $newevent.TimeCreated)
        {
            if($OnlyError)
            {
                $newevents=Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational | select -first 10 | where LevelDisplayName -eq "Error"|where TimeCreated -gt $lastevent.timecreated
            }
            else
            {
                $newevents=Get-WinEvent -Logname Microsoft-Windows-WLAN-AutoConfig/Operational | select -first 10 | where TimeCreated -gt $lastevent.timecreated
            }
            foreach ($nextevent in $newevents)
            {
                if($nextevent.TimeCreated -ne $lastevent.TimeCreated)
                {
                    $shortmessage=$nextevent.Message.split("`n")[0]
                    write-host ('{0} {1} {2} {3}' -f ($nextevent.TimeCreated.ToString()).padright(23, ' '), $nextevent.Id.ToString().padright(10, ' '), $nextevent.LevelDisplayName.ToString().padright(15, ' '), $shortmessage)

                }
            }
            $lastevent=$newevent[0]
        }

       sleep 1

    }
}



function List-WifiProfiles()
{
<#

.DESCRIPTION
   This function can help you to list available wireless profiles.


.PARAMETER profileName
   You can specify the exact profile to list profiles.
.PARAMETER profileRegex
   You can specify a regex pattern to list profiles.
.PARAMETER profileContain
   You can specify a string that profile name must contain to list.
.PARAMETER profileWildCard
   You can specify a wildcard to list profiles.

.EXAMPLE
   List-WifiProfiles -profileName TP007

.EXAMPLE
   List-WifiProfiles -profileRegex TP.*$

.EXAMPLE
   List-WifiProfiles -profileContain TP

.EXAMPLE
   List-WifiProfiles -profileWildCard T*07

#>
    param($profileName, $profileRegex, $profileContain, $profileWildCard)

    $AllProfiles=$(netsh wlan show profiles)

        if(-not ($profileName -eq "" -or $profileName -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *" -and $nextLine.split(":")[1] -eq " $profileName") {Write-Host $nextLine}

            }
        }
        elseif(-not ($profileContain -eq "" -or $profileContain -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -like "*$profileContain*")
                    {
                        Write-Host $nextLine
                    }
                }
            }
        }
        elseif(-not($profileRegex -eq "" -or $profileRegex -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -match $profileRegex)
                    {
                        Write-Host $nextLine
                    }
                }
            }
        }
        elseif(-not($profileWildCard -eq "" -or $profileWildCard -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -like "?$profileWildCard")
                    {
                        Write-Host $nextLine
                    }
                }
            }
        }
        else
        {
            Write-Host ($AllProfiles | Out-String)
        }


}

function Delete-WifiProfiles()
{
<#

.DESCRIPTION
   This function can help you to delete wireless profiles.


.PARAMETER profileName
   You can specify the exact profile to delete profiles.
.PARAMETER profileRegex
   You can specify a regex pattern to delete profiles.
.PARAMETER profileContain
   You can specify a string that profile name must contain to delete.
.PARAMETER profileWildCard
   You can specify a wildcard to delete profiles.

.EXAMPLE
   Delete-WifiProfiles -profileName TP007

.EXAMPLE
   Delete-WifiProfiles -profileRegex TP.*$

.EXAMPLE
   Delete-WifiProfiles -profileContain TP

.EXAMPLE
   Delete-WifiProfiles -profileWildCard T*07

#>
    [CmdletBinding()]
    param( $profileRegex, $profileContain, $profileWildCard)
    DynamicParam {
        $ParameterName="profileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin{
        $profileName = $PsBoundParameters[$ParameterName]
    }


    process{
        $AllProfiles=$(netsh wlan show profiles)

        if(-not ($profileName -eq "" -or $profileName -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *" -and $nextLine.split(":")[1] -eq " $profileName")
                {
                    $ProfielToDelete=$nextLine.split(":")[1].Trim(" ")
                    netsh wlan delete profile $ProfielToDelete
                }
            }
        }
        elseif(-not ($profileContain -eq "" -or $profileContain -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -like "*$profileContain*")
                    {
                        $ProfielToDelete=$nextLine.split(":")[1].Trim(" ")
                        netsh wlan delete profile $ProfielToDelete
                    }
                }
            }
        }
        elseif(-not($profileRegex -eq "" -or $profileRegex -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -match $profileRegex)
                    {
                        $ProfielToDelete=$nextLine.split(":")[1].Trim(" ")
                        netsh wlan delete profile $ProfielToDelete
                    }
                }
            }
        }
        elseif(-not($profileWildCard -eq "" -or $profileWildCard -eq $null))
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    if($nextLine.split(":")[1] -like "?$profileWildCard")
                    {
                        $ProfielToDelete=$nextLine.Trim(" ")
                        netsh wlan delete profile $ProfielToDelete
                    }
                }
            }
        }
        else
        {
            foreach($nextLine in $AllProfiles)
            {
                if($nextLine -like "* : *")
                {
                    $ProfielToDelete=$nextLine.split(":")[1].Trim(" ")
                    netsh wlan delete profile $ProfielToDelete
                }
            }
        }

    }
}

Function Show-WifiInterface()
{
<#

.DESCRIPTION
   This funtcion will display the same information that "netsh wlan show interfaces command" do.

.EXAMPLE
   Show-WifiInterface

#>
    netsh wlan show interfaces
}

Function Show-IPConfig
{
<#

.DESCRIPTION
   This function display the same information as the traditional ipconfig /all,
   but in userfriendly filterable format.

.PARAMETER Interface
   Specifies the nam of the interface.


.EXAMPLE
   Show-IPConfig -interface Ethernet
   Show-IPConfig Eth

   You can use only part of the full interface name.

   get-netAdapter command will list the available network intrafaces.

#>
    [CmdletBinding()]
    param()

    DynamicParam {
        $ParameterName="Interface"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0
        $AttributeCollection.Add($ParameterAttribute)
        #$arrSet = (Get-NetAdapter).Name
        $arrSet = (netsh interface show interface | select-string -Pattern "([a-zA-Z0-9]*\s{2,}){3}(.*)" | Select-Object -Skip 1| &{process{[pscustomobject]@{Name=$_.matches[0].groups[2].value}}}).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin{
        $Interface = $PsBoundParameters[$ParameterName]
    }


    Process{
        $AllAdapters=(netsh interface show interface | select-string -Pattern "([a-zA-Z0-9]*\s{2,}){3}(.*)"| Select-Object -Skip 1 | &{process{[pscustomobject]@{Name=$_.matches[0].groups[2].value}}}        )
        $SelectedAdapter= $AllAdapters | Where-Object {$_.Name -eq $Interface}
        
        #$SelectedAdapter=Get-NetAdapter | Where-Object {$_.Name -eq $Interface}
        
        $Interface=$SelectedAdapter.Name

        $AllIpConifig=$(ipconfig /all)
        $needToPrintNextLine=$false
        $ignoreWhiteSpace=$false
        foreach($nextline in $AllIpConifig)
        {
            if($ignoreWhiteSpace -eq $true)
            {
                Write-Host $nextline
                $ignoreWhiteSpace=$false
            }
            else
            {
                if($nextline -match "^(?!\s).*")
                {
                    if($nextline -match "^.*$($Interface):$")
                    {
                        Write-Host $nextline
                        $needToPrintNextLine=$true
                        $ignoreWhiteSpace=$true
                    }
                    else
                    {
                        $needToPrintNextLine=$false
                        $ignoreWhiteSpace=$false
                    }


                }
                else
                {
                    if($needToPrintNextLine)
                    {
                        Write-Host $nextline
                    }
                }
            }
        }
    }
}

function Release-Renew-IP()
{
<#

.DESCRIPTION
   This funtcion Will proceed the complete dhcp release renew cycle


.EXAMPLE
    Release-Renew-IP

#>
    ipconfig /release
    sleep 5
    ipconfig /renew
}

function Disconnect-Wifi()
{
<#

.DESCRIPTION
   This funtcion Will disconnect from current wireless network



.EXAMPLE
   Disconnect-Wifi

.EXAMPLE
   Disconnect-Wifi -interface Wi-Fi

#>
    [CmdletBinding()]
    param()

     DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 1
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{

        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }

    process{
        if($SelectedInterface -eq $null)
        {
            #$SelectedInterface=get-netadapter  | where-Object {$_.PhysicalMediaType -eq "Native 802.11"}  |Select-Object -First 1 | & {process{return $_.Name}}
            $SelectedInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}} | Where-Object {$_.Name -like "Wi*"}|Select-Object -First 1).name
        }
        netsh wlan disconnect interface=$SelectedInterface
    }

}


function Create-WifiProfile()
{
    <#

.DESCRIPTION
   This funtcion Will create a Wireless Profile

.PARAMETER WLanName
   Define SSID for the wireless network.
.PARAMETER Passwd
   Define the secretkey of wireless network.
.PARAMETER WPA
   This switch can help to generate a WPA profile(Default:WPA2)


.EXAMPLE
   Create-WifiProfile -WlanName "MyNetworkName" -Passwd "networkpassword"
   Create-WifiProfile "MyNetworkName" "networkpassword"

   These command will generate a WPA2 wireless profile with the defined name and password.

.EXAMPLE
    Create-WifiProfile -WlanName MyOpenWifiNetwork

    This command will generate a profile for unprotected wireless network.

.EXAMPLE
    Create-WifiProfile -WlanName "MyNetworkName" -Passwd "networkpassword" -WPA
    Create-WifiProfile "MyNetworkName" "networkpassword" -WPA
    Create-WifiProfile "MyNetworkName" "networkpassword" -WPA -PHYType ac

    These command will generate a WPA wireless profile with the defined name and password.
#>
    [CmdletBinding()]
    param([Parameter(Mandatory=$true, HelpMessage="Please add Wireless network name")]
    [string]$WLanName,
    [string]$Passwd,
    [Parameter(Mandatory=$false, HelpMessage="This switch will generate a WPA profile instead of WPA2")]
    [switch]$WPA=$false)


      DynamicParam {
        $ParameterName="PHYType"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $false
        $ParameterAttribute.Position = 4
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = "b", "g", "n","a", "ac"
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        return $RuntimeParameterDictionary
    }
    begin{
        $PHYType = $PsBoundParameters[$ParameterName]
    }
    process{
        if($PHYType -ne $null){
            $PHYRestriction="<connectivity><phyType>$PHYType</phyType></connectivity>"
            
        }
        else{
            $PHYRestriction=""
        }
    





        if($WPA -eq $false)
        {
            $WpaState="WPA2PSK"
            $EasState="AES"
        }
        else
        {
            $WpaState="WPAPSK"
            $EasState="AES"
        }


$XMLProfile= @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
      <name>$WlanName</name>
      <SSIDConfig>
         <SSID>
              <name>$WLanName</name>
          </SSID>
     </SSIDConfig>
     <connectionType>ESS</connectionType>
     <connectionMode>auto</connectionMode>
     <MSM>
        $PHYRestriction
         <security>
             <authEncryption>
                 <authentication>$WpaState</authentication>
                 <encryption>$EasState</encryption>
                 <useOneX>false</useOneX>
             </authEncryption>
             <sharedKey>
                 <keyType>passPhrase</keyType>
                 <protected>false</protected>
				<keyMaterial>$Passwd</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>
"@

        if($Passwd -eq "")
                                                                                                        {
$XMLProfile= @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$WLanName</name>
	<SSIDConfig>
		<SSID>
			<name>$WLanName</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
        $PHYRestriction
		<security>/
			<authEncryption>
				<authentication>open</authentication>
				<encryption>none</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
	</MacRandomization>
</WLANProfile>


"@
    }


       $currentlocation=Get-Location
       cd $env:TEMP
       $TempLocation=Get-Location
       $XMLProfile | Set-Content "$WLanName.xml"
       Netsh WLAN add profile filename=$TempLocation\$WLanName.xml
       remove-item "$WLanName.xml"
       cd $currentlocation

   }
}

function Create-W4AWifiProfile()
{
<#

.DESCRIPTION
   This funtcion Will create a W4A Wireless Profile.

.PARAMETER NetworkName
   Specifies custom name for W4A network


.EXAMPLE
   Create-W4AProfile "Custom Wi-Free"

#>
    param($NetworkName)
    if($NetworkName -eq $null)
    {
        $NetworkName = "Horizon Wi-Free"
    }
$XMLProfile= @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$NetworkName</name>
	<SSIDConfig>
		<SSID>

			<name>$NetworkName</name>
		</SSID>
		<nonBroadcast>false</nonBroadcast>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<autoSwitch>false</autoSwitch>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2</authentication>
				<encryption>AES</encryption>
				<useOneX>true</useOneX>
				<FIPSMode xmlns="http://www.microsoft.com/networking/WLAN/profile/v2">false</FIPSMode>
			</authEncryption>
			<PMKCacheMode>enabled</PMKCacheMode>
			<PMKCacheTTL>720</PMKCacheTTL>
			<PMKCacheSize>128</PMKCacheSize>
			<preAuthMode>disabled</preAuthMode>
			<OneX xmlns="http://www.microsoft.com/networking/OneX/v1">
				<cacheUserData>true</cacheUserData>
				<authMode>user</authMode>
				<EAPConfig><EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapMethod><Type xmlns="http://www.microsoft.com/provisioning/EapCommon">25</Type><VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId><VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType><AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId></EapMethod><Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>25</Type><EapType xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV1"><ServerValidation><DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation><ServerNames></ServerNames></ServerValidation><FastReconnect>true</FastReconnect><InnerEapOptional>false</InnerEapOptional><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>26</Type><EapType xmlns="http://www.microsoft.com/provisioning/MsChapV2ConnectionPropertiesV1"><UseWinLogonCredentials>false</UseWinLogonCredentials></EapType></Eap><EnableQuarantineChecks>false</EnableQuarantineChecks><RequireCryptoBinding>false</RequireCryptoBinding><PeapExtensions><PerformServerValidation xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">false</PerformServerValidation><AcceptServerName xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2">false</AcceptServerName><PeapExtensionsV2 xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV2"><AllowPromptingWhenServerCANotFound xmlns="http://www.microsoft.com/provisioning/MsPeapConnectionPropertiesV3">true</AllowPromptingWhenServerCANotFound></PeapExtensionsV2></PeapExtensions></EapType></Eap></Config></EapHostConfig></EAPConfig>
			</OneX>
		</security>
	</MSM>
</WLANProfile>

"@

   $currentlocation=Get-Location
   cd $env:TEMP
   $TempLocation=Get-Location
   $XMLProfile | Set-Content "$NetworkName.xml"
   Netsh WLAN add profile filename=$TempLocation\$NetworkName.xml
   remove-item "$NetworkName.xml"
   cd $currentlocation

}


class WifiAP
{
    [string]$Name
    [string]$Authentication
    [string]$Encryption
    [string]$BSSID
    [string]$Signal
    [string]$Radio
    [string]$Channel


}
Function Scan-WifiAPs()
{

<#

.DESCRIPTION
   This funtcion designed to list available APs and details

.PARAMETER profileNameWildCard
   Specifies wildcard filter for SSID
.PARAMETER BSSIDWildCard
   Specifies wildcard filter for BSSID

.EXAMPLE
   Scan-WifiAPs -profileNameWildCard TP007

    Name           : TP007
    Authentication : WPA2-Personal
    Encryption     : CCMP
    BSSID          : 64:70:02:9a:2a:c8
    Signal         : 80%
    Radio          : 802.11n
    Channel        : 11

.EXAMPLE
   Scan-WifiAPs | Format-Table

    Name             Authentication  Encryption BSSID             Signal Radio    Channel
    ----             --------------  ---------- -----             ------ -----    -------
    Horizon Wi-Free  WPA2-Enterprise CCMP       de:53:1c:ae:a3:b4 99%    802.11n  5
    Horizon Wi-Free  WPA2-Enterprise CCMP       0a:95:2a:5d:1b:cc 56%    802.11n  1
    Horizon Wi-Free  WPA2-Enterprise CCMP       5c:a3:9d:e9:25:19 28%    802.11n  6
    VM521D7B9        WPA2-Personal   CCMP       dc:53:7c:ae:a3:b4 99%    802.11n  5
    VM521D7B9-5      WPA2-Personal   CCMP       dc:53:7c:ae:a3:ac 98%    802.11ac 40
    PS4-BE73F184585B WPA2-Personal   CCMP       60:5b:b4:45:f2:3f 46%    802.11n  6
    UPC5912998       WPA2-Personal   CCMP       08:95:2a:5d:1b:ca 65%    802.11n  1
    TP007            WPA2-Personal   CCMP       64:70:02:9a:2a:c8 60%    802.11n  11
#>

    [CmdletBinding()]
    param([string]$profileNameWildCard, [string]$BSSIDWildCard)

    #clear-host
    $AllAP=$(netsh wlan show networks mode=bssid)
    #Write-Host $($AllAP | Out-String)
    $ListOfAPs=@()
    $ProcessNextLine=$false
    $lastLineisChannel=$false
    foreach($nextline in $AllAP)
    {
        if($nextline -match "^SSID\s[0-9]{1,4}\s:\s(.*)")
        {
            $ProcessNextLine=$true
            $Name=[regex]::match($nextline,"^SSID\s[0-9]{1,4}\s:\s(.*)").captures.groups[1].value

        }
        else
        {
            if($ProcessNextLine -eq $true)
            {
                if($nextline -eq "")
                {
                    $ProcessNextLine=$false
                    [WifiAP]$NewAP = [WifiAP]::new()
                    $NewAP.Name=$Name
                    $NewAP.Authentication=$Authentication
                    $NewAP.BSSID=$BSSID
                    $NewAP.Channel=$Channel
                    $NewAP.Encryption=$Encryption
                    $NewAP.Signal=$Signal
                    $NewAP.Radio=$Radio
                    $ListOfAPs+=$NewAP
                    $lastLineisChannel=$false
                    #$ListOfAPs+=(@{Name=$Name; Authentication=$Authentication; Encryption=$Encryption; BSSID=$BSSID; Signal=$Signal; Radio=$Radio; Channel=$Channel })
                }
                else
                {

                    if($nextline -match "^\s{4}Authentication\s{1,24}\s:\s([a-zA-Z0-9-]*)"){$Authentication=$Matches[1]}
                    if($nextline -match "^\s{4}Encryption\s{1,24}\s:\s([a-zA-Z0-9-]*)"){ $Encryption=$Matches[1]}
                    if($nextline -match "^\s{4}BSSID\s[0-9]{1,5}\s{1,24}\s:\s([0-9a-f:]*)")
                    {
                        if($lastLineisChannel -eq $true)
                        {
                            [WifiAP]$NewAP = [WifiAP]::new()
                            $NewAP.Name=$Name
                            $NewAP.Authentication=$Authentication
                            $NewAP.BSSID=$BSSID
                            $NewAP.Channel=$Channel
                            $NewAP.Encryption=$Encryption
                            $NewAP.Signal=$Signal
                            $NewAP.Radio=$Radio
                            $ListOfAPs+=$NewAP
                            $lastLineisChannel=$false
                        }
                        $BSSID=$Matches[1]
                    }
                    if($nextline -match "^\s{9}Signal\s{1,24}\s:\s([0-9%]*)"){ $Signal=$Matches[1]}
                    if($nextline -match "^\s{9}Radio\stype\s{1,24}\s:\s([0-9a-z\.]*)"){ $Radio=$Matches[1]}
                    if($nextline -match "^\s{9}Channel\s{1,24}\s:\s([0-9]*)"){ $Channel=$Matches[1]; $lastLineisChannel=$true}



                }
            }
        }
    }
    if($profileNameWildCard -ne "")
    {
        $ListOfAPs = $ListOfAPs | Where-Object {$_.Name -like $profileNameWildCard}
    }
    if($BSSIDWildCard -ne "")
    {
        $ListOfAPs =$ListOfAPs | Where-Object {$_.BSSID -like $BSSIDWildCard}
    }
    return $ListOfAPs
    #process all AP to an object, and after filter them
}


Function Get-WifiProfiles()
{
    $AllProfiles=$(netsh wlan show profiles)
    $ArrayProfiles=@()
    foreach($nextline in $AllProfiles)
    {
        if($nextline -match "    All User Profile     : (.*)")
        {
            $ArrayProfiles+=$Matches[1]
        }

    }
    return $ArrayProfiles
}

Function Get-TCPConnectionsInfo()
{
<#

.DESCRIPTION
   This function will get back information about tcp connection.



.EXAMPLE
   Get-TCPConnectionsInfo |Format-Table


RemoteDNS                       RemoteIP                    RemotePort ProcessID ProcessName            Company               LocalIP                     LocalPort
---------                       --------                    ---------- --------- -----------            -------               -------                     ---------
KriszLaptop                     fe80::f546:a6ce:fae0:37a7%4        445         4 System                                       fe80::f546:a6ce:fae0:37a7%4      1796
KriszLaptop                     fe80::f546:a6ce:fae0:37a7%4       1796         4 System                                       fe80::f546:a6ce:fae0:37a7%4       445
KriszLaptop                     127.0.0.1                         1266     12400 Duplicati.GUI.TrayIcon Duplicati Team        127.0.0.1                        8200
wm-in-f189.1e100.net            64.233.166.189                     443      6080 opera                  Opera Software        192.168.2.185                    6164
server22809.teamviewer.com      188.172.204.19                    5938      3772 TeamViewer_Service     TeamViewer GmbH       192.168.2.185                    6104
db5sch101110740.wns.windows.com 40.77.229.82                       443      5884 svchost                Microsoft Corporation 192.168.2.185                    6096
KriszLaptop                     127.0.0.1                         1704      3772 TeamViewer_Service     TeamViewer GmbH       127.0.0.1                        5939
KriszLaptop                     127.0.0.1                         4537      3772 TeamViewer_Service     TeamViewer GmbH       127.0.0.1                        4538
KriszLaptop                     127.0.0.1                         4538      3772 TeamViewer_Service     TeamViewer GmbH       127.0.0.1                        4537
KriszLaptop                     127.0.0.1                         2263      7532 pycharm64              JetBrains s.r.o.      127.0.0.1                        2264
KriszLaptop                     127.0.0.1                         2264      7532 pycharm64              JetBrains s.r.o.      127.0.0.1                        2263
KriszLaptop                     127.0.0.1                         2261      7532 pycharm64              JetBrains s.r.o.      127.0.0.1                        2262
KriszLaptop                     127.0.0.1                         2262      7532 pycharm64              JetBrains s.r.o.      127.0.0.1                        2261
KriszLaptop                     127.0.0.1                         1706      7388 TeamViewer             TeamViewer GmbH       127.0.0.1                        1707


#>
Get-NetTCPConnection -State Established |
foreach {
        if($lastItem -eq $null)
        {
            $lastItem=""
        }
        if($_.RemoteAddress -ne $lastItem)
        {
            $Name=Resolve-DnsName $_.RemoteAddress -ErrorAction SilentlyContinue;
            $lastItem=$_.RemoteAddress
        }

        $Process=Get-Process | where Id -eq $_.OwningProcess

        [pscustomobject]@{RemoteDNS=$Name.Server; RemoteIP=$_.RemoteAddress;RemotePort=$_.RemotePort;ProcessID=$_.OwningProcess;ProcessName=$Process.ProcessName;Company=$Process.Company; LocalIP=$_.LocalAddress; LocalPort=$_.LocalPort}


}
}


function Stay-Connected()
{
<#

.DESCRIPTION
   This function will chechk connection to specified network, and it will attempt to re-connect in case of long disconnection.


.PARAMETER ProfileName
   You can specify the exact profile name, where you want to connect.

.EXAMPLE
   Stay-connected -ProfileName TP007

   Connection will be proceed only if profile exists.

.EXAMPLE
   Stay-connected -ProfileName TP007 -InterfaceName Wi-Fi

   Connection will be procced, if profile exists on the specified interface.
#>
    [CmdletBinding()]
    param()

    DynamicParam {
        $ParameterName="ProfileName"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = Get-WifiProfiles
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)


        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{
        $ProfileName = $PsBoundParameters[$ParameterName]
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process
    {
        $allProfiles=$(netsh wlan show profiles)
        $IsProfileExist=$false
        foreach($nextline in $allProfiles)
        {
            if($nextline -match "^.*Profile\s*:\s$ProfileName$")
            {
                $IsProfileExist=$true
            }
        }
        if($IsProfileExist)
        {
            if($SelectedInterface -eq $null)
            {
                #$SelectedInterface=get-netadapter  | where-Object {$_.PhysicalMediaType -eq "Native 802.11"}|Select-Object -First 1 | & {process{return $_.Name}}
                $SelectedInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}} | Where-Object {$_.Name -like "Wi*"}|Select-Object -First 1).name
            }
            $SleepCounter=0
            while($true)
            {
                sleep 60
                $Status=Show-WifiInterface
                $Status=$Status.split("`n") | Where-Object {$_ -match "^\s{4}State"}
                if($Status -match ".*disconnected.*")
                {
                    $SleepCounter++
                    DateEcho "Network state: Disconnected"
                    if($SleepCounter -gt 10)
                    {
                        DateEcho "Connection attempt"
                        netsh wlan connect name=$ProfileName interface=$SelectedInterface

                    }
                }
                else
                {
                    $SleepCounter=0
                    if($Status -match ".*:\s(.*)")
                    {
                        DateEcho "Network state: $($Matches[1])"
                    }

                }


            }
        }
        else
        {
            Write-host "Network profile does not exists."
        }
    }
}

function Get-WifiState()
{
    <#

.DESCRIPTION
   This function will return with object that contain the state of wifi interface.


.PARAMETER InterfaceName
   You can specify the exact wifi interface name, where you want to connect.


.EXAMPLE
   Get-WifiState -InterfaceName Wi-Fi


#>
    [CmdletBinding()]
    param()

    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary



        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process
    {
        $InterfaceIP=""
	    $State=""
	    $ESSID=""
	    $BSSID=""
	    $Authentication=""
	    $ReceiveRate=""
	    $TransmitRate=""
	    $Signal=""
	    $CurrentChannel=""
        $LogHeader=""
        $LogLine=""
        $LogCsvHeader=""
        $logCsvLine=""



        if($SelectedInterface -eq $null)
        {
            #$SelectedInterface=get-netadapter  | where-Object {$_.PhysicalMediaType -eq "Native 802.11"}|Select-Object -First 1 | & {process{return $_.Name}}
            $SelectedInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}} | Where-Object {$_.Name -like "Wi*"}|Select-Object -First 1).name
        }
        $InterfaceIP=(Get-InterfaceIP $SelectedInterface).IPv4Address

        $Interface=""
        $Interface=netsh wlan show interface $SelectedInterface

        $State=$Interface[7].Split(":")[1].Trim()
        if( "$($State)" -eq "connected" )
        {
            $ESSID=$Interface[8].Split(":")[1].Trim()
            $BSSID=$Interface[9].Substring($Interface[9].IndexOf(" : ")+3).Trim()
            $Authentication=$Interface[12].Split(":")[1].Trim()
            $ReceiveRate=$Interface[16].Split(":")[1].Trim()
            $TransmitRate=$Interface[17].Split(":")[1].Trim()
            $Signal=$Interface[18].Split(":")[1].Trim()
            $CurrentChannel=$Interface[15].Split(":")[1].Trim()
        }
        $LogHeader="{0,-16} {1,-15} {2,-20} {3,-18} {4,-15} {5,-7} {6,-7} {7,-7} {8,-7}" -f "InterfaceIP", "State", "ESSID", "BSSID", "Authentication", "RxRate","TxRate", "Signal", "Channel"
        $LogHeader+="`n"+"{0} {1} {2} {3} {4} {5} {6} {7} {8}" -f "".PadLeft(16,"-"), "".PadLeft(15,"-"), "".PadLeft(20,"-"), "".PadLeft(18,"-"), "".PadLeft(15,"-"), "".PadLeft(7,"-"), "".PadLeft(7,"-"), "".PadLeft(7,"-"), "".PadLeft(7,"-")
        $LogLine="{0,-16} {1,-15} {2,-20} {3,-18} {4,-15} {5,-7} {6,-7} {7,-7} {8,-7}" -f $InterfaceIP, $State, $ESSID, $BSSID, $Authentication, $ReceiveRate, $TransmitRate, $Signal, $CurrentChannel
        $LogCsvHeader="{0};{1};{2};{3};{4};{5};{6};{7};{8}" -f "InterfaceIP", "State", "ESSID", "BSSID", "Authentication", "RxRate","TxRate", "Signal", "Channel"
        $logCsvLine="{0};{1};{2};{3};{4};{5};{6};{7};{8}" -f $InterfaceIP, $State, $ESSID, $BSSID, $Authentication, $ReceiveRate, $TransmitRate, $Signal, $CurrentChannel

        return [pscustomobject]@{InterfaceIP=$InterfaceIP;State=$State;ESSID=$ESSID;BSSID=$BSSID;Authentication=$Authentication;ReceiveRate=$ReceiveRate;TransmitRate=$TransmitRate;Signal=$Signal;CurrentChannel=$CurrentChannel;`
        LogHeader=$LogHeader;LogLine=$LogLine;LogCsvHeader=$LogCsvHeader;logCsvLine=$logCsvLine;}

    }
}

Function Monitor-WifiState()
{
 <#

.DESCRIPTION
   This function will monitor periodicly the state of wifi interface.


.PARAMETER InterfaceName
   You can specify the exact wifi interface name, where you want to connect.


.EXAMPLE
   Get-WifiState -InterfaceName Wi-Fi


#>
    [CmdletBinding()]
    param([int]$CheckTime=1)

    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary



        $ParameterNameInterface="InterfaceName"
        $AttributeCollectionInterface = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttributeInterface = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttributeInterface.Mandatory = $false
        $ParameterAttributeInterface.Position = 2
        $AttributeCollectionInterface.Add($ParameterAttributeInterface)
        #$arrSetInterface=get-netadapter | where-Object {$_.PhysicalMediaType -eq "Native 802.11"} | & {process{return $_.Name}}
        $arrSetInterface=(netsh wlan show interfaces | select-string -Pattern "\s{4}Name\s{19}:\s(.*)" | &{process{[pscustomobject]@{Name=$_.matches[0].groups[1].value}}}).name
        $ValidateSetAttributeInterface=New-Object System.Management.Automation.ValidateSetAttribute($arrSetInterface)
        $AttributeCollectionInterface.Add($ValidateSetAttributeInterface)
        $RuntimeParameterInterface = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterNameInterface, [string], $AttributeCollectionInterface)
        $RuntimeParameterDictionary.Add($ParameterNameInterface, $RuntimeParameterInterface)




        return $RuntimeParameterDictionary
    }
    begin{
        $SelectedInterface=$PsBoundParameters[$ParameterNameInterface]
    }
    process
    {

        while($true)
        {

            if($SelectedInterface -eq $null)
            {
                $CurrentState=Get-WifiState
                DateEcho $CurrentState.LogLine
            }
            else
            {
                $CurrentState=Get-WifiState -InterfaceName $SelectedInterface
                DateEcho $CurrentState.LogLine
            }

            Sleep $CheckTime
        }

    }
}
function DateEcho($Var)
{
<#

.DESCRIPTION
   This function will add an extra time stamp for all input.
   Pipeline enabled command.

.EXAMPLE
   DateEcho "This message need a timesamp"
   26.01.2017-22:24:08> This message need a timesamp

.EXAMPLE
    ping 8.8.8.8 -t | DateEcho

    26.01.2017-22:24:48> Reply from 8.8.8.8: bytes=32 time=10ms TTL=57
    26.01.2017-22:24:49> Reply from 8.8.8.8: bytes=32 time=13ms TTL=57
    26.01.2017-22:24:50> Reply from 8.8.8.8: bytes=32 time=12ms TTL=57
    26.01.2017-22:24:51> Reply from 8.8.8.8: bytes=32 time=10ms TTL=57
    26.01.2017-22:24:52> Reply from 8.8.8.8: bytes=32 time=10ms TTL=57
#>

    process
    {
         $TimeStamp=Get-Date -Format "dd.MM.yyyy-HH:mm:ss> "
        "$TimeStamp$Var$_"

    }


}


function Get-InterfaceIP()
{
    [CmdletBinding()]
    param()

    DynamicParam {
        $ParameterName="Interface"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0
        $AttributeCollection.Add($ParameterAttribute)
        #$arrSet = (Get-NetAdapter).Name
        $arrSet = (netsh interface show interface | select-string -Pattern "([a-zA-Z0-9]*\s{2,}){3}(.*)" | Select-Object -Skip 1| &{process{[pscustomobject]@{Name=$_.matches[0].groups[2].value}}}).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    begin{
        $Interface = $PsBoundParameters[$ParameterName]
    }


    Process{
        $selectedInterface=[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | where name -eq $Interface

        $InterfaceAlias=$selectedInterface.Name
     
        $IPAddress=($selectedInterface.GetIPProperties().UnicastAddresses | Where-Object PrefixLength -eq 24 ).Address.IPAddressToString
        $IPv6Address=($selectedInterface.GetIPProperties().UnicastAddresses | Where-Object PrefixLength -eq 64 ).Address.IPAddressToString
        return [pscustomobject]@{InterfaceAlias=$InterfaceAlias;IPv4Address=$IPAddress;IPv6Address=$IPv6Address}
    }
}