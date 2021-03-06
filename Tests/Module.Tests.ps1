$ModuleName = "Set-ADUserLogonTo"
$RootPath = (Get-Item -Path $PSScriptRoot).Parent.FullName
$ModuleManifest = "$RootPath\$ModuleName.psd1"

Get-Module $ModuleName | Remove-Module
Import-Module $ModuleManifest

Describe "$ModuleName Module Tests" {

    It "has the root module $ModuleName.psm1" {
        "$RootPath\$ModuleName.psm1" | Should Exist
    }

    It "has the manifest file of $ModuleName.psd1" {
        "$RootPath\$ModuleName.psd1" | Should Exist
        "$RootPath\$ModuleName.psd1" | Should Contain "$ModuleName.psm1"
        {Test-ModuleManifest -Path "$RootPath\$ModuleName.psd1"} | Should Not Throw
    }

    It "has valid PowerShell code" {
        $psFile = Get-Content -Path "$RootPath\$ModuleName.psm1" -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should be 0
    }

    If ((Get-Module -name $ModuleName).ExportedFormatFiles -ne ""){
        It "has the formatting file $ModuleName.format.ps1xml" {
            "$RootPath\$ModuleName.format.ps1xml" | Should Exist
        }
    }

    If (Test-Path -Path "$RootPath\$ModuleName.format.ps1xml"){
        It "has a format file in the manifest"{
            (Get-Module -Name $ModuleName).ExportedFormatFiles | Should Not BeNullOrEmpty
            (Get-Module -Name $ModuleName).ExportedFormatFiles | Should BeLike "*$ModuleName.format.ps1xml*"
        }
    }

    It "Has the proper amount of exported modules"{
        $ExportedCount = Get-Command -Module $ModuleName | Measure-Object | Select-Object -ExpandProperty Count

        $PublicFunctions = (Get-Content "$ModuleName.psd1" | Select-String -SimpleMatch FunctionsToExport).ToString()
        $PublicFunctions = $PublicFunctions.Replace(' ','').TrimStart('FunctionsToExport=').Replace("'","").Replace('"','').Split(',')
        $DeclaredCount = $PublicFunctions | Measure-Object | Select-Object -ExpandProperty Count

        $ExportedCount | Should Be $DeclaredCount

    }

    Context "Documentation Files"{
        It "has a README file"{
            "$RootPath\README.md" | Should Exist
            }

        It "has a LICENSE file"{
            "$RootPath\LICENSE.md" | Should Exist
        }

        It "has PlatyPS source files"{
            $Functions =Get-Command -Module $ModuleName
            foreach($Function in $Functions){
                "$RootPath\docs\$Function.md" | Should Exist
            }
        }

        It "has valid links in README file"{
            $READMEMedia = Get-Content "$RootPath\README.md" | Select-String -SimpleMatch !
            foreach ($File in $ReadMeMedia){
                $File = $File.ToString().Split('(').Replace(')','')[1]
                "$RootPath\$File" | Should Exist
            }
        }

    }
}

Describe "$ModuleName Function Tests" {

    $Functions = Get-Command -Module $ModuleName

    foreach ($Function in $Functions){
        Get-Help -Name $Function
        Context "Function : $Function" {
            It "has help"{
                Get-Help -Name $Function | Should Not BeLike "*Get-Help cannot find the Help files for this cmdlet on this computer*"
            }
            It "has a synopsis"{
                Get-Help $Function | Select-Object -ExpandProperty Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
            }
            It "has a description"{
                Get-Help $Function | Select-Object -ExpandProperty Description | Should Not BeNullOrEmpty
            }
            It "has an example in help"{
                Get-Help $Function | Select-Object -ExpandProperty Examples | Measure-Object | Select-Object -ExpandProperty Count | Should Not Be '0'
            }
        }
    }
}
Remove-Module $ModuleName