Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

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
        </StackPanel>

        <TextBlock Name="StatusText" Grid.Row="1" Text="Ready to load..." Foreground="Gray" Margin="0,0,0,10" FontWeight="Bold"/>

        <DataGrid Name="TimesheetGrid" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" AlternatingRowBackground="#F0F0F0" HeadersVisibility="Column" HorizontalScrollBarVisibility="Auto">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding TicketID}" IsReadOnly="True" Width="Auto"/>
                <DataGridTextColumn Header="Client Name" Binding="{Binding ClientName}" IsReadOnly="True" Width="Auto"/>
                <DataGridTextColumn Header="Project" Binding="{Binding Project}" IsReadOnly="True" Width="Auto"/>
                <DataGridTextColumn Header="Ticket Summary" Binding="{Binding TicketSummary}" IsReadOnly="True" Width="Auto"/>
                
                <DataGridTextColumn Header="Mon" Binding="{Binding Mon}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding MonHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Tue" Binding="{Binding Tue}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding TueHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Wed" Binding="{Binding Wed}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding WedHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Thu" Binding="{Binding Thu}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding ThuHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Fri" Binding="{Binding Fri}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding FriHasTime}" Value="True"><Setter Property="Background" Value="#D4EDDA"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sat" Binding="{Binding Sat}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SatHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Sun" Binding="{Binding Sun}" Width="60">
                    <DataGridTextColumn.CellStyle><Style TargetType="DataGridCell"><Style.Triggers><DataTrigger Binding="{Binding SunHasTime}" Value="True"><Setter Property="Background" Value="#E2E3E5"/></DataTrigger></Style.Triggers></Style></DataGridTextColumn.CellStyle>
                </DataGridTextColumn>
                
                <DataGridTextColumn Header="Row Total" Binding="{Binding Total}" IsReadOnly="True" Width="70" FontWeight="Bold"/>
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
            <Label Content="Charge Code:" VerticalAlignment="Center" FontWeight="Bold"/>
            <ComboBox Name="ChargeCodeCombo" Width="200" Margin="5,0,25,0" VerticalAlignment="Center" DisplayMemberPath="Name" SelectedValuePath="ID"/>

            <Label Content="Default Note:" VerticalAlignment="Center" FontWeight="Bold"/>
            <TextBox Name="NoteBox" Width="250" Margin="5,0,15,0" VerticalAlignment="Center" Text=""/>
            
            <CheckBox Name="PromptNotesChk" Content="Prompt for custom note per entry on submit" VerticalAlignment="Center" FontWeight="Bold"/>
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
$SubmitBtn          = $Window.FindName("SubmitBtn")
$TimesheetGrid      = $Window.FindName("TimesheetGrid")
$StatusText         = $Window.FindName("StatusText")
$NoteBox            = $Window.FindName("NoteBox")
$PromptNotesChk     = $Window.FindName("PromptNotesChk")
$ChargeCodeCombo    = $Window.FindName("ChargeCodeCombo")

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
    $TotMon.Text = $TMon; $TotTue.Text = $TTue; $TotWed.Text = $TWed
    $TotThu.Text = $TThu; $TotFri.Text = $TFri; $TotSat.Text = $TSat; $TotSun.Text = $TSun
    $TotWeek.Text = $TMon + $TTue + $TWed + $TThu + $TFri + $TSat + $TSun
    # Try to refresh the row totals visually, but fail silently if the user is already tabbing into the next cell
    try {
        $TimesheetGrid.Items.Refresh()
    } catch { }
}

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
    } catch {
        $StatusText.Text = "Failed to retrieve agent details. $_"
        $StatusText.Foreground = "Red"
        return
    }

    # FETCH CHARGE CODES (Lookup ID 17)
    try {
        $LookupUri = "$HaloUrl/api/lookup?lookupid=17&outcome_id=132&tickettype_id=20"
        $LookupResp = Invoke-RestMethod -Uri $LookupUri -Method Get -Headers $Headers
        
        $ComboData = @()
        foreach ($Item in $LookupResp) {
            # Halo Lookups usually return id and name. We map them cleanly for the ComboBox.
            $ComboData += [PSCustomObject]@{
                ID = $Item.id
                Name = $Item.name
            }
        }
        $ChargeCodeCombo.ItemsSource = $ComboData
        
        # Select the first item by default if it loaded correctly
        if ($ComboData.Count -gt 0) {
             if ($ComboData.ID -contains $AgentChargeRate) {
                $ChargeCodeCombo.SelectedValue = $AgentChargeRate
            }
            else {
                $ChargeCodeCombo.SelectedIndex = 0
            }
        }
    } catch {
        Write-Warning "Failed to load charge codes. $_"
    }

    $SelectedDate = $WeekPicker.SelectedDate
    $Offset = if ($SelectedDate.DayOfWeek -eq 'Sunday') { 6 } else { [int]$SelectedDate.DayOfWeek - 1 }
    $Monday = $SelectedDate.AddDays(-$Offset).Date
    $Sunday = $Monday.AddDays(6).AddHours(23).AddMinutes(59)
    
    $Global:LoadedDates = @{
        "Mon" = $Monday; "Tue" = $Monday.AddDays(1); "Wed" = $Monday.AddDays(2);
        "Thu" = $Monday.AddDays(3); "Fri" = $Monday.AddDays(4); "Sat" = $Monday.AddDays(5); "Sun" = $Monday.AddDays(6)
    }

    try {
        $Uri = "$HaloUrl/api/Tickets?pageinate=false&agent_id=$AgentID&open_only=true&columns_id=104"
        $Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers
        
        if ($FetchAllTicketsChk.IsChecked) {
            $Tickets = $Response.tickets
        } else {
            # Filter to just Project Tickets (20) and Consulting Tickets (100)
            $Tickets = $Response.tickets | Where-Object { $_.tickettype_id -eq 20 -or $_.tickettype_id -eq 100 }
        }

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

        foreach ($Ticket in $Tickets) {
            # Start hours at 0
            $MonHrs = 0; $TueHrs = 0; $WedHrs = 0; $ThuHrs = 0; $FriHrs = 0; $SatHrs = 0; $SunHrs = 0


            # FETCH EXISTING TIME LOGIC
            if ($FetchExistingChk.IsChecked) {
                $StatusText.Text = "Fetching existing time... ($CurrentTicketNum / $($Tickets.Count))"
                [System.Windows.Forms.Application]::DoEvents()

                try {
                    $ActionsUri = "$HaloUrl/api/Actions?ticket_id=$($Ticket.id)&agentonly=true"
                    $ActionsResp = Invoke-RestMethod -Uri $ActionsUri -Method Get -Headers $Headers
                    $ActionsList = $ActionsResp.actions | Where-Object {$_.who_agentid -eq $AgentID}

                    foreach ($Act in $ActionsList) {
                        $ActDate = ([datetime]$Act.datetime).ToLocalTime()
                        if ($ActDate -ge $Monday -and $ActDate -le $Sunday -and $Act.timetaken -gt 0) {
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
                } catch { }
            }
            $CurrentTicketNum++

            # Map the new properties directly from the ticket object
            $RowObj = [PSCustomObject]@{
                TicketID      = $Ticket.id
                ClientName    = if ($Ticket.client_name) { $Ticket.client_name } else { "Unassigned" }
                Project       = if ($Ticket.parent_subject) { $Ticket.parent_subject -replace " - Parent Project", '' } else { "None" }
                TicketSummary = if ($Ticket.summary -match "-\s+(\D.*)$") { $Matches[1].Trim() } else { $Ticket.summary }
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
        
        $StatusText.Text = "Loaded $($Tickets.Count) tickets for the week of $($Monday.ToString('yyyy-MM-dd'))."
        $StatusText.Foreground = "Green"

    } catch {
        $StatusText.Text = "API Error: $_"
        $StatusText.Foreground = "Red"
    }
})

# 5. Submit Button Event
$SubmitBtn.Add_Click({
    $TimesheetGrid.CommitEdit() | Out-Null
    
    # Grab the selected Charge Rate ID from the dropdown, default to 30 if nothing is selected/loaded
    $SelectedChargeRate = if ($ChargeCodeCombo.SelectedValue) { [string]$ChargeCodeCombo.SelectedValue } else { "30" }

    $StatusText.Text = "Calculating and posting time entries..."
    $StatusText.Foreground = "Blue"
    [System.Windows.Forms.Application]::DoEvents()

    $Headers = @{
        "Authorization" = "Bearer $($TokenBox.Password)"
        "Content-Type"  = "application/json"
    }

    # Grab the custom note, fallback if empty
    $DefaultNote = $NoteBox.Text

    $CurrentData = $TimesheetGrid.ItemsSource
    $PostCount = 0
    $ErrorCount = 0

    foreach ($CurrentRow in $CurrentData) {
        $OriginalRow = $Global:OriginalData | Where-Object { $_.TicketID -eq $CurrentRow.TicketID }
        
        $Days = @("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
        foreach ($Day in $Days) {
            $CurrentVal = 0
            if (-not [double]::TryParse($CurrentRow.$Day, [ref]$CurrentVal)) {
                $StatusText.Text = "Warning: Invalid number detected in Ticket $($CurrentRow.TicketID) on $Day. Skipped."
                $StatusText.Foreground = "DarkOrange"
                continue 
            }
            
            $OriginalVal = [double]($OriginalRow.$Day)
            $Diff = $CurrentVal - $OriginalVal

            if ($Diff -gt 0) {
                $HoursToLog = $Diff
                $EntryDate = $Global:LoadedDates[$Day].AddHours(17).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss")

                # CUSTOM NOTE PROMPT LOGIC
                 $FinalNote = $DefaultNote
                 if ($PromptNotesChk.IsChecked) {
                     $PromptMsg = "Adding $Diff hours on $Day to:`n'$($CurrentRow.Project)'.`n`nEnter your specific note for this entry:"
                     $UserInput = [Microsoft.VisualBasic.Interaction]::InputBox($PromptMsg, "Custom Time Entry Note", $DefaultNote)
                     if (-not [string]::IsNullOrWhiteSpace($UserInput)) {
                         $FinalNote = $UserInput
                     }
                 }

                $ActionObj = @{
                    ticket_id     = $CurrentRow.TicketID
                    note          = $FinalNote
                    timetaken     = $HoursToLog
                    datetime      = $EntryDate
                    outcome_id    = "132"
                    new_status    = "61"
                    chargerate    = $SelectedChargeRate
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
                    $ErrorMessage = $_.ErrorDetails.Message -join "`n"
                    [System.Windows.MessageBox]::Show("Failed to post time for Ticket $($CurrentRow.TicketID) on $Day.`n$ErrorMessage", "Error")
                    $ErrorCount++
                }
            }
        }
    }

    &$UpdateTotals 
    
    if ($ErrorCount -eq 0) {
        $StatusText.Text = "Success! Created $PostCount new time entries."
        $StatusText.Foreground = "Green"
    } else {
        $StatusText.Text = "Finished with $ErrorCount errors. Check popups."
        $StatusText.Foreground = "Red"
    }
})

# 6. Launch the App
$Window.ShowDialog() | Out-Null