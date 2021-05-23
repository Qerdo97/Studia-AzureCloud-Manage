#Ustawiamy domyślne formaty kodowania do UTF8 aby poprawnie wyświetlać polskie znaki diakrytyczne
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$OutputEncoding = [System.Text.Encoding]::UTF8
$exercise = "AZ2 - Zadanie Cloud"
$name = "Grzegorz"
$lastName = "Sekuła"
$group = "IZ08TC1"
$indexNumber = "17313"
$workDir = "c:\WIT\" + $indexNumber

function CheckAdminRights
{
    If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
    {
        Write-Host "Ten skrypt musi być uruchomiony z uprawieniami administratora!!!"
        Write-Host ""
        Write-Host -NoNewLine 'Wciśnij dowolny klawisz aby kontynuować...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        Break
    }
}

function LoginToAzure
{
    Clear-Variable -Name connectionInfo -Scope Global -ErrorAction SilentlyContinue | Out-Null
    $Credential = Get-Credential

    Install-Module AzureADPreview
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery

    Connect-AzAccount -Credential $Credential | Out-Null
    Connect-AzureAD -Credential $Credential -OutVariable global:connectionInfo | Out-Null

    Write-Host "Obecnie jesteś zalogowany na konto:"
    Write-Host -ForegroundColor Green $global:connectionInfo.Account.Id
}

function LogoutFromAzure
{
    Disconnect-AzAccount | Out-Null
    Disconnect-AzureAD | Out-Null
    Write-Host "Pomyślnie wylogowano"
    Clear-Variable -Name connectionInfo -Scope Global
}

#Funkcja ShowAuthor wyświetla informacje o autorze tego skrypty
function ShowAuthor
{
    Write-Host    $exercise
    Write-Host    ""
    Write-Host    "Author:"
    Write-Host    $name $lastName
    Write-Host    "Grupa:" $group
    Write-Host    "Nr indeksu:" $indexNumber
}

#Funkcja odpowiedzialna za wyświetlanie menu
function ShowMenu
{
    Clear-Host
    Write-Host -ForegroundColor Yellow "========================== MENU =========================="
    Write-Host ""
    Write-Host -ForegroundColor Yellow "        == Obecnie jesteś zalogowany na konto: ==         "
    Write-Host -ForegroundColor Green $connectionInfo.Account.Id
    Write-Host ""
    Write-Host -ForegroundColor Yellow "                 == Obsługa raportów ==                   "
    Write-Host "1: Wciśnij '1' aby otrzymać raport MASZYN WIRTUALNYCH."
    Write-Host "2: Wciśnij '2' aby otrzymać raport KONT UŻYTKOWNIKÓW."
    Write-Host "3: Wciśnij '3' aby otrzymać raport GRUP."
    Write-Host "4: Wciśnij '4' aby otrzymać raport ZDARZEŃ."
    Write-Host -ForegroundColor Yellow "                       == Więcej ==                       "
    Write-Host "A: Wciśnij 'A' aby otrzymać informacje o autorze."
    Write-Host "K: Wciśnij 'K' aby zmienić zalogowane konto."
    Write-Host "L: Wciśnij 'L' aby się wylogować."
    Write-Host "Q: Wciśnij 'Q' aby wyjść."
    Write-Host ""
    Write-Host -ForegroundColor Yellow "=========================================================="
}

