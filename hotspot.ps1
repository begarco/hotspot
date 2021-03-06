########################################################################
# HotSpot
# Created On: 16/04/2017 21:40
# Author: begarco
########################################################################

# Generate the GUI Form
function GenerateForm {

##----------------------------------------------
##----------------------------------------------
##
##   Import Block
##
##----------------------------------------------
##----------------------------------------------
#region Import Block
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion Import Block

#region .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
#endregion

##----------------------------------------------
##----------------------------------------------
##
##   Declaration Block
##
##----------------------------------------------
##----------------------------------------------
#region Declaration Block
$mainWindow = New-Object System.Windows.Forms.Form
$console = New-Object System.Windows.Forms.RichTextBox
$configBox = New-Object System.Windows.Forms.GroupBox
$textBoxKey = New-Object System.Windows.Forms.TextBox
$labelKey = New-Object System.Windows.Forms.Label
$textBoxName = New-Object System.Windows.Forms.TextBox
$labelName = New-Object System.Windows.Forms.Label
$startButton = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

$global:networkState = $False;
#endregion Declaration Block

##----------------------------------------------
##----------------------------------------------
##
##   Function Block
##
##----------------------------------------------
##----------------------------------------------
#region Function Block

#----------------------------------------------
#    Check correctness of a password
#----------------------------------------------
Function Check-Password ($password)
{
    return "$password" -match '^[\x00-\x7f]{8,63}$';
}

#----------------------------------------------
#    Check already started
#----------------------------------------------
Function Check-Already-Started ()
{
    $status = (netsh wlan show hostednetwork)[3];
    return "$status" -match 'autorisé';
}

Function Get-Hosted-Network-Name ()
{    
    $exists = (netsh wlan show hostednetwork)[4] -match '«.+»';
    if($exists) {
        $name = $matches[0].Substring(2,$matches[0].Length-4);
    }
    return $name;
}

#----------------------------------------------
#    Hide the console
#----------------------------------------------
function Hide-Console
{
    $consolePtr = [Console.Window]::GetConsoleWindow();
    [Console.Window]::ShowWindow($consolePtr, 0);
}

#endregion Function Block

##----------------------------------------------
##----------------------------------------------
##
##   Event Block
##
##----------------------------------------------
##----------------------------------------------
#region Event Block

#----------------------------------------------
#    Callback for start/stop wifi hotspot
#----------------------------------------------
$handler_start_stop= 
{
    if($global:networkState -eq $False) {
        if($textBoxName.Text -eq "") {
            $textBoxName.Text = "BeGarco Hotspot";
        }
        if($textBoxKey.Text -eq "") {
            $textBoxKey.Text = "BeGarco!";
        }
        $retour = netsh wlan set hostednetwork mode=allow ssid=($textBoxName.Text) key=($textBoxKey.Text) | Out-String;
        if(Check-Password ($textBoxKey.Text)) {
            #$console.AppendText($retour);
            $retour = netsh wlan start hostednetwork | Out-String;
            if($? -eq $True) {
                $global:networkState = $True;
                $startButton.Text = "Stop";
                $console.AppendText("Le hotspot WiFi " + $textBoxName.Text + " a démarré avec succès." + ([Environment]::NewLine));
            } else {
                $console.AppendText("Le hotspot WiFi " + $textBoxName.Text + " n'a pas pu démarrer." + ([Environment]::NewLine));
            }
        } else {
            $console.AppendText("Le mot de passe suivant n'est pas correct : " + $textBoxKey.Text + ([Environment]::NewLine) + "Le mot de passe doit comporter entre 8 et 63 caractères ASCII." + ([Environment]::NewLine));
        }
    } else {
        $retour = netsh wlan set hostednetwork mode=disallow | Out-String;
        #$console.AppendText($retour);
        $retour = netsh wlan stop hostednetwork | Out-String;
        if($? -eq $True) {
            $global:networkState = $False;
            $startButton.Text = "Start";
            $console.AppendText("Le hotspot WiFi " + $textBoxName.Text + " s'est arrêté avec succès." + ([Environment]::NewLine));
        } else {
            $console.AppendText("Le hotspot WiFi " + $textBoxName.Text + " n'a pas pu être stoppé." + ([Environment]::NewLine));
        }
    }
}

#----------------------------------------------
#    Callback for form close
#----------------------------------------------
$hotspot_FormClosed= 
{
    netsh wlan set hostednetwork mode=disallow;
    netsh wlan stop hostednetwork;
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$mainWindow.WindowState = $InitialFormWindowState
    Hide-Console
    $global:networkState = Check-Already-Started;
    if($global:networkState) {
        $textBoxName.Text = Get-Hosted-Network-Name;
        $startButton.Text = "Stop";
        $console.AppendText("Le hotspot WiFi " + $textBoxName.Text + " est déjà en fonctionnement." + ([Environment]::NewLine));
    }
}

#endregion Event Block

##----------------------------------------------
##----------------------------------------------
##
##   View Build Block
##
##----------------------------------------------
##----------------------------------------------
#region View Block

$mainWindow.AutoSizeMode = 0
$mainWindow.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 369
$System_Drawing_Size.Width = 284
$mainWindow.ClientSize = $System_Drawing_Size
$mainWindow.DataBindings.DefaultDataSourceUpdateMode = 0
$mainWindow.Name = "mainWindow"
$mainWindow.Text = "HotSpot"
$mainWindow.add_FormClosed($hotspot_FormClosed)

$console.Anchor = 15
$console.BackColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
$console.BorderStyle = 0
$console.DataBindings.DefaultDataSourceUpdateMode = 0
$console.ForeColor = [System.Drawing.Color]::FromArgb(255,0,255,0)
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 168
$console.Location = $System_Drawing_Point
$console.Name = "console"
$console.ReadOnly = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 189
$System_Drawing_Size.Width = 260
$console.Size = $System_Drawing_Size
$console.TabIndex = 1
$console.Text = ""

$mainWindow.Controls.Add($console)

$configBox.Anchor = 13
$configBox.AutoSizeMode = 0

$configBox.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 12
$configBox.Location = $System_Drawing_Point
$configBox.Name = "configBox"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 150
$System_Drawing_Size.Width = 260
$configBox.Size = $System_Drawing_Size
$configBox.TabIndex = 0
$configBox.TabStop = $False
$configBox.Text = "Configuration"

$mainWindow.Controls.Add($configBox)
$textBoxKey.Anchor = 13
$textBoxKey.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 84
$textBoxKey.Location = $System_Drawing_Point
$textBoxKey.Name = "textBoxKey"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 247
$textBoxKey.Size = $System_Drawing_Size
$textBoxKey.TabIndex = 4
$textBoxKey.UseSystemPasswordChar = $True

$configBox.Controls.Add($textBoxKey)

$labelKey.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 66
$labelKey.Location = $System_Drawing_Point
$labelKey.Name = "labelKey"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 15
$System_Drawing_Size.Width = 247
$labelKey.Size = $System_Drawing_Size
$labelKey.TabIndex = 3
$labelKey.Text = "Clé de sécurité"

$configBox.Controls.Add($labelKey)

$textBoxName.Anchor = 13
$textBoxName.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 39
$textBoxName.Location = $System_Drawing_Point
$textBoxName.Name = "textBoxName"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 247
$textBoxName.Size = $System_Drawing_Size
$textBoxName.TabIndex = 2

$configBox.Controls.Add($textBoxName)

$labelName.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 21
$labelName.Location = $System_Drawing_Point
$labelName.Name = "labelName"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 15
$System_Drawing_Size.Width = 247
$labelName.Size = $System_Drawing_Size
$labelName.TabIndex = 1
$labelName.Text = "Nom du réseau Wi-Fi"

$configBox.Controls.Add($labelName)

$startButton.Anchor = 13
$startButton.AutoSizeMode = 0

$startButton.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 110
$startButton.Location = $System_Drawing_Point
$startButton.Name = "startButton"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 34
$System_Drawing_Size.Width = 247
$startButton.Size = $System_Drawing_Size
$startButton.TabIndex = 0
$startButton.Text = "Start"
$startButton.UseVisualStyleBackColor = $True
$startButton.add_Click($handler_start_stop)

$configBox.Controls.Add($startButton)

$mainWindow.Width = 400;
$mainWindow.Height = 420;

#endregion View Block

##----------------------------------------------
##----------------------------------------------
##
##   Start Block
##
##----------------------------------------------
##----------------------------------------------
#region Start Block

#Save the initial state of the form
$InitialFormWindowState = $mainWindow.WindowState
#Init the OnLoad event to correct the initial state of the form
$mainWindow.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$mainWindow.ShowDialog()| Out-Null

#endregion Start Block
}

#Call the Function
GenerateForm
