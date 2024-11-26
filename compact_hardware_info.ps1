# Compact JSON Hardware Information Script for NFC Tag

# Debug log file
$debugLogFile = "Debug_Log.txt"
Set-Content -Path $debugLogFile -Value "Debugging Log - $(Get-Date)`n"

function Log-Debug {
    param([string]$Message)
    Add-Content -Path $debugLogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Host $Message
}

try {
    Log-Debug "Gathering compact hardware information..."

    # Gather hardware information
    $hardwareData = @{
        S = @{
            M  = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
            Md = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
        }
        C = @{
            N  = ((Get-CimInstance -ClassName Win32_Processor).Name -replace "\s+", "")
            Cr = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
            T  = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
        }
        R = @{
            Tt = "$([math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0))G"
        }
        O = @{
            N = ((Get-CimInstance -ClassName Win32_OperatingSystem).Caption -replace "Microsoft ", "")
            A = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture
        }
        St = @{
            D = (Get-CimInstance -ClassName Win32_DiskDrive | ForEach-Object {
                $size = [math]::Round($_.Size / 1GB, 0)
                if ($size -ge 500) { "$($_.Model.Split(' ')[0]):${size}G" }
            }) -join ","
        }
        G = @{
            Ad = (Get-CimInstance -ClassName Win32_VideoController | ForEach-Object {
                $ram = [math]::Round($_.AdapterRAM / 1GB, 0)
                if ($ram -gt 0) { "$($_.Name.Split(' ')[0]):${ram}G" }
            }) -join ","
        }
        Nt = @{
            MAC = (Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true -and $_.MACAddress } | Select-Object -First 1).MACAddress
        }
    }

    if (-not $hardwareData.Nt.MAC) {
        $hardwareData.Nt.MAC = "N/A"
    }

    Log-Debug "Compact hardware data collected: $(ConvertTo-Json $hardwareData -Depth 2 -Compress)"

    # Convert to compact JSON format
    $jsonData = $hardwareData | ConvertTo-Json -Depth 2 -Compress
    Log-Debug "JSON Data: $jsonData"

    # Save JSON to file for verification
    Set-Content -Path "Compact_Hardware_Data.json" -Value $jsonData
    Log-Debug "JSON data saved to Compact_Hardware_Data.json"

    # Ensure the data fits within 500 bytes
    $jsonDataSize = [System.Text.Encoding]::UTF8.GetByteCount($jsonData)
    Log-Debug "JSON Data Length (bytes): $jsonDataSize"

    if ($jsonDataSize -le 500) {
        Write-Host "JSON Data fits within 500 bytes."
        Write-Host "JSON Data saved to file: Compact_Hardware_Data.json"
    } else {
        Write-Host "JSON Data exceeds 500 bytes. Consider reducing the data further."
    }

} catch {
    Log-Debug "Error: $($_.Exception.Message)"
    Write-Host "Failed to gather or process hardware data."
}

# Display debugging log location
Write-Host "`nDebugging log saved to: $((Get-Item $debugLogFile).FullName)"
Write-Host "Script completed."