function reportVMs
{
    ##############################
    # VM Raport
    ##############################
    $completeVMRaportDir = $workDir + "\VM"
    $completeVMRaportFileName = $indexNumber + "_VMs.csv"
    New-Item -Path $completeVMRaportDir -Name $completeVMRaportFileName -Force | Out-Null
    Add-Content -Path $completeVMRaportDir\$completeVMRaportFileName -Value "Nazwa maszyny,Rozmiar maszyny,Obecny status,Wersja zainstalowanego systemu operacyjnego,Nazwa wbudowanego konta administratora,Typ dysku z systemem operacyjnym,Rozmiar dysku z systemem operacyjnym,Ilość dysków DATA,Nazwy dysków DATA,Rozmiar dysków DATA,Rodzaj dysków DATA,Publiczny adres IP,Prywatny adres IP,Przypisana grupa NSG,Przypisana grupa ASG,Grupa zasobów,Subskrypcja Azure"
    $VMs = Get-AzVM
    Foreach ($VM in $VMs)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam VM $( $VM.Name )"
        $VMname = $VM.Name
        $VMsize = $VM.HardwareProfile.VmSize
        $VMstatus = $VM.StatusCode
        $VMOSversion = $VM.StorageProfile.ImageReference.Offer + "-" + $VM.StorageProfile.ImageReference.Sku + "(" + $VM.StorageProfile.ImageReference.ExactVersion + ")"
        $VMadminName = $VM.OSProfile.AdminUsername
        $VMOSDiskType = $VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
        $VMOSDiskSize = ($VM.StorageProfile.OsDisk.DiskSizeGB).ToString() + " GB"
        $VMDataDisks = $VM.StorageProfile.DataDisks
        $VMDataDisksCount = $VM.StorageProfile.DataDisks.Count
        Foreach ($VMDataDisk in $VMDataDisks)
        {
            $NameOfDisk = $VMDataDisk.Name
            $VMDataDiskType = (Get-AzDisk | Where-Object Name -Like $NameOfDisk).Sku.Name
            $VMDataDiskSize = $VMDataDisk.DiskSizeGB.ToString() + " GB"

            $ArrayOfDiskNames += $NameOfDisk
            $ArrayOfDiskTypes += $VMDataDiskType
            $ArrayOfDiskSizes += $VMDataDiskSize
        }
        $VMNetworkPublicIp = (Get-AzNetworkInterface | Where-Object Id -Like $VM.NetworkProfile.NetworkInterfaces.Id).IpConfigurations.PublicIpAddress
        $VMNetworkPrivateIp = (Get-AzNetworkInterface | Where-Object Id -Like $VM.NetworkProfile.NetworkInterfaces.Id).IpConfigurations.PrivateIpAddress
        $VMNSGGroup = (Get-AzNetworkSecurityGroup | Where-Object Id -EQ ((Get-AzNetworkInterface | Where-Object Id -Like $VM.NetworkProfile.NetworkInterfaces.Id).NetworkSecurityGroup.Id)).Name
        $VMASGGroup = (Get-AzApplicationSecurityGroup | Where-Object ResourceGroupName -EQ ($VM.ResourceGroupName)).Name
        $VMResourceGroup = $VM.ResourceGroupName
        $VMAzureSubscription = (Get-AzSubscription | Where-Object Id -EQ ((($VM.Id.ToString()) -split '/')[2])).Name
        Add-Content -Path $completeVMRaportDir\$completeVMRaportFileName -Value "$VMname,$VMsize,$VMstatus,$VMOSversion,$VMadminName,$VMOSDiskType,$VMOSDiskSize,$VMDataDisksCount,$ArrayOfDiskNames,$ArrayOfDiskSizes,$ArrayOfDiskTypes,$VMNetworkPublicIp,$VMNetworkPrivateIp,$VMNSGGroup,$VMASGGroup,$VMResourceGroup,$VMAzureSubscription"
        Clear-Variable -Name ArrayOfDiskNames -ErrorAction SilentlyContinue | Out-Null
        Clear-Variable -Name ArrayOfDiskTypes -ErrorAction SilentlyContinue | Out-Null
        Clear-Variable -Name ArrayOfDiskSizes -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host -ForegroundColor Green "Raport VM został zapisany w $completeVMRaportDir\$completeVMRaportFileName"


    ##############################
    # Networking Raport
    ##############################
    $completeNetworkingRaportDir = $workDir + "\VM"
    $completeNetworkingRaportFileName = $indexNumber + "_sieciwirtualne.csv"
    New-Item -Path $completeNetworkingRaportDir -Name $completeNetworkingRaportFileName -Force | Out-Null
    Add-Content -Path $completeNetworkingRaportDir\$completeNetworkingRaportFileName -Value "Nazwa sieci,Adresacja (IP + maska),Ilość podsieci,Adresacja (IP + maska) podsieci,Grupa zasobów,Nazwa subskrypcji"

    $Networks = Get-AzVirtualNetwork
    Foreach ($Network in $Networks)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam sieć wirtualną $( $Network.Name )"
        $NetworkName = $Network.Name
        $NetworkAddress = $Network.AddressSpace.AddressPrefixes
        $NetworkSubnetsCount = $Network.Subnets.Count
        $NetworkSubnets = $Network.Subnets
        Foreach ($NetworkSubnet in $NetworkSubnets)
        {
            $NetworkSubnetAddress = $NetworkSubnet.AddressPrefix
            $ArrayOfNetworkSubnetAddress += $NetworkSubnetAddress
        }
        $NetworkResourceGroup = $Network.ResourceGroupName
        $NetworkSubscriptionName = (Get-AzSubscription | Where-Object Id -EQ ((($Network.Id.ToString()) -split '/')[2])).Name
        Add-Content -Path $completeNetworkingRaportDir\$completeNetworkingRaportFileName -Value "$NetworkName,$NetworkAddress,$NetworkSubnetsCount,$ArrayOfNetworkSubnetAddress,$NetworkResourceGroup,$NetworkSubscriptionName"
        Clear-Variable -Name ArrayOfNetworkSubnetAddress -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host -ForegroundColor Green "Raport sieci wirtualnych został zapisany w $completeNetworkingRaportDir\$completeNetworkingRaportFileName"



    ##############################
    # NSG Raport
    ##############################
    $completeNSGRaportDir = $workDir + "\VM"
    $completeNSGRaportFileName = $indexNumber + "_NSG.csv"
    New-Item -Path $completeNSGRaportDir -Name $completeNSGRaportFileName -Force | Out-Null
    Add-Content -Path $completeNSGRaportDir\$completeNSGRaportFileName -Value "Nazwa grupy,Rodzaj reguły (przychodząca/wychodząca),Konfiguracja,Grupa zasobów,Nazwa subskrypcji"

    $NSGs = Get-AzNetworkSecurityGroup
    Foreach ($NSG in $NSGs)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam NSG $( $NSG.Name )"
        Clear-Variable -Name NSGSecurityRuleDirectionArrowWay -ErrorAction SilentlyContinue | Out-Null
        $NSGname = $NSG.Name
        $NSGResourceGroup = $NSG.ResourceGroupName
        $NSGSubscriptionName = (Get-AzSubscription | Where-Object Id -EQ ((($NSG.Id.ToString()) -split '/')[2])).Name
        $NSGSecurityRules = $NSG.SecurityRules
        Foreach ($NSGSecurityRule in $NSGSecurityRules)
        {
            $NSGSecurityRuleDirection = $NSGSecurityRule.Direction
            if ($NSGSecurityRuleDirection -eq "Inbound")
            {
                $NSGSecurityRuleDirectionArrowWay = "<-"
            }
            if ($NSGSecurityRuleDirection -eq "Outbound")
            {
                $NSGSecurityRuleDirectionArrowWay = "->"
            }
            $NSGSecurityRuleConfiguration = "[Priorytet:$( $NSGSecurityRule.Priority ) | Nazwa:$( $NSGSecurityRule.Name ) | Opis:$( $NSGSecurityRule.Description ) | $( $NSGSecurityRule.Access ) | Protokół:$( $NSGSecurityRule.Protocol ) | $( $NSGSecurityRule.SourceAddressPrefix ):$( $NSGSecurityRule.SourcePortRange )$( $NSGSecurityRuleDirectionArrowWay )$( $NSGSecurityRule.DestinationAddressPrefix ):$( $NSGSecurityRule.DestinationPortRange ) | Zródłowe ASG:$( $NSGSecurityRule.SourceApplicationSecurityGroups ) | Docelowe ASG:$( $NSGSecurityRule.DestinationApplicationSecurityGroups )]"
            Add-Content -Path $completeNSGRaportDir\$completeNSGRaportFileName -Value "$NSGname,$NSGSecurityRuleDirection,$NSGSecurityRuleConfiguration,$NSGResourceGroup,$NSGSubscriptionName"
        }
        $NSGDefaultSecurityRules = $NSG.DefaultSecurityRules
        Foreach ($NSGDefaultSecurityRule in $NSGDefaultSecurityRules)
        {
            $NSGDefaultSecurityRuleDirection = $NSGDefaultSecurityRule.Direction
            if ($NSGDefaultSecurityRuleDirection -eq "Inbound")
            {
                $NSGDefaultSecurityRuleDirectionArrowWay = "<-"
            }
            if ($NSGDefaultSecurityRuleDirection -eq "Outbound")
            {
                $NSGDefaultSecurityRuleDirectionArrowWay = "->"
            }
            $NSGDefaultSecurityRuleConfiguration = "[Priorytet:$( $NSGDefaultSecurityRule.Priority ) | Nazwa:$( $NSGDefaultSecurityRule.Name ) | Opis:$( $NSGDefaultSecurityRule.Description ) | $( $NSGDefaultSecurityRule.Access ) | Protokół:$( $NSGDefaultSecurityRule.Protocol ) | $( $NSGDefaultSecurityRule.SourceAddressPrefix ):$( $NSGDefaultSecurityRule.SourcePortRange )$( $NSGDefaultSecurityRuleDirectionArrowWay )$( $NSGDefaultSecurityRule.DestinationAddressPrefix ):$( $NSGDefaultSecurityRule.DestinationPortRange ) | Zródłowe ASG:$( $NSGDefaultSecurityRule.SourceApplicationSecurityGroups ) | Docelowe ASG:$( $NSGDefaultSecurityRule.DestinationApplicationSecurityGroups )]"
            Add-Content -Path $completeNSGRaportDir\$completeNSGRaportFileName -Value "$NSGname,$NSGDefaultSecurityRuleDirection,$NSGDefaultSecurityRuleConfiguration,$NSGResourceGroup,$NSGSubscriptionName"
        }

    }
    Write-Host -ForegroundColor Green "Raport NSG został zapisany w $completeNSGRaportDir\$completeNSGRaportFileName"
}

