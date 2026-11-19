Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Force TLS 1.2 / TLS 1.3 for secure HaloPSA API communication
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
} catch {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

# 1. Configuration
$HaloUrl = "https://theinstillery.halopsa.com"

# 2. XAML Definition
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="HaloPSA Weekly Timesheet" Height="1000" Width="1800" WindowStartupLocation="CenterScreen">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,15">
            <Label Content="Bearer Token:" VerticalAlignment="Center" FontWeight="Bold"/>
            <PasswordBox Name="TokenBox" Width="200" Margin="5,0,15,0" VerticalAlignment="Center"/>
            
            <Label Content="Select Week:" VerticalAlignment="Center" FontWeight="Bold"/>
            <DatePicker Name="WeekPicker" Width="120" Margin="5,0,15,0" VerticalAlignment="Center"/>
            
            <CheckBox Name="FetchExistingChk" Content="Fetch Existing Time (Slower)" IsChecked="true" VerticalAlignment="Center" Margin="5,0,15,0" FontWeight="Bold" Foreground="#D66000"/>
            <CheckBox Name="FetchAllTicketsChk" Content="Show All Tickets" VerticalAlignment="Center" Margin="5,0,15,0" FontWeight="Bold"/>

            <Button Name="LoadBtn" Content="Load Timesheet" Width="120" Padding="5" Background="#0078D7" Foreground="White" FontWeight="Bold"/>
            <Button Name="HowItWorksBtn" Content="How It Works" Width="110" Margin="10,0,0,0" Padding="5" Background="#17A2B8" Foreground="White" FontWeight="Bold"/>
        </StackPanel>

        <TextBlock Name="StatusText" Grid.Row="1" Text="Ready to load..." Foreground="Gray" Margin="0,0,0,10" FontWeight="Bold"/>

        <DataGrid Name="TimesheetGrid" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" AlternatingRowBackground="#F0F0F0" HeadersVisibility="Column" HorizontalScrollBarVisibility="Auto">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding TicketID}" IsReadOnly="True" Width="45"/>
                <DataGridTextColumn Header="Type" Binding="{Binding TicketType}" IsReadOnly="True" Width="105">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Client Name" Binding="{Binding ClientName}" IsReadOnly="True" Width="*" MinWidth="100">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Project" Binding="{Binding Project}" IsReadOnly="True" Width="*" MinWidth="150">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Ticket Summary" Binding="{Binding TicketSummary}" IsReadOnly="True" Width="*" MinWidth="150">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridCheckBoxColumn Header="Override" Binding="{Binding HasOverride}" Width="55"/>
                <DataGridTextColumn Header="Ticket Note" Binding="{Binding TicketNote}" Width="*" MinWidth="90">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>

                <DataGridTextColumn Header="Mon" Binding="{Binding Mon}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding MonHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Tue" Binding="{Binding Tue}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding TueHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Wed" Binding="{Binding Wed}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding WedHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Thu" Binding="{Binding Thu}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding ThuHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Fri" Binding="{Binding Fri}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding FriHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sat" Binding="{Binding Sat}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SatHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sun" Binding="{Binding Sun}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SunHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>

                <DataGridTextColumn Header="Row Total" Binding="{Binding Total}" IsReadOnly="True" Width="60" FontWeight="Bold"/>
            </DataGrid.Columns>
        </DataGrid>

        <Border Grid.Row="3" Background="#343A40" CornerRadius="3" Margin="0,5,0,10" Padding="10,5">
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="DAILY TOTALS:" Foreground="White" FontWeight="Bold" VerticalAlignment="Center" Width="150" Margin="0,0,20,0"/>
                <TextBlock Text="Mon: " Foreground="White"/><TextBlock Name="TotMon" Text="0" Foreground="#28A745" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Tue: " Foreground="White"/><TextBlock Name="TotTue" Text="0" Foreground="#28A745" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Wed: " Foreground="White"/><TextBlock Name="TotWed" Text="0" Foreground="#28A745" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Thu: " Foreground="White"/><TextBlock Name="TotThu" Text="0" Foreground="#28A745" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Fri: " Foreground="White"/><TextBlock Name="TotFri" Text="0" Foreground="#28A745" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Sat: " Foreground="White"/><TextBlock Name="TotSat" Text="0" Foreground="#FFC107" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="Sun: " Foreground="White"/><TextBlock Name="TotSun" Text="0" Foreground="#FFC107" FontWeight="Bold" Width="40" Margin="0,0,10,0"/>
                <TextBlock Text="WEEK TOTAL: " Foreground="White" Margin="20,0,0,0"/><TextBlock Name="TotWeek" Text="0" Foreground="#17A2B8" FontWeight="Bold" FontSize="14" Width="50"/>
            </StackPanel>
        </Border>

        <WrapPanel Grid.Row="4" Orientation="Horizontal" Margin="0,5,0,0">
            <StackPanel Orientation="Horizontal" Margin="0,2,15,2">
                <Label Content="Project Charge Code:" VerticalAlignment="Center" FontWeight="Bold"/>
                <ComboBox Name="ChargeCodeCombo" Width="160" Margin="5,0,0,0" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            </StackPanel>

            <StackPanel Orientation="Horizontal" Margin="0,2,15,2">
                <Label Content="Consulting Charge Code:" VerticalAlignment="Center" FontWeight="Bold"/>
                <ComboBox Name="ConsultingChargeCodeCombo" Width="160" Margin="5,0,0,0" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            </StackPanel>

            <StackPanel Orientation="Horizontal" Margin="0,2,15,2">
                <Label Content="Service / Evergreen Charge Code:" VerticalAlignment="Center" FontWeight="Bold"/>
                <ComboBox Name="ServiceChargeCodeCombo" Width="160" Margin="5,0,0,0" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            </StackPanel>

            <StackPanel Orientation="Horizontal" Margin="0,2,0,2">
                <Label Content="Default Note:" VerticalAlignment="Center" FontWeight="Bold"/>
                <TextBox Name="NoteBox" Width="220" Margin="5,0,0,0" VerticalAlignment="Center" Text=""/>
            </StackPanel>
        </WrapPanel>

        <Button Name="SubmitBtn" Grid.Row="5" Content="Submit Time Entries" Height="40" Margin="0,15,0,0" Background="#28A745" Foreground="White" FontWeight="Bold" FontSize="14"/>
    </Grid>
</Window>
"@

# 3. Read XAML and Load UI Elements
$Reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$TokenBox           = $Window.FindName("TokenBox")
$WeekPicker         = $Window.FindName("WeekPicker")
$FetchExistingChk   = $Window.FindName("FetchExistingChk")
$FetchAllTicketsChk = $Window.FindName("FetchAllTicketsChk")
$LoadBtn            = $Window.FindName("LoadBtn")
$HowItWorksBtn      = $Window.FindName("HowItWorksBtn")
$SubmitBtn          = $Window.FindName("SubmitBtn")
$TimesheetGrid      = $Window.FindName("TimesheetGrid")
$StatusText         = $Window.FindName("StatusText")
$NoteBox            = $Window.FindName("NoteBox")
$ChargeCodeCombo           = $Window.FindName("ChargeCodeCombo")
$ConsultingChargeCodeCombo = $Window.FindName("ConsultingChargeCodeCombo")
$ServiceChargeCodeCombo    = $Window.FindName("ServiceChargeCodeCombo")

# Footer Totals Elements
$TotMon = $Window.FindName("TotMon"); $TotTue = $Window.FindName("TotTue"); $TotWed = $Window.FindName("TotWed")
$TotThu = $Window.FindName("TotThu"); $TotFri = $Window.FindName("TotFri"); $TotSat = $Window.FindName("TotSat")
$TotSun = $Window.FindName("TotSun"); $TotWeek = $Window.FindName("TotWeek")

$WeekPicker.SelectedDate = [datetime]::Today
$Global:OriginalData = @()
$Global:LoadedDates = @{}

# HELPER FUNCTION: Recalculate Totals
$UpdateTotals = {
    $TMon = 0; $TTue = 0; $TWed = 0; $TThu = 0; $TFri = 0; $TSat = 0; $TSun = 0
    if ($null -ne $TimesheetGrid.ItemsSource) {
        foreach ($Row in $TimesheetGrid.ItemsSource) {
            $M = 0; [double]::TryParse($Row.Mon, [ref]$M) | Out-Null; $TMon += $M
            $T = 0; [double]::TryParse($Row.Tue, [ref]$T) | Out-Null; $TTue += $T
            $W = 0; [double]::TryParse($Row.Wed, [ref]$W) | Out-Null; $TWed += $W
            $Th= 0; [double]::TryParse($Row.Thu, [ref]$Th)| Out-Null; $TThu += $Th
            $F = 0; [double]::TryParse($Row.Fri, [ref]$F) | Out-Null; $TFri += $F
            $Sa= 0; [double]::TryParse($Row.Sat, [ref]$Sa)| Out-Null; $TSat += $Sa
            $Su= 0; [double]::TryParse($Row.Sun, [ref]$Su)| Out-Null; $TSun += $Su
            $Row.Total = $M + $T + $W + $Th + $F + $Sa + $Su
        }
    }
    $TotMon.Text = $TMon; $TotTue.Text = $TTue; $TotWed.Text = $TWed
    $TotThu.Text = $TThu; $TotFri.Text = $TFri; $TotSat.Text = $TSat; $TotSun.Text = $TSun
    $TotWeek.Text = $TMon + $TTue + $TWed + $TThu + $TFri + $TSat + $TSun
    # Try to refresh the row totals visually, but fail silently if the user is already tabbing into the next cell
    try {
        $TimesheetGrid.Items.Refresh()
    } catch { }
}

# HELPER FUNCTION: Override Input Box (Custom Note + Custom Charge Code)
function Show-OverrideInputBox {
    param (
        [string]$Title = "Time Entry Override",
        [string]$PromptMessage,
        [string]$DefaultNote = "",
        [System.Collections.IEnumerable]$ChargeCodes,
        [string]$SelectedChargeCode = ""
    )

    [xml]$InputXAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Height="380" Width="480" WindowStartupLocation="CenterScreen"
            ResizeMode="NoResize">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <TextBlock Name="PromptTextBlock" Grid.Row="0" Margin="0,0,0,12" TextWrapping="Wrap" FontWeight="Bold"/>
            
            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,12">
                <Label Content="Charge Code:" VerticalAlignment="Center" FontWeight="Bold" Width="100"/>
                <ComboBox Name="PopupChargeCodeCombo" Width="330" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            </StackPanel>
            
            <DockPanel Grid.Row="2" Margin="0,0,0,10">
                <Label Content="Custom Note:" DockPanel.Dock="Top" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBox Name="InputTextBox" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
            </DockPanel>

            <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
                <Button Name="OkButton" Content="OK" Width="80" Height="28" Margin="0,0,10,0" IsDefault="True" />
                <Button Name="CancelButton" Content="Cancel" Width="80" Height="28" IsCancel="True" />
            </StackPanel>
        </Grid>
    </Window>
"@
    $InputReader = (New-Object System.Xml.XmlNodeReader $InputXAML)
    $InputWindow = [Windows.Markup.XamlReader]::Load($InputReader)
    if ($null -ne $Window -and $Window.IsLoaded) { $InputWindow.Owner = $Window }
    
    $InputWindow.Title = $Title
    $InputWindow.FindName("PromptTextBlock").Text = $PromptMessage
    
    $PopupCombo = $InputWindow.FindName("PopupChargeCodeCombo")
    $PopupCombo.ItemsSource = $ChargeCodes
    
    if (-not [string]::IsNullOrWhiteSpace($SelectedChargeCode) -and ($ChargeCodes | Where-Object { [string]$_.ID -eq [string]$SelectedChargeCode })) {
        $PopupCombo.SelectedValue = [string]$SelectedChargeCode
    } elseif ($null -ne $ChargeCodes -and $ChargeCodes.Count -gt 0) {
        $PopupCombo.SelectedIndex = 0
    }
    
    $InputTextBox = $InputWindow.FindName("InputTextBox")
    $InputTextBox.Text = $DefaultNote
    
    $OkBtn = $InputWindow.FindName("OkButton")
    $OkBtn.Add_Click({ $InputWindow.DialogResult = $true })
    
    # Auto-focus and select text when the window appears
    $InputWindow.Add_ContentRendered({
        $InputTextBox.Focus() | Out-Null
        $InputTextBox.SelectAll()
    })
    
    $Result = $InputWindow.ShowDialog()
    
    if ($Result) {
        $ChosenChargeCode = if ($null -ne $PopupCombo.SelectedValue -and [string]$PopupCombo.SelectedValue -ne "") { [string]$PopupCombo.SelectedValue } else { $SelectedChargeCode }
        return @{
            Note       = $InputTextBox.Text
            ChargeCode = $ChosenChargeCode
        }
    } else {
        return $null
    }
}

# HELPER FUNCTION: How It Works & Help Dialog
function Show-HowItWorksWindow {
    [xml]$HelpXAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="HaloPSA Weekly Timesheet - How It Works &amp; User Guide"
            Height="700" Width="820" WindowStartupLocation="CenterScreen"
            ResizeMode="CanResizeWithGrip">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Header -->
            <Border Grid.Row="0" Background="#0078D7" CornerRadius="4" Padding="15,10" Margin="0,0,0,12">
                <StackPanel>
                    <TextBlock Text="HaloPSA Weekly Timesheet Tool" Foreground="White" FontSize="18" FontWeight="Bold"/>
                    <TextBlock Text="User Guide, Features, Limitations &amp; Security Overview" Foreground="#E2E2E2" FontSize="12" Margin="0,3,0,0"/>
                </StackPanel>
            </Border>

            <!-- Content Area -->
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel Margin="0,0,10,0">
                    
                    <!-- Section 1: Bearer Token -->
                    <Border Background="#F8F9FA" BorderBrush="#DEE2E6" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[1] Bearer Token Management &amp; How to Acquire" FontSize="14" FontWeight="Bold" Foreground="#333"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#444" FontSize="12">
                                - <Run FontWeight="Bold">How to get your Bearer Token:</Run> Log into HaloPSA in your web browser. Open Developer Tools (F12) -&gt; Network tab. Perform any action or refresh. Inspect an API request header under 'Authorization' and copy the token string following 'Bearer '.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Security Notice:</Run> Your token is processed in-memory only for direct API calls to HaloPSA and is <Run FontWeight="Bold">never stored or saved to disk</Run>.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 2: Loading & Grid Operations -->
                    <Border Background="#F8F9FA" BorderBrush="#DEE2E6" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[2] Loading Timesheets &amp; Grid Controls" FontSize="14" FontWeight="Bold" Foreground="#333"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#444" FontSize="12">
                                - <Run FontWeight="Bold">Select Week:</Run> Choose any date; the tool automatically resolves Monday through Sunday for that week.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Fetch Existing Time (Slower):</Run> Pulls historical logged hours for the week from HaloPSA into the grid cells.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Show All Tickets:</Run> By default, the tool shows Project (Type 20), Consulting (Type 100), Service Request (Type 3), &amp; Evergreen (Type 114) tickets. Check this to load all assigned open tickets (note: other unmapped ticket types cannot have time posted via this tool).
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 3: Charge Codes & Notes -->
                    <Border Background="#F8F9FA" BorderBrush="#DEE2E6" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[3] Charge Codes &amp; Notes Management" FontSize="14" FontWeight="Bold" Foreground="#333"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#444" FontSize="12">
                                - <Run FontWeight="Bold">Charge Code Dropdowns:</Run> Separate dropdowns allow setting default charge rates for Project tickets, Consulting tickets, and a shared dropdown for Service Request &amp; Evergreen tickets.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Ticket Note Column:</Run> Enter specific notes per ticket directly up front in the grid. Blank notes fall back to the 'Default Note' box.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">0.25 Time Block Enforcement:</Run> All added time entries must be in 15-minute (0.25h) increments. Any entry that isn't will be rejected with a warning and skipped on submit.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 4: Override Feature -->
                    <Border Background="#FFF3CD" BorderBrush="#FFEEBA" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[4] How the 'Override' Checkbox Works" FontSize="14" FontWeight="Bold" Foreground="#856404"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#856404" FontSize="12">
                                - <Run FontWeight="Bold">Targeted Popups Only:</Run> Standard time entries submit silently without popup prompts.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Dual Customization:</Run> Checking the <Run FontWeight="Bold">Override</Run> box on a ticket row triggers a popup during submit allowing you to specify both a <Run FontWeight="Bold">Custom Charge Code</Run> and a <Run FontWeight="Bold">Custom Note</Run> specifically for that entry.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 5: Limitations -->
                    <Border Background="#F8D7DA" BorderBrush="#F5C6CB" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[5] Tool Limitations" FontSize="14" FontWeight="Bold" Foreground="#721C24"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#721C24" FontSize="12">
                                - <Run FontWeight="Bold">Supported Ticket Types:</Run> Time posting supports Project, Consulting, Service Request, and Evergreen tickets. Entries on other ticket types shown via 'Show All Tickets' will be flagged and skipped during submission.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Adding Time Only:</Run> You can add time to any day where your entered value exceeds existing hours.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">No Reduction/Deletion:</Run> You cannot reduce hours or delete historical time entries via this tool. Modifications to past entries must be performed directly in HaloPSA.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Token Failure Handling:</Run> If your token expires during posting, you can choose to Continue or Cancel; entries already created remain saved.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 6: Disclaimer & Liability -->
                    <Border Background="#E2E3E5" BorderBrush="#D6D8D9" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,5">
                        <StackPanel>
                            <TextBlock Text="[6] Disclaimer &amp; Liability Notice" FontSize="14" FontWeight="Bold" Foreground="#383D41"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#383D41" FontSize="11" FontStyle="Italic">
                                THIS TOOL IS PROVIDED 'AS IS' WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. THE CREATOR AND CONTRIBUTORS ASSUME NO LIABILITY OR RESPONSIBILITY FOR INCORRECT TIME ENTRIES, DATA LOSS, OR SYSTEM ISSUES ARISING FROM THE USE OF THIS APPLICATION.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                </StackPanel>
            </ScrollViewer>

            <!-- Footer Close Button -->
            <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
                <Button Name="CloseHelpBtn" Content="Close Guide" Width="100" Height="30" Background="#0078D7" Foreground="White" FontWeight="Bold"/>
            </StackPanel>
        </Grid>
    </Window>
"@
    $HelpReader = (New-Object System.Xml.XmlNodeReader $HelpXAML)
    $HelpWindow = [Windows.Markup.XamlReader]::Load($HelpReader)
    if ($null -ne $Window -and $Window.IsLoaded) { $HelpWindow.Owner = $Window }
    
    $CloseBtn = $HelpWindow.FindName("CloseHelpBtn")
    $CloseBtn.Add_Click({ $HelpWindow.Close() })
    
    $HelpWindow.ShowDialog() | Out-Null
}

$HowItWorksBtn.Add_Click({
    Show-HowItWorksWindow
})

$TimesheetGrid.Add_CellEditEnding({
    $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $Action = [Action]{ &$UpdateTotals }
    $Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::ContextIdle, $Action) | Out-Null
})

