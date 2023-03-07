Add-Type -AssemblyName System.Drawing

<#
    .SYNOPSIS
    Convert image to ascii.
    .DESCRIPTION
    Convert any image to ascii picture by representing each pixels grayscale value as an ascii character.
    .PARAMETER Path
    The path to the image to process.
    .PARAMETER Resolution
    The amount of different ascii characters the grayscale values will be assigned to.
    .PARAMETER Width
    Set the width of the output ascii picture manually.
    .PARAMETER Height
    Set the height of the output ascii picture manually.
    .PARAMETER FitConsoleHeight
    Whether the output ascii picture should fit the console height instead of width. Only applicable if
    width and height are not explicitly specified.
    .PARAMETER Invert
    Whether the output ascii picture should be inverted. Use this on light console backgrounds
    for better results.
    .INPUTS
    System.IO.FileInfo
    System.String
    System.Int32
    .OUTPUTS
    System.String
    .COMPONENT
    GDI+
#>

function Convert-ImageToAscii
{
    [Alias('i2a')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [ValidateScript({ $PSItem | Test-Path -PathType Leaf })]
        [ValidateScript({ $PSItem.Extension -in '.bmp', '.gif', '.jpeg', '.jpg', '.png', '.tiff' })]
        [System.IO.FileInfo]
        $Path,

        [ValidateSet('Low', 'Mid', 'High')]
        [string]
        $Resolution='Low',

        [Parameter(Mandatory, ParameterSetName="SetDimensionsManually")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Width,

        [Parameter(Mandatory, ParameterSetName="SetDimensionsManually")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Height,

        [Parameter(ParameterSetName="SetDimensionsAutomatically")]
        [switch]
        $FitConsoleHeight,

        [switch]
        $Invert
    )

    begin {
        $symbols = $(if ($Invert.IsPresent) {
        @{
            Low  = '@#+. '
            Mid  = "@%#*+:,. "
             High = '@%#omCXxt?+~;:,. '
        }
     }
    else {
        @{
            Low  = ' .+#@'
            Mid  = ' .,:+*#%@'
            High = ' .,:;~+?txXCmo#%@'
        }
    })[$Resolution]
    }

    process { 
        try {
            $img = [Drawing.Image]::FromFile($(Resolve-Path -Path $Path))

            [int]$w, [int]$h = switch ($PSCmdlet.ParemeterSetName) {
                SetDimensionsManually {
                    ($Width / 2), $Height
                }

                SetDimensionsAutomatically {
                    @(($Host.UI.RawUI.WindowSize.Height * ($img.Width / $img.Height))
                        ($Host.UI.RawUI.WindowSize.Height - 4))
                }

                default {
                    @(($Host.UI.RawUI.WindowSize.Width / 2 - 1)
                    ($Host.UI.RawUI.WindowSize.Width / 2 / ($img.Width / $img.Height)))
                }

            }

            $bmp = [Drawing.Bitmap]::New($w, $h)
            $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)

            $rec = [Drawing.Rectangle]::New(0, 0, $w, $h)
            $wrapMode = [Drawing.Imaging.ImageAttributes]::New()
            $wrapMode.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)

            $graphics                   = [Drawing.Graphics]::FromImage($bmp)
            $graphics.CompositingMode   = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($img, $rec, 0, 0, $img.Width, $img.Height, [Drawing.GraphicsUnit]::Pixel, $wrapMode)

            $ascii = [System.Text.StringBuilder]::New()

            foreach ($y in 0..($bmp.Height-1))
            {
                foreach ($x in 0..($bmp.Width-1))
                {
                    $p = $bmp.GetPixel($x, $y)
                    $symbol = "$($symbols[[Math]::Floor((($p.R+$p.G+$p.B)/3)/(256/$symbols.Length))])" * 2
                    [void]$ascii.Append($symbol)
                }
                [void]$ascii.Append("`n")
            }

            $ascii.ToString()

        } finally {
            $wrapMode.Dispose()
            $graphics.Dispose()
            $bmp.Dispose()
            $img.Dispose()
        }
    }
}

function Convert-ImagesToAscii
{
    [Alias('is2a')]
    [OutputType([string])]
    [CmdletBinding()]

    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        $Path,

        [ValidateSet('Low', 'Mid', 'High')]
        [string]
        $Resolution='Low',

        [Parameter(Mandatory, ParameterSetName="SetDimensionsManually")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Width,

        [Parameter(Mandatory, ParameterSetName="SetDimensionsManually")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Height,

        [Parameter(ParameterSetName="SetDimensionsAutomatically")]
        [switch]
        $FitConsoleHeight,

        [switch]
        $Invert
    )

    #$Images = (Get-ChildItem ($(Resolve-Path -Path $Path)) | Measure-Object).Count
    #Write-Host ($Images)
    cd ($(Resolve-Path -Path $Path))

    foreach($file in Get-ChildItem ($(Resolve-Path -Path $Path)))
    {
		Start-Sleep -Milliseconds 8
		if ($FitConsoleHeight.IsPresent)
		{
			if ($Invert.IsPresent) 
			{ 
			GCI $file | Convert-ImageToAscii -FitConsoleHeight -Resolution $Resolution -Invert
			} 
			else 
			{
				GCI $file | Convert-ImageToAscii -FitConsoleHeight -Resolution $Resolution 
			}
		}
		else 
		{ 
			if ($Invert.IsPresent) 
			{
				GCI $file | Convert-ImageToAsciii -Width $Width -Height $Height -Resolution $Resolution
			}
			else 
			{
				GCI $file | Convert-ImageToAscii -Width $Width -Height $Height -Resolution $Resolution
			}
		}
	}
}
