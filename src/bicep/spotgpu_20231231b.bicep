// Create a small linux vm, in the free tier of vms (the disks are billable)
//
// Forces use of ssh public key to login, default key ties this to authors machine
//
// Derived from ms quicstart at https://learn.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-bicep?tabs=CLI
//
@description('Name of the virtual machine.')
param vmName string = 'spot-20231231b'

@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'spot-20231231b'

@description('Username for the Virtual Machine.')
param adminUsername string = 'mikejenn'

// @description('Password for the Virtual Machine.')
// @minLength(8)
// @secure()
// param adminPassword string 

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
// @allowed([
//   'Ubuntu Server 20.04 LTS - x64 Gen 2'
// ])
param OSVersion string = '20_04-lts-gen2'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s_v2'

@description('Location for all resources.')
param location string = 'centralus'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var nicName = 'spotNic0231231b'
var virtualNetworkName = 'spotVNET20231231b'
var networkSecurityGroupName = 'spot20231231b-nsg'
var storageAccountName = 'spotuscen${uniqueString(resourceGroup().id)}'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var publicKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBxFHMCT21LDP4CVjysFcE8DLZc75Itc4GoEhtLzQL4pkOTmGgUSbvntvXOERwOylKGOOlvgD6gLGoQDoaMTqki+XxOQj1VoWLn8ivhJxmLivf/XMK5DrAFJlwxo1h+bFxrHGIAwXkGeu58ej9RI5PPwx+mwKAgFTrkseZOaIfskHBucIUf4jJ+fEd68hyR1rheUEyxA6m/LDkPd0q1bCtHuzQz6W/yjPPEJeeit1eOYDPegydBr2ZzY1CB/2WxtiyKBe6NZ9mZRFDZp0e8gF4oqiiVox6wen0669Jq9vHOvQHgCTWnPVcmdQr8Hw3fJRGQzeA1wTpHAunuimlB33FcBku4BbTR8jMgmhTvUK+caI1AfCJQyiIVaOER+X2AWdJTAiXcNwzRtchLPa64bJCULZ/DBmJPgTLL09mzp702XIPk+3Kna6VROZ6jju8YJgkVekM1x9ir8sRSAkVhZMXBdLk0Y1H0Y1wtSwjGSGlxwRctzXVNs/1Rsdhh7uVSqk= generated-by-azure'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}



resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
 properties: {
   securityRules: [
     {
       name: 'default-allow-3389'
       properties: {
         priority: 900
         access: 'Allow'
         direction: 'Inbound'
         destinationPortRange: '3389'
         protocol: 'Tcp'
         sourcePortRange: '*'
         sourceAddressPrefix: '*'
         destinationAddressPrefix: '*'
       }
     }
     {
       name: 'mwj-allow-ssh'
       properties: {
         priority: 1000
         access: 'Allow'
         direction: 'Inbound'
         destinationPortRange: '22'
         protocol: 'Tcp'
         sourcePortRange: '*'
         sourceAddressPrefix: '*'
         destinationAddressPrefix: '*'
       }
     }
   ]
 }
}
resource symbolicname 'Microsoft.Compute/sshPublicKeys@2023-03-01' = {
  name: 'spotPubKey20231231b'
  location: location
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  properties: {
    publicKey: publicKey
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    priority: 'Spot'
    evictionPolicy: 'Delete'
    billingProfile: {
      maxPrice: -1
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      // adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/mikejenn/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 12
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

//resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
//  parent: vm
//  name: extensionName
//  location: location
//  properties: {
//    publisher: extensionPublisher
//    type: extensionName
//    typeHandlerVersion: extensionVersion
//    autoUpgradeMinorVersion: true
//    enableAutomaticUpgrade: true
//    settings: {
//      AttestationConfig: {
//        MaaSettings: {
//          maaEndpoint: maaEndpoint
//          maaTenantName: maaTenantName
//        }
//      }
//    }
//  }
//}

output hostname string = publicIp.properties.dnsSettings.fqdn
