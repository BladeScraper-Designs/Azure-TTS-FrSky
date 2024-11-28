Add-Type -AssemblyName PresentationFramework

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="WPF Example" Height="200" Width="300">
    <StackPanel>
        <Label Content="Hello, WPF!" />
        <Button Name="MyButton" Content="Click Me" />
    </StackPanel>
</Window>
"@

# Load XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Get the button by its name
$button = $window.FindName("MyButton")

# Add event handler for the button click
$button.Add_Click({
    [System.Windows.MessageBox]::Show("Button clicked!")
})

# Show the window
$window.ShowDialog()