function reportUsers
{
    $completeUserPath = $workDir + "\dzialyAAD"
    #var below made for saving time
    $GetAzureADUser = Get-AzureADUser -All $true
    $Departments = ($GetAzureADUser | Select-Object -ExpandProperty Department | Group-Object).Name
    Foreach ($Department in $Departments)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam dział $( $Department )"
        $completeUserFileName = $indexNumber + "_" + $Department + ".csv"
        New-Item -Path $completeUserPath -Name $completeUserFileName -Force | Out-Null
        Add-Content -Path $completeUserPath\$completeUserFileName -Value "Imię,Nazwisko,UPN,Przydzielone licencje"
        $UsersInDepartment = $GetAzureADUser | Where-Object Department -EQ $Department
        Foreach ($UserInDepartment in $UsersInDepartment)
        {
            $UserInDepartmentName = $UserInDepartment.GivenName
            $UserInDepartmentSurname = $UserInDepartment.Surname
            $UserInDepartmentUPN = $UserInDepartment.UserPrincipalName
            $UserInDepartmentLicensesInSkuID = $UserInDepartment.AssignedLicenses.SkuId
            Foreach ($UserInDepartmentLicenseInSkuID in $UserInDepartmentLicensesInSkuID)
            {
                $UserInDepartmentLicenseInSkuPartNumber = ((Get-AzureADSubscribedSku | Where-Object SkuId -EQ $UserInDepartmentLicenseInSkuID).SkuPartNumber)
                $ArrayOfUserInDepartmentLicenseInSkuPartNumber += "[$( $UserInDepartmentLicenseInSkuPartNumber )]"
            }
            Add-Content -Path $completeUserPath\$completeUserFileName -Value "$UserInDepartmentName,$UserInDepartmentSurname,$UserInDepartmentUPN,$ArrayOfUserInDepartmentLicenseInSkuPartNumber"
            Clear-Variable -Name ArrayOfUserInDepartmentLicenseInSkuPartNumber -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host -ForegroundColor Green "Raport działu $( $Department ) został zapisany w $completeUserPath\$completeUserFileName"
    }
    $UsersWithoutDepartment = $GetAzureADUser | Where-Object Department -EQ $NULL
    if ($UsersWithoutDepartment.Count -gt 0)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam użytkowników bez działu"
        $completeUsersWithoutDepartmentFileName = $indexNumber + "_BRAK-DZIAŁU.csv"
        New-Item -Path $completeUserPath -Name $completeUsersWithoutDepartmentFileName -Force | Out-Null
        Add-Content -Path $completeUserPath\$completeUsersWithoutDepartmentFileName -Value "Imię,Nazwisko,UPN,Przydzielone licencje"
        Foreach ($UserWithoutDepartment in $UsersWithoutDepartment)
        {
            $UserWithoutDepartmentName = $UserWithoutDepartment.GivenName
            $UserWithoutDepartmentSurname = $UserWithoutDepartment.Surname
            $UserWithoutDepartmentUPN = $UserWithoutDepartment.UserPrincipalName
            $UserWithoutDepartmentLicensesInSkuID = $UserWithoutDepartment.AssignedLicenses.SkuId
            Foreach ($UserWithoutDepartmentLicenseInSkuID in $UserWithoutDepartmentLicensesInSkuID)
            {
                $UserWithoutDepartmentLicenseInSkuPartNumber = ((Get-AzureADSubscribedSku | Where-Object SkuId -EQ $UserWithoutDepartmentLicenseInSkuID).SkuPartNumber)
                $ArrayOfUserWithoutDepartmentLicenseInSkuPartNumber += "[$( $UserWithoutDepartmentLicenseInSkuPartNumber )]"
            }
            Add-Content -Path $completeUserPath\$completeUsersWithoutDepartmentFileName -Value "$UserWithoutDepartmentName,$UserWithoutDepartmentSurname,$UserWithoutDepartmentUPN,$ArrayOfUserWithoutDepartmentLicenseInSkuPartNumber"
            Clear-Variable -Name ArrayOfUserWithoutDepartmentLicenseInSkuPartNumber -ErrorAction SilentlyContinue | Out-Null

        }
        Write-Host -ForegroundColor Green "Raport użytkowników BEZ DZIAŁU został zapisany w $completeUserPath\$completeUsersWithoutDepartmentFileName"
    }

}

