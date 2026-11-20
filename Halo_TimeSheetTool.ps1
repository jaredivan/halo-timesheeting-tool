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
                <DataGridTextColumn Header="ID" Binding="{Binding TicketID}" IsReadOnly="True" Width="50">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Type" Binding="{Binding TicketType}" IsReadOnly="True" Width="105">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Client Name" Binding="{Binding ClientName}" IsReadOnly="True" Width="*" MinWidth="100">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Project" Binding="{Binding Project}" IsReadOnly="True" Width="*" MinWidth="150">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Ticket Summary" Binding="{Binding TicketSummary}" IsReadOnly="True" Width="*" MinWidth="150">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridCheckBoxColumn Header="Override" Binding="{Binding HasOverride}" Width="55">
                    <DataGridCheckBoxColumn.ElementStyle><Style TargetType="CheckBox"><Setter Property="HorizontalAlignment" Value="Center"/><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="ToolTip" Value="Check this to get a popup at submit time letting you set a custom charge code, note, and entry time just for this ticket."/></Style></DataGridCheckBoxColumn.ElementStyle>
                </DataGridCheckBoxColumn>
                <DataGridTextColumn Header="Ticket Note" Binding="{Binding TicketNote}" Width="*" MinWidth="90">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextTrimming" Value="CharacterEllipsis"/><Setter Property="ToolTip" Value="{Binding RelativeSource={RelativeSource Self}, Path=Text}"/><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTemplateColumn Header="Charge Code" Width="150">
                    <DataGridTemplateColumn.CellTemplate>
                        <DataTemplate>
                            <ComboBox ItemsSource="{Binding ChargeCodeOptions}" DisplayMemberPath="Name" SelectedValuePath="ID" SelectedValue="{Binding SelectedChargeCode, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Margin="2"/>
                        </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                </DataGridTemplateColumn>

                <DataGridTextColumn Header="Mon" Binding="{Binding Mon}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding MonHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Tue" Binding="{Binding Tue}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding TueHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Wed" Binding="{Binding Wed}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding WedHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Thu" Binding="{Binding Thu}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding ThuHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Fri" Binding="{Binding Fri}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding FriHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sat" Binding="{Binding Sat}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SatHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sun" Binding="{Binding Sun}" Width="45">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SunHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>

                <DataGridTextColumn Header="Row Total" Binding="{Binding Total}" IsReadOnly="True" Width="60" FontWeight="Bold">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="VerticalAlignment" Value="Center"/></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
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

        <StackPanel Grid.Row="4" Orientation="Horizontal" Margin="0,5,0,0">
            <Label Content="Default Note:" VerticalAlignment="Center" FontWeight="Bold"/>
            <TextBox Name="NoteBox" Width="220" Margin="5,0,15,0" VerticalAlignment="Center" Text=""/>

            <Label Content="Charge Code:" VerticalAlignment="Center" FontWeight="Bold"/>
            <ComboBox Name="BulkChargeCodeCombo" Width="160" Margin="5,0,10,0" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            <Button Name="ApplyBulkChargeCodeBtn" Content="Apply to All Rows" Width="130" Padding="5" Background="#6C757D" Foreground="White" FontWeight="Bold"/>
        </StackPanel>

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
$BulkChargeCodeCombo    = $Window.FindName("BulkChargeCodeCombo")
$ApplyBulkChargeCodeBtn = $Window.FindName("ApplyBulkChargeCodeBtn")

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
        [string]$SelectedChargeCode = "",
        [int]$DefaultHour = 17,
        [int]$DefaultMinute = 0
    )

    [xml]$InputXAML = @"
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Height="415" Width="480" WindowStartupLocation="CenterScreen"
            ResizeMode="NoResize">
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock Name="PromptTextBlock" Grid.Row="0" Margin="0,0,0,12" TextWrapping="Wrap" FontWeight="Bold"/>

            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,12">
                <Label Content="Entry Time:" VerticalAlignment="Center" FontWeight="Bold" Width="100"/>
                <ComboBox Name="HourCombo" Width="70" VerticalAlignment="Center"/>
                <TextBlock Text=":" VerticalAlignment="Center" FontWeight="Bold" Margin="6,0,6,0"/>
                <ComboBox Name="MinuteCombo" Width="70" VerticalAlignment="Center"/>
                <TextBlock Text="(24h)" VerticalAlignment="Center" Foreground="Gray" Margin="10,0,0,0"/>
            </StackPanel>

            <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,0,0,12">
                <Label Content="Charge Code:" VerticalAlignment="Center" FontWeight="Bold" Width="100"/>
                <ComboBox Name="PopupChargeCodeCombo" Width="330" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>
            </StackPanel>

            <DockPanel Grid.Row="3" Margin="0,0,0,10">
                <Label Content="Custom Note:" DockPanel.Dock="Top" FontWeight="Bold" Margin="0,0,0,4"/>
                <TextBox Name="InputTextBox" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
            </DockPanel>

            <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
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

    $HourCombo = $InputWindow.FindName("HourCombo")
    $HourCombo.ItemsSource = 0..23 | ForEach-Object { "{0:D2}" -f $_ }
    $HourCombo.SelectedItem = "{0:D2}" -f $DefaultHour

    $MinuteCombo = $InputWindow.FindName("MinuteCombo")
    $MinuteCombo.ItemsSource = @(0, 15, 30, 45) | ForEach-Object { "{0:D2}" -f $_ }
    $MinuteCombo.SelectedItem = "{0:D2}" -f $DefaultMinute
    if (-not $MinuteCombo.SelectedItem) { $MinuteCombo.SelectedIndex = 0 }

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
            Hour       = [int]$HourCombo.SelectedItem
            Minute     = [int]$MinuteCombo.SelectedItem
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
                                - <Run FontWeight="Bold">Show All Tickets:</Run> By default, the tool shows Project (Type 20), Consulting (Type 100), Service Request (Type 3), &amp; Evergreen (Type 114) tickets. Check this to load all assigned open tickets.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 3: Charge Codes & Notes -->
                    <Border Background="#F8F9FA" BorderBrush="#DEE2E6" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[3] Charge Codes &amp; Notes Management" FontSize="14" FontWeight="Bold" Foreground="#333"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#444" FontSize="12">
                                - <Run FontWeight="Bold">Per-Ticket Charge Code:</Run> Each ticket row has its own Charge Code dropdown, populated from the full HaloPSA charge code list (or bulk-set all rows via the bottom 'Charge Code' + 'Apply to All Rows' controls). It defaults to your own agent charge rate where available, otherwise the first available code.
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
                                - <Run FontWeight="Bold">Triple Customization:</Run> Checking the <Run FontWeight="Bold">Override</Run> box on a ticket row triggers a popup during submit allowing you to specify a <Run FontWeight="Bold">Custom Charge Code</Run>, a <Run FontWeight="Bold">Custom Note</Run>, and a <Run FontWeight="Bold">Custom Entry Time</Run> (hour/minute, 24h format) specifically for that entry. Entries default to 5:00 PM when not overridden.
                                <LineBreak/><LineBreak/>
                                - <Run FontWeight="Bold">Ticket-Specific Charge Code List:</Run> The Charge Code dropdown in this popup is looked up specifically for that ticket's client, contract, and resolved outcome, so it may differ from the row's default list. If that lookup fails or returns nothing, it falls back to the row's normal Charge Code list.
                            </TextBlock>
                        </StackPanel>
                    </Border>

                    <!-- Section 5: Limitations -->
                    <Border Background="#F8D7DA" BorderBrush="#F5C6CB" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="[5] Tool Limitations" FontSize="14" FontWeight="Bold" Foreground="#721C24"/>
                            <TextBlock TextWrapping="Wrap" Margin="0,6,0,0" Foreground="#721C24" FontSize="12">
                                - <Run FontWeight="Bold">Workflow Action Requirement:</Run> Tickets require a matching 'Note' or 'Add Time' action on their current workflow step (Service Request &amp; Evergreen tickets keep their current status and post privately).
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

    # FETCH CHARGE CODES (Lookup ID 17) - shared across all rows, selected per-ticket in the grid
    $ChargeCodeOptions = @()
    $DefaultChargeCodeID = $null
    try {
        $LookupUri = "$HaloUrl/api/lookup?lookupid=17"
        $LookupResp = Invoke-RestMethod -Uri $LookupUri -Method Get -Headers $Headers

        foreach ($Item in ($LookupResp | Where-Object { -not $_.inactive })) {
            # Store ID as string so "0" ("No Charge") matches reliably across WPF ComboBoxes
            $ChargeCodeOptions += [PSCustomObject]@{
                ID = [string]$Item.id
                Name = $Item.name
            }
        }

        if ($ChargeCodeOptions.Count -gt 0) {
            $DefaultChargeCodeID = if (-not [string]::IsNullOrEmpty($AgentChargeRateStr) -and ($ChargeCodeOptions.ID -contains $AgentChargeRateStr)) {
                $AgentChargeRateStr
            } else {
                $ChargeCodeOptions[0].ID
            }
        }
    } catch {
        Write-Warning "Failed to load charge codes. $_"
    }

    $BulkChargeCodeCombo.ItemsSource = $ChargeCodeOptions
    if ($null -ne $DefaultChargeCodeID -and [string]$DefaultChargeCodeID -ne "") {
        $BulkChargeCodeCombo.SelectedValue = $DefaultChargeCodeID
    } elseif ($ChargeCodeOptions.Count -gt 0) {
        $BulkChargeCodeCombo.SelectedIndex = 0
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
                        $Ticket.tickettype_name
                    } else {
                        "Type $TypeId"
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
                WorkflowID    = $Ticket.workflow_id
                WorkflowStep  = $Ticket.workflow_step
                ClientID      = $Ticket.client_id
                ContractID    = if ($null -ne $Ticket.contract_id) { $Ticket.contract_id } else { -1 }
                ClientName    = if ($Ticket.client_name) { $Ticket.client_name } else { "Unassigned" }
                Project       = if ($Ticket.parent_subject) { $Ticket.parent_subject -replace " - Parent Project", '' } else { "None" }
                TicketSummary = $FormattedSummary
                HasOverride   = $false
                TicketNote    = ""
                ChargeCodeOptions  = $ChargeCodeOptions
                SelectedChargeCode = $DefaultChargeCodeID
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

# 4b. Bulk-Apply Charge Code Button Event
$ApplyBulkChargeCodeBtn.Add_Click({
    if ($null -eq $TimesheetGrid.ItemsSource -or $null -eq $BulkChargeCodeCombo.SelectedValue -or [string]$BulkChargeCodeCombo.SelectedValue -eq "") { return }

    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null

    foreach ($Row in $TimesheetGrid.ItemsSource) {
        $Row.SelectedChargeCode = [string]$BulkChargeCodeCombo.SelectedValue
    }

    try { $TimesheetGrid.Items.Refresh() } catch { }
})

# 5. Submit Button Event
$SubmitBtn.Add_Click({
    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true) | Out-Null
    $TimesheetGrid.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Row, $true) | Out-Null

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
    $WorkflowCache = @{}
    $StatusCache = @{}

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
                $EntryHour = 17
                $EntryMinute = 0

                # Charge Rate comes from this row's Charge Code selector (preserving "0" No Charge)
                # Outcome ID is resolved dynamically from workflow (with fallback 108 for Service Request / Evergreen)
                $CurrentTicketType    = [int]$OriginalRow.TicketTypeID
                $IsServiceTicket      = ($CurrentTicketType -eq 3 -or $CurrentTicketType -eq 114)
                $DefaultChargeRate    = if ($null -ne $CurrentRow.SelectedChargeCode -and [string]$CurrentRow.SelectedChargeCode -ne "") { [string]$CurrentRow.SelectedChargeCode } else { "30" }
                $AvailableChargeCodes = $CurrentRow.ChargeCodeOptions

                # Determine base note: custom ticket note up front if specified, otherwise General Default Note
                $BaseNote = if (-not [string]::IsNullOrWhiteSpace($CurrentRow.TicketNote)) { $CurrentRow.TicketNote } else { $DefaultNote }
                $FinalNote = $BaseNote
                $FinalChargeRate = $DefaultChargeRate

                try {
                    # Dynamically resolve the Outcome ID from the ticket's current workflow step (cached per submit run)
                    $MatchedAction = $null
                    $WorkflowIdInt = 0
                    if ([int]::TryParse([string]$OriginalRow.WorkflowID, [ref]$WorkflowIdInt) -and $WorkflowIdInt -gt 0) {
                        if ($WorkflowCache.ContainsKey($WorkflowIdInt)) {
                            $WorkflowResp = $WorkflowCache[$WorkflowIdInt]
                        } else {
                            $WorkflowUri = "$HaloUrl/api/workflow/$WorkflowIdInt"
                            $WorkflowResp = Invoke-RestMethod -Uri $WorkflowUri -Method Get -Headers $Headers
                            $WorkflowCache[$WorkflowIdInt] = $WorkflowResp
                        }

                        if ($null -ne $WorkflowResp -and $null -ne $WorkflowResp.steps) {
                            $MatchedStep = $WorkflowResp.steps | Where-Object { $_.step_id -eq $OriginalRow.WorkflowStep }
                            if ($null -ne $MatchedStep) {
                                if ($IsServiceTicket) {
                                    $MatchedAction = $MatchedStep.actions | Where-Object { [string]$_.action_id -eq "108" } | Select-Object -First 1
                                }
                                if (-not $MatchedAction) {
                                    $MatchedAction = $MatchedStep.actions | Where-Object { $_.action_name -match '(Project|Private|Internal) Note|Add Time' } | Select-Object -First 1
                                }
                            }
                        }
                    }

                    if ($MatchedAction) {
                        $SubmitOutcomeId = [string]$MatchedAction.action_id
                    } elseif ($IsServiceTicket) {
                        $SubmitOutcomeId = "108"
                    } else {
                        throw "No 'Note' or 'Add Time' action is available on the current workflow step for Ticket $($CurrentRow.TicketID)."
                    }

                    # LIC actions post with no status change and a fixed charge rate
                    $IsLicAction = ($null -ne $MatchedAction -and $MatchedAction.action_name -match '^LIC')

                    # TARGETED OVERRIDE LOGIC (Triggers ONLY if Override checkbox is checked for this entry/row)
                    if ($CurrentRow.HasOverride) {
                        $PromptMsg = "OVERRIDE for Ticket $($CurrentRow.TicketID) ($($CurrentRow.TicketType)) on $Day ($Diff hrs):`nProject: $($CurrentRow.Project)`nSummary: $($CurrentRow.TicketSummary)"

                        # Resolve a charge-code list specific to this ticket's client/contract/outcome for the override picker
                        $OverrideChargeCodes = $AvailableChargeCodes
                        try {
                            $OverrideLookupUri = "$HaloUrl/api/lookup?lookupid=17&use=0&client_id=$($OriginalRow.ClientID)&contract_id=$($OriginalRow.ContractID)&outcome_id=$SubmitOutcomeId&tickettype_id=$CurrentTicketType"
                            $OverrideLookupResp = Invoke-RestMethod -Uri $OverrideLookupUri -Method Get -Headers $Headers
                            $OverrideLookupData = @()
                            foreach ($Item in ($OverrideLookupResp | Where-Object { -not $_.inactive })) {
                                $OverrideLookupData += [PSCustomObject]@{ ID = [string]$Item.id; Name = $Item.name }
                            }
                            if ($OverrideLookupData.Count -gt 0) { $OverrideChargeCodes = $OverrideLookupData }
                        } catch { }

                        $OverrideResult = Show-OverrideInputBox -Title "Time Entry Override ($Day)" -PromptMessage $PromptMsg -DefaultNote $BaseNote -ChargeCodes $OverrideChargeCodes -SelectedChargeCode $DefaultChargeRate -DefaultHour $EntryHour -DefaultMinute $EntryMinute

                        if ($null -ne $OverrideResult) {
                            $FinalNote = $OverrideResult.Note
                            if ($null -ne $OverrideResult.ChargeCode -and [string]$OverrideResult.ChargeCode -ne "") { $FinalChargeRate = [string]$OverrideResult.ChargeCode }
                            $EntryHour = $OverrideResult.Hour
                            $EntryMinute = $OverrideResult.Minute
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

                    $EntryDate = $Global:LoadedDates[$Day].AddHours($EntryHour).AddMinutes($EntryMinute).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

                    if ($IsLicAction) {
                        $SubmitStatus = $null
                        $FinalChargeRate = "0"
                    } elseif ($IsServiceTicket) {
                        # Service Request (3) & Evergreen (114) omit new_status so existing ticket status stays unchanged
                        $SubmitStatus = $null
                    } else {
                        # Dynamically resolve the Status that pairs with that Outcome on this workflow step (cached per submit run)
                        $StatusCacheKey = "$CurrentTicketType|$SubmitOutcomeId|$WorkflowIdInt|$($OriginalRow.WorkflowStep)"
                        if ($StatusCache.ContainsKey($StatusCacheKey)) {
                            $StatusResp = $StatusCache[$StatusCacheKey]
                        } else {
                            $StatusUri = "$HaloUrl/api/Status?type=ticket&excludepending=true&excludeclosed=true&tickettype_id=$CurrentTicketType&outcome_id=$SubmitOutcomeId&workflow_id=$($OriginalRow.WorkflowID)&workflow_step=$($OriginalRow.WorkflowStep)"
                            $StatusResp = Invoke-RestMethod -Uri $StatusUri -Method Get -Headers $Headers
                            $StatusCache[$StatusCacheKey] = $StatusResp
                        }
                        $SubmitStatus = ($StatusResp | Where-Object { $_.name -match 'Open|In Progress' } | Select-Object -First 1).id

                        if (-not $SubmitStatus) {
                            throw "No valid ticket Status was returned for Ticket $($CurrentRow.TicketID) with Outcome $SubmitOutcomeId."
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