# 4. Load Data Button Event
$LoadBtn.Add_Click({
    if ([string]::IsNullOrWhiteSpace($TokenBox.Password)) {
        $StatusText.Text = "Error: Please enter a Bearer Token."
        $StatusText.Foreground = "Red"
        return
    }

    $StatusText.Text = "Loading tickets... Please wait."
    $StatusText.Foreground = "Blue"
    [System.Windows.Forms.Application]::DoEvents() 

    $Headers = @{
        "Authorization" = "Bearer $($TokenBox.Password)"
        "Content-Type"  = "application/json"
    }

    # LOAD AGENT DETAILS (to get AgentID for filtering)
    try {
        $agentUri = "$HaloUrl/api/Agent/me"
        $agentResp = Invoke-RestMethod -Uri $agentUri -Method Get -Headers $Headers
        $AgentID = $agentResp.id
        $AgentChargeRate = $agentResp.chargerate
        $AgentChargeRateStr = if ($null -ne $AgentChargeRate) { [string]$AgentChargeRate } else { "" }
    } catch {
        $ErrMsg = if ($_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        $StatusText.Text = "Failed to retrieve agent details. $ErrMsg"
        $StatusText.Foreground = "Red"
        return
    }

    # FETCH CHARGE CODES (Lookup ID 17)
    try {
        # Fetch Project Charge Codes (outcome 132, tickettype 20)
        $LookupUri = "$HaloUrl/api/lookup?lookupid=17&outcome_id=132&tickettype_id=20"
        $LookupResp = Invoke-RestMethod -Uri $LookupUri -Method Get -Headers $Headers
        
        $ComboData = @()
        foreach ($Item in ($LookupResp | Where-Object { -not $_.inactive })) {
            # Halo Lookups usually return id and name. Store ID as string so "0" ("No Charge") matches reliably.
            $ComboData += [PSCustomObject]@{
                ID = [string]$Item.id
                Name = $Item.name
            }
        }
        $ChargeCodeCombo.ItemsSource = $ComboData
        
        if ($ComboData.Count -gt 0) {
            if (-not [string]::IsNullOrEmpty($AgentChargeRateStr) -and ($ComboData.ID -contains $AgentChargeRateStr)) {
                $ChargeCodeCombo.SelectedValue = $AgentChargeRateStr
            } else {
                $ChargeCodeCombo.SelectedIndex = 0
            }
        }

        # Fetch Consulting Charge Codes (outcome 269, tickettype 100)
        try {
            $ConsultingLookupUri = "$HaloUrl/api/lookup?lookupid=17&outcome_id=269&tickettype_id=100"
            $ConsultingLookupResp = Invoke-RestMethod -Uri $ConsultingLookupUri -Method Get -Headers $Headers
            $ConsultingComboData = @()
            foreach ($Item in ($ConsultingLookupResp | Where-Object { -not $_.inactive })) {
                $ConsultingComboData += [PSCustomObject]@{
                    ID = [string]$Item.id
                    Name = $Item.name
                }
            }

            if ($ConsultingComboData.Count -gt 0) {
                $ConsultingChargeCodeCombo.ItemsSource = $ConsultingComboData
                if (-not [string]::IsNullOrEmpty($AgentChargeRateStr) -and ($ConsultingComboData.ID -contains $AgentChargeRateStr)) {
                    $ConsultingChargeCodeCombo.SelectedValue = $AgentChargeRateStr
                } else {
                    $ConsultingChargeCodeCombo.SelectedIndex = 0
                }
            } else {
                $ConsultingChargeCodeCombo.ItemsSource = $ComboData
                $ConsultingChargeCodeCombo.SelectedValue = $ChargeCodeCombo.SelectedValue
            }
        } catch {
            $ConsultingChargeCodeCombo.ItemsSource = $ComboData
            $ConsultingChargeCodeCombo.SelectedValue = $ChargeCodeCombo.SelectedValue
        }

        # Fetch Service Request / Evergreen Charge Codes (outcome 108, tickettype 3 primary with tickettype 114 fallback)
        $ServiceComboData = @()
        foreach ($ServiceLookupUri in @(
            "$HaloUrl/api/lookup?lookupid=17&outcome_id=108&tickettype_id=3",
            "$HaloUrl/api/lookup?lookupid=17&use=0&outcome_id=108&tickettype_id=114"
        )) {
            try {
                $ServiceLookupResp = Invoke-RestMethod -Uri $ServiceLookupUri -Method Get -Headers $Headers
                foreach ($Item in ($ServiceLookupResp | Where-Object { -not $_.inactive })) {
                    $ServiceComboData += [PSCustomObject]@{
                        ID = [string]$Item.id
                        Name = $Item.name
                    }
                }
                if ($ServiceComboData.Count -gt 0) { break }
            } catch { }
        }

        if ($ServiceComboData.Count -gt 0) {
            $ServiceChargeCodeCombo.ItemsSource = $ServiceComboData
            if (-not [string]::IsNullOrEmpty($AgentChargeRateStr) -and ($ServiceComboData.ID -contains $AgentChargeRateStr)) {
                $ServiceChargeCodeCombo.SelectedValue = $AgentChargeRateStr
            } else {
                $ServiceChargeCodeCombo.SelectedIndex = 0
            }
        } else {
            $ServiceChargeCodeCombo.ItemsSource = $ComboData
            $ServiceChargeCodeCombo.SelectedValue = $ChargeCodeCombo.SelectedValue
        }
    } catch {
        Write-Warning "Failed to load charge codes. $_"
    }

    $SelectedDate = $WeekPicker.SelectedDate
    $Offset = if ($SelectedDate.DayOfWeek -eq 'Sunday') { 6 } else { [int]$SelectedDate.DayOfWeek - 1 }
    $Monday = $SelectedDate.AddDays(-$Offset).Date
    $WeekEnd = $Monday.AddDays(7)
    
    $Global:LoadedDates = @{
        "Mon" = $Monday; "Tue" = $Monday.AddDays(1); "Wed" = $Monday.AddDays(2);
        "Thu" = $Monday.AddDays(3); "Fri" = $Monday.AddDays(4); "Sat" = $Monday.AddDays(5); "Sun" = $Monday.AddDays(6)
    }

    try {
        $Uri = "$HaloUrl/api/Tickets?pageinate=false&agent_id=$AgentID&open_only=true&columns_id=104"
        $Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers
        
        $SupportedTicketTypeIds = @(20, 100, 3, 114)
        if ($FetchAllTicketsChk.IsChecked) {
            $Tickets = @($Response.tickets)
        } else {
            # Filter to supported ticket types: Project (20), Consulting (100), Service Request (3), Evergreen (114)
            $Tickets = @($Response.tickets | Where-Object { $SupportedTicketTypeIds -contains [int]$_.tickettype_id })
        }

        # Deduplicate tickets by ID (Halo's /api/Tickets queue response can include duplicate ticket rows)
        $SeenIds = @{}
        $Tickets = @($Tickets | Where-Object {
            if ($null -ne $_.id -and -not $SeenIds.ContainsKey($_.id)) {
                $SeenIds[$_.id] = $true
                $true
            } else {
                $false
            }
        })

        if ($null -eq $Tickets -or $Tickets.Count -eq 0) {
            $StatusText.Text = "No tickets found for the selected criteria."
            $StatusText.Foreground = "DarkOrange"
            
            # Clear the grid and reset the footer totals
            $TimesheetGrid.ItemsSource = $null
            &$UpdateTotals
            return
        }

        $GridData = @()
        $Global:OriginalData = @()
        $CurrentTicketNum = 1
        $ActionFetchErrors = 0
        $FailedActionTickets = @()

        foreach ($Ticket in $Tickets) {
            # Start hours at 0
            $MonHrs = 0; $TueHrs = 0; $WedHrs = 0; $ThuHrs = 0; $FriHrs = 0; $SatHrs = 0; $SunHrs = 0


            # FETCH EXISTING TIME LOGIC
            if ($FetchExistingChk.IsChecked) {
                $StatusText.Text = "Fetching existing time... ($CurrentTicketNum / $($Tickets.Count))"
                [System.Windows.Forms.Application]::DoEvents()

                try {
                    $ActionsUri = "$HaloUrl/api/Actions?ticket_id=$($Ticket.id)&agentonly=true&pageinate=false"
                    $ActionsResp = Invoke-RestMethod -Uri $ActionsUri -Method Get -Headers $Headers
                    $ActionsList = $ActionsResp.actions | Where-Object {$_.who_agentid -eq $AgentID}

                    foreach ($Act in $ActionsList) {
                        $ActDate = ([datetime]$Act.datetime).ToLocalTime()
                        if ($ActDate -ge $Monday -and $ActDate -lt $WeekEnd -and $Act.timetaken -gt 0) {
                            $Hours = [math]::Round($Act.timetaken, 2)
                            switch ($ActDate.DayOfWeek) {
                                'Monday'    { $MonHrs += $Hours }
                                'Tuesday'   { $TueHrs += $Hours }
                                'Wednesday' { $WedHrs += $Hours }
                                'Thursday'  { $ThuHrs += $Hours }
                                'Friday'    { $FriHrs += $Hours }
                                'Saturday'  { $SatHrs += $Hours }
                                'Sunday'    { $SunHrs += $Hours }
                            }
                        }
                    }
                } catch {
                    $ActionFetchErrors++
                    $FailedActionTickets += $Ticket.id
                    Write-Warning "Failed to fetch existing actions for Ticket $($Ticket.id): $_"
                }
            }
            $CurrentTicketNum++

            $TypeId = [int]$Ticket.tickettype_id
            $TicketTypeName = switch ($TypeId) {
                20      { "Project" }
                100     { "Consulting" }
                3       { "Service Request" }
                114     { "Evergreen" }
                default {
                    if (-not [string]::IsNullOrWhiteSpace($Ticket.tickettype_name)) {
                        "$($Ticket.tickettype_name) (Unsupported)"
                    } else {
                        "Other (Type $TypeId)"
                    }
                }
            }

            # Strip project code prefix only on Project/Consulting tickets; handle numeric-leading Project task names safely
            $FormattedSummary = if ($TypeId -eq 20) {
                if ($Ticket.summary -match "^[^-]+-\s*\d+\s*-\s*(.+)$") {
                    $Matches[1].Trim()
                } elseif ($Ticket.summary -match "-\s+(\D.*)$") {
                    $Matches[1].Trim()
                } else {
                    $Ticket.summary
                }
            } elseif ($TypeId -eq 100 -and ($Ticket.summary -match "-\s+(\D.*)$")) {
                $Matches[1].Trim()
            } else {
                $Ticket.summary
            }

            # Map the new properties directly from the ticket object
            $RowObj = [PSCustomObject]@{
                TicketID      = $Ticket.id
                TicketTypeID  = $TypeId
                TicketType    = $TicketTypeName
                ClientName    = if ($Ticket.client_name) { $Ticket.client_name } else { "Unassigned" }
                Project       = if ($Ticket.parent_subject) { $Ticket.parent_subject -replace " - Parent Project", '' } else { "None" }
                TicketSummary = $FormattedSummary
                HasOverride   = $false
                TicketNote    = ""
                Total = 0
                Mon = $MonHrs; MonHasTime = ($MonHrs -gt 0)
                Tue = $TueHrs; TueHasTime = ($TueHrs -gt 0)
                Wed = $WedHrs; WedHasTime = ($WedHrs -gt 0)
                Thu = $ThuHrs; ThuHasTime = ($ThuHrs -gt 0)
                Fri = $FriHrs; FriHasTime = ($FriHrs -gt 0)
                Sat = $SatHrs; SatHasTime = ($SatHrs -gt 0)
                Sun = $SunHrs; SunHasTime = ($SunHrs -gt 0)
            }
            
            $Global:OriginalData += $RowObj.PSObject.Copy()
            $GridData += $RowObj
        }

        # Sort the array by Client Name alphabetically
        $GridData = $GridData | Sort-Object ClientName, Project, TicketSummary

        # Bind to Grid
        $TimesheetGrid.ItemsSource = [System.Collections.ObjectModel.ObservableCollection[System.Object]]::new($GridData)
        
        &$UpdateTotals 
        
        if ($ActionFetchErrors -gt 0) {
            $StatusText.Text = "Loaded $($Tickets.Count) tickets for the week of $($Monday.ToString('yyyy-MM-dd')) (Warning: failed to fetch existing time for $ActionFetchErrors ticket(s): $($FailedActionTickets -join ', '))."
            $StatusText.Foreground = "DarkOrange"
        } else {
            $StatusText.Text = "Loaded $($Tickets.Count) tickets for the week of $($Monday.ToString('yyyy-MM-dd'))."
            $StatusText.Foreground = "Green"
        }

    } catch {
        $StatusText.Text = "API Error: $_"
        $StatusText.Foreground = "Red"
    }
})

# 5. Submit Button Event
$SubmitBtn.Add_Click({
    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null
    
    # Grab the selected Charge Rates from the dropdowns, defaulting if nothing is selected/loaded (check $null/-ne "" so "0" No Charge works)
    $SelectedProjectChargeRate = if ($null -ne $ChargeCodeCombo.SelectedValue -and [string]$ChargeCodeCombo.SelectedValue -ne "") { [string]$ChargeCodeCombo.SelectedValue } else { "30" }
    $SelectedConsultingChargeRate = if ($null -ne $ConsultingChargeCodeCombo.SelectedValue -and [string]$ConsultingChargeCodeCombo.SelectedValue -ne "") { [string]$ConsultingChargeCodeCombo.SelectedValue } else { $SelectedProjectChargeRate }
    $SelectedServiceChargeRate = if ($null -ne $ServiceChargeCodeCombo.SelectedValue -and [string]$ServiceChargeCodeCombo.SelectedValue -ne "") { [string]$ServiceChargeCodeCombo.SelectedValue } else { $SelectedProjectChargeRate }

    $StatusText.Text = "Calculating and posting time entries..."
    $StatusText.Foreground = "Blue"
    [System.Windows.Forms.Application]::DoEvents()

    $Headers = @{
        "Authorization" = "Bearer $($TokenBox.Password)"
        "Content-Type"  = "application/json"
    }

    # Grab the general default note
    $DefaultNote = $NoteBox.Text

    $CurrentData = $TimesheetGrid.ItemsSource
    $PostCount = 0
    $ErrorCount = 0
    $TokenExpired = $false
    $UserCancelled = $false

    :RowLoop foreach ($CurrentRow in $CurrentData) {
        $OriginalRow = $Global:OriginalData | Where-Object { $_.TicketID -eq $CurrentRow.TicketID } | Select-Object -First 1
        if ($null -eq $OriginalRow) { continue }
        
        $Days = @("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        foreach ($Day in $Days) {
            $CurrentVal = 0
            if (-not [double]::TryParse($CurrentRow.$Day, [ref]$CurrentVal)) {
                $StatusText.Text = "Warning: Invalid number detected in Ticket $($CurrentRow.TicketID) on $Day. Skipped."
                $StatusText.Foreground = "DarkOrange"
                $InvalidMsg = "Invalid number '$($CurrentRow.$Day)' detected in Ticket $($CurrentRow.TicketID) on $Day.`n`nThis entry was skipped."
                [System.Windows.MessageBox]::Show($InvalidMsg, "Invalid Time Entry", 0, 48)
                $ErrorCount++
                continue 
            }

            $OriginalVal = [double]($OriginalRow.$Day)
            $Diff = [math]::Round([decimal]$CurrentVal - [decimal]$OriginalVal, 4)

            if ($Diff -eq 0) { continue }

            if ($Diff -gt 0 -and (($Diff % [decimal]0.25) -ne 0)) {
                $WarnMsg = "Added time must be in increments of 0.25.`n`nTicket $($CurrentRow.TicketID) on $Day (+$Diff hrs) was skipped."
                [System.Windows.MessageBox]::Show($WarnMsg, "Invalid Time Entry", 0, 48)
                $ErrorCount++
                continue
            }

            if ($Diff -gt 0) {
                $HoursToLog = [double]$Diff
                $EntryDate = $Global:LoadedDates[$Day].AddHours(17).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

                # Dynamically set Outcome, Status, visibility flags, default Charge Rate, and available lookup options based on Ticket Type
                $CurrentTicketType = [int]$OriginalRow.TicketTypeID
                $IsServiceTicket = $false

                switch ($CurrentTicketType) {
                    20 {
                        # Project Ticket
                        $SubmitOutcomeId      = "132"
                        $SubmitStatus         = 61
                        $DefaultChargeRate    = $SelectedProjectChargeRate
                        $AvailableChargeCodes = $ChargeCodeCombo.ItemsSource
                    }
                    100 {
                        # Consulting Ticket
                        $SubmitOutcomeId      = "269"
                        $SubmitStatus         = 2
                        $DefaultChargeRate    = $SelectedConsultingChargeRate
                        $AvailableChargeCodes = $ConsultingChargeCodeCombo.ItemsSource
                    }
                    { $_ -eq 3 -or $_ -eq 114 } {
                        # Service Request (3) or Evergreen (114) Ticket - private note, preserve current status
                        $SubmitOutcomeId      = "108"
                        $SubmitStatus         = $null
                        $IsServiceTicket      = $true
                        $DefaultChargeRate    = $SelectedServiceChargeRate
                        $AvailableChargeCodes = $ServiceChargeCodeCombo.ItemsSource
                    }
                    default {
                        $SkipPrompt = "Ticket $($CurrentRow.TicketID) ($($CurrentRow.TicketType), Type ID $CurrentTicketType) on $Day is not a supported ticket type for time posting.`n`nClick YES to skip this entry and continue, or NO to cancel all remaining postings."
                        $SkipDialog = [System.Windows.MessageBox]::Show($SkipPrompt, "Unsupported Ticket Type", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
                        $ErrorCount++
                        if ($SkipDialog -eq [System.Windows.MessageBoxResult]::No) {
                            $UserCancelled = $true
                            break RowLoop
                        } else {
                            continue
                        }
                    }
                }

                # Determine base note: custom ticket note up front if specified, otherwise General Default Note
                $BaseNote = if (-not [string]::IsNullOrWhiteSpace($CurrentRow.TicketNote)) { $CurrentRow.TicketNote } else { $DefaultNote }
                $FinalNote = $BaseNote
                $FinalChargeRate = $DefaultChargeRate

                # TARGETED OVERRIDE LOGIC (Triggers ONLY if Override checkbox is checked for this entry/row)
                if ($CurrentRow.HasOverride) {
                    $PromptMsg = "OVERRIDE for Ticket $($CurrentRow.TicketID) ($($CurrentRow.TicketType)) on $Day ($Diff hrs):`nProject: $($CurrentRow.Project)`nSummary: $($CurrentRow.TicketSummary)"
                    
                    $OverrideResult = Show-OverrideInputBox -Title "Time Entry Override ($Day)" -PromptMessage $PromptMsg -DefaultNote $BaseNote -ChargeCodes $AvailableChargeCodes -SelectedChargeCode $DefaultChargeRate
                    
                    if ($null -ne $OverrideResult) {
                        $FinalNote = $OverrideResult.Note
                        if ($null -ne $OverrideResult.ChargeCode -and [string]$OverrideResult.ChargeCode -ne "") { $FinalChargeRate = [string]$OverrideResult.ChargeCode }
                    } else {
                        # User clicked Cancel on the override dialog for this entry
                        $CancelDialog = [System.Windows.MessageBox]::Show("You cancelled override for Ticket $($CurrentRow.TicketID) on $Day.`n`nDo you want to SKIP this entry and continue, or CANCEL all remaining postings?", "Override Cancelled", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
                        if ($CancelDialog -eq [System.Windows.MessageBoxResult]::No) {
                            $UserCancelled = $true
                            break RowLoop
                        } else {
                            continue
                        }
                    }
                }

                $ParsedRate = 0
                $ChargeRateValue = if ([int]::TryParse($FinalChargeRate, [ref]$ParsedRate)) { $ParsedRate } else { $FinalChargeRate }

                $ActionObj = @{
                    ticket_id     = $CurrentRow.TicketID
                    note          = $FinalNote
                    timetaken     = $HoursToLog
                    datetime      = $EntryDate
                    outcome_id    = $SubmitOutcomeId
                    chargerate    = $ChargeRateValue
                }

                if ($null -ne $SubmitStatus) {
                    $ActionObj["new_status"] = $SubmitStatus
                }
                if ($IsServiceTicket) {
                    $ActionObj["hiddenfromuser"] = $true
                    $ActionObj["sendemail"]      = $false
                    $ActionObj["new_slastatus"]  = -1
                }

                $ActionPayload = "[$($ActionObj | ConvertTo-Json -Compress)]"

                try {
                    $PostUri = "$HaloUrl/api/Actions"
                    Invoke-RestMethod -Uri $PostUri -Method Post -Headers $Headers -Body $ActionPayload
                    $PostCount++
                    
                    $OriginalRow.$Day = $CurrentVal
                    $HasTimeProp = "${Day}HasTime"
                    $CurrentRow.$HasTimeProp = $true 
                } catch {
                    $ErrorMessage = if ($_.ErrorDetails.Message) { $_.ErrorDetails.Message -join "`n" } else { $_.Exception.Message }
                    $IsUnauthorized = ($_.Exception.Response.StatusCode -eq 'Unauthorized' -or $_.Exception.Message -match "401")
                    
                    if ($IsUnauthorized) {
                        $TokenExpired = $true
                        $PromptTitle = "Token Expired"
                        $PromptBody = "Your Bearer Token has expired or is invalid.`n`nDo you want to CONTINUE attempting to post remaining entries, or CANCEL all remaining postings?"
                    } else {
                        $PromptTitle = "Posting Error"
                        $PromptBody = "Failed to post time for Ticket $($CurrentRow.TicketID) on $Day.`nError: $ErrorMessage`n`nDo you want to CONTINUE attempting to post remaining entries, or CANCEL all remaining postings?"
                    }

                    # Show MessageBox with Yes (Continue) / No (Cancel All) options
                    $DialogResult = [System.Windows.MessageBox]::Show($PromptBody, $PromptTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
                    
                    $ErrorCount++
                    if ($DialogResult -eq [System.Windows.MessageBoxResult]::No) {
                        $UserCancelled = $true
                        break RowLoop
                    }
                }
            }
            elseif ($Diff -lt 0) {
                # 1. Alert the user
                $WarnMsg = "Cannot reduce time for Ticket $($CurrentRow.TicketID) on $Day.`n`nPlease edit historical time directly in HaloPSA. This cell will now be reset to its original value of $OriginalVal."
                [System.Windows.MessageBox]::Show($WarnMsg, "Invalid Entry", 0, 48) # 0 = OK button, 48 = Warning Icon
                
                # 2. Reset the grid cell visually
                $CurrentRow.$Day = $OriginalVal
                
                # 3. Increment error count so the status bar reflects the failure
                $ErrorCount++
            }
        }
    }

    &$UpdateTotals 
    
    if ($UserCancelled) {
        $StatusText.Text = "Submission cancelled by user. ($PostCount entries successfully posted)."
        $StatusText.Foreground = "Red"
    } elseif ($TokenExpired) {
        $StatusText.Text = "Submission halted. Token Expired. ($PostCount entries were successfully saved)."
        $StatusText.Foreground = "Red"
    } elseif ($ErrorCount -eq 0) {
        $StatusText.Text = "Success! Created $PostCount new time entries."
        $StatusText.Foreground = "Green"
    } else {
        $StatusText.Text = "Finished with $ErrorCount errors. Check popups."
        $StatusText.Foreground = "Red"
    }
})

# 6. Launch the App
$Window.ShowDialog() | Out-Null