function reportGroups
{
    $completeGroupsPath = $workDir + "\grupyAAD"

    $Groups = Get-AzureADGroup
    Foreach ($Group in $Groups)
    {
        Write-Host -ForegroundColor Yellow "Sprawdzam grupę $( $Group.DisplayName )"
        $completeGroupsFileName = $indexNumber + "_" + ($Group.DisplayName -replace '[<>:"/\|?*]', '') + ".csv"
        New-Item -Path $completeGroupsPath -Name $completeGroupsFileName -Force | Out-Null
        Add-Content -Path $completeGroupsPath\$completeGroupsFileName -Value "Owners,Members"
        $GroupOwners = (Get-AzureADGroupOwner -ObjectId $Group.ObjectId).DisplayName
        $GroupMembers = (Get-AzureADGroupMember -ObjectId $Group.ObjectId).DisplayName
        Add-Content -Path $completeGroupsPath\$completeGroupsFileName -Value "$( $GroupOwners -join " | " ),$( $GroupMembers -join " | " )"
        Write-Host -ForegroundColor Green "Raport grup został zapisany w $completeGroupsPath\$completeGroupsFileName"
    }
}

function reportLogs
{
    $completeLogsPath = $workDir + "\logiAAD"
    $completeLogsFileName = $indexNumber + "_LogiAAD.csv"
    $Logs = Get-AzureADAuditDirectoryLogs | Where-Object Category -EQ "UserManagement"
    New-Item -Path $completeLogsPath -Name $completeLogsFileName -Force | Out-Null
    Add-Content -Path $completeLogsPath\$completeLogsFileName -Value "Kto,Kiedy,Obiekt,Nowa wartość,Typ operacji"
    Foreach ($Log in $Logs)
    {
        $LogWho = $Log.InitiatedBy.User.UserPrincipalName
        $LogWhen = ($Log.ActivityDateTime).ToString("dd/MM/yyyy HH:mm:ss")
        $LogObject = $Log.TargetResources.UserPrincipalName -replace '[,;]', '|'
        $LogOperationType = $Log.ActivityDisplayName -replace '[,;]', '|'
        $LogModifiedProperties = $Log.TargetResources.ModifiedProperties | Where-Object { $_.DisplayName -ne "Included Updated Properties" }
        ForEach ($LogModifiedPropertie in $LogModifiedProperties)
        {
            $LogModifiedPropertieDisplayName = $LogModifiedPropertie.DisplayName -replace '[,;]', '|'
            $LogModifiedPropertieNewValue = $LogModifiedPropertie.NewValue -replace '[,;]', '|'
            Add-Content -Path $completeLogsPath\$completeLogsFileName -Value "$LogWho,$LogWhen,$LogObject,$( $LogModifiedPropertieDisplayName ):$( $LogModifiedPropertieNewValue ),$LogOperationType"
        }
    }
    Write-Host -ForegroundColor Green "Raport logów został zapisany w $completeLogsPath\$completeLogsFileName"
}

function menu
{
    #Wyświetlenie menu i oczekiwanie na decyzję. Po wybraniu odpowiedniej opcji jest wywoływana odpowiednia funkcja
    do
    {
        ShowMenu
        $selection = Read-Host "Proszę dokonać wyboru"
        switch ($selection)
        {
            '1' {
                Clear-Host
                reportVMs
            }
            '2' {
                Clear-Host
                reportUsers
            }
            '3' {
                Clear-Host
                reportGroups
            }
            '4' {
                Clear-Host
                reportLogs
            }
            'a' {
                Clear-Host
                ShowAuthor
            }
            'k' {
                Clear-Host
                LoginToAzure
            }
            'l' {
                Clear-Host
                LogoutFromAzure
            }
            'q' {

            }
            Default {
                q
                Clear-Host
                "Nie ma takiej opcji"
            }
        }
        pause
    }
    until ($selection -eq 'q')
}
CheckAdminRights
LoginToAzure
menu