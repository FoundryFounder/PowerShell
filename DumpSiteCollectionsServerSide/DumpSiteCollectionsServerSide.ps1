<#
   DumpSiteCollectionsServerSide.ps1
   Displays all property values for all site collections.  Run on server.
   Copyright © 2017 John Huschka, Collaboration Foundry, www.collaboration-foundry.com
   August 15, 2017
#>

if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

<#  DumpObjectProperties:  Displays all property values, sorted by property name, of a 
     parameter supplied object
#>
function DumpObjectProperties($objectToDump){
   write-host $objectToDump -ForegroundColor Cyan
   <#  Format-List displays a list of properties/values of its input object ($site), one/line.
       The inner "Get-Member" selects the name of every property on the object, and that output
        is then passed into a Sort-Object.
       The collection of sorted property names is provided to Format-List, telling it which 
        properties to display in what order.  #>
   $objectToDump | Format-List -Property ([string[]]($objectToDump | Get-Member -MemberType Property | %{ $_.Name } | Sort-Object)) 
}

$sites = get-spsite | Where-Object{$_.Url -like '*'}
foreach($site in $sites){
    DumpObjectProperties $site
}

