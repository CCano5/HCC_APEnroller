Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
# Load modified Get-WindowsAutopilotInfo function
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/JaredSeavyHodge/PowerShell-OSD/main/Functions/Get-WindowsAutopilotInfo.ps1')
# Load Start-OobeTasks function
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/JaredSeavyHodge/PowerShell-OSD/main/Functions/Start-OobeTasks.ps1')
# Load OSDCloud functions for OOBE
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OSDeploy/OSD/master/cloud/modules/_oobe.psm1')

# Collect computer information
$OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$serialNumber = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue | Select -ExpandProperty SerialNumber -ErrorAction SilentlyContinue
$isRegistered = "Unknown"
try {
    $isRegistered = Get-WindowsAutoPilotInfo -CheckIfRegistered -ErrorAction stop
}
catch {
    Write-Host -ForegroundColor DarkGray "Could not determine if already registered in autopilot. Error Message: $($_.Exception.Message)"
    $isRegistered = "Unknown"
}

$ComputerInfoText = ""
$ComputerInfoText += "Computer Name: " + $env:COMPUTERNAME + "`n"
$ComputerInfoText += "Computer Serial: " + ($serialNumber) + "`n"
$ComputerInfoText += "Operating System: " + ($OSInfo | Select -ExpandProperty Caption) + "`n"
$ComputerInfoText += "Operating System Version: " + ($OSInfo | Select -ExpandProperty Version ) + "`n"
$ComputerInfoText += "Operating System Build: " + ($OSInfo | Select -ExpandProperty BuildNumber) + "`n"
$ComputerInfoText += "Operating System Architecture: " + ($OSInfo | Select -ExpandProperty OSArchitecture) + "`n"
$ComputerInfoText += "Operating System Install Date: " + ($OSInfo | Select -ExpandProperty InstallDate) + "`n"
$ComputerInfoText += "Operating System Last Boot Up Time: " + ($OSInfo | Select -ExpandProperty LastBootUpTime) + "`n"
$ComputerInfoText += "Autopilot Registered: " + ($isRegistered) + "`n"

# Create the form
$FormSizeX = 465
$FormSizeY = 600
$form = New-Object System.Windows.Forms.Form 
$form.Text = "HCC Autopilot Enroller"
$form.Size = New-Object System.Drawing.Size($FormSizeX,$FormSizeY) # Adjusted form size to accommodate new elements
$form.StartPosition = "CenterScreen"

# Add an image logo to the form
$image = [System.Drawing.Image]::Fromfile("$PSScriptRoot\HCC_Logo.png")
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Width = $image.Width
$pictureBox.Height = $image.Height
$pictureBox.Image = $image
$pictureBox.Location = New-Object System.Drawing.Point(($FormSizeX/2 - $pictureBox.Width/2),10) # Centered horizontally at the top of the form
$form.Controls.Add($pictureBox)

# Adjust position of other elements to accommodate the image
$label = New-Object System.Windows.Forms.Label
$label.Text = $ComputerInfoText
$label.Location = New-Object System.Drawing.Point(10, $pictureBox.Height + 20) # Positioned under the picture box
$label.Size = New-Object System.Drawing.Size($FormSizeX - 20, 200) # Adjust width to fit within form
$form.Controls.Add($label)

# Set up the button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(($FormSizeX/2 - 50), $pictureBox.Height + $label.Height + 30) # Centered horizontally and placed under the label
$OKButton.Size = New-Object System.Drawing.Size(100,25)
$OKButton.Text = "OK"
$OKButton.Add_Click({
    # Set the task sequence variable so the enrollment script runs
    # Invoke-Expression 'Set-WmiInstance -Namespace root\cimv2 -Class OSDCloud -Property @{AutoPilotEnroll="True"}'
    Start-OobeTasks
    # Close the form
    $form.Close()
    # Open Edge
    Start-Process "microsoft-edge:http://google.com"
})
$form.Controls.Add($OKButton)

# Show the form
$form.ShowDialog()
