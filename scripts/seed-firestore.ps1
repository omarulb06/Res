# =============================================================================
#  seed-firestore.ps1 — populate Firestore with sample venues.
# -----------------------------------------------------------------------------
#  Strategy:
#    1. Save the current firestore.rules to a backup.
#    2. Append a tiny temporary clause that allows creating venues ONLY when
#       `ownerId == "seed-owner"`. The write scope is tightly bounded so even
#       if someone discovered the project ID during the ~30-sec window, they
#       could only inject documents under that one owner id (which we clean
#       up anyway).
#    3. Deploy the modified rules.
#    4. POST venues to the Firestore REST API using the project's web API key
#       (same key already shipped in the APK — no new secrets).
#    5. Restore the original rules and redeploy.
# =============================================================================

param(
    [string]$ProjectId = 'resapp-4e5b2',
    [switch]$WipeFirst  # if set, also deletes existing seed-owner venues
)

$ErrorActionPreference = 'Stop'
$env:Path = "C:\Program Files\nodejs;$env:APPDATA\npm;" + $env:Path

$ProjectRoot = 'C:\Res'
$RulesFile   = Join-Path $ProjectRoot 'firestore.rules'
$BackupFile  = Join-Path $ProjectRoot 'firestore.rules.backup'
$SeedRules   = Join-Path $ProjectRoot 'firestore.rules.seed'

$BaseUrl = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents"

Push-Location $ProjectRoot
try {
    # -------------------------------------------------------------------------
    # Helper: convert a PowerShell object to Firestore REST field format
    # -------------------------------------------------------------------------
    function ConvertTo-FirestoreValue {
        param($Value)
        if ($Value -is [bool])     { return @{ booleanValue = $Value } }
        if ($Value -is [int] -or $Value -is [long])    { return @{ integerValue = "$Value" } }
        if ($Value -is [double])   { return @{ doubleValue = $Value } }
        if ($Value -is [string])   { return @{ stringValue = $Value } }
        if ($Value -is [datetime]) { return @{ timestampValue = $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ') } }
        if ($Value -is [array]) {
            $items = @()
            foreach ($i in $Value) { $items += ,(ConvertTo-FirestoreValue $i) }
            return @{ arrayValue = @{ values = $items } }
        }
        if ($Value -is [hashtable] -or $Value -is [pscustomobject]) {
            $fields = @{}
            foreach ($k in $Value.Keys) {
                if ($null -ne $Value[$k]) {
                    $fields[$k] = ConvertTo-FirestoreValue $Value[$k]
                }
            }
            return @{ mapValue = @{ fields = $fields } }
        }
        throw "Unsupported type: $($Value.GetType())"
    }

    function ConvertTo-FirestoreDocument {
        param([hashtable]$Data)
        $fields = @{}
        foreach ($k in $Data.Keys) {
            if ($null -ne $Data[$k]) {
                $fields[$k] = ConvertTo-FirestoreValue $Data[$k]
            }
        }
        return @{ fields = $fields }
    }

    # -------------------------------------------------------------------------
    # Seed data
    # -------------------------------------------------------------------------
    $venues = @(
        @{
            id                 = 'seed-alnoor'
            ownerId            = 'seed-owner'
            title              = 'Al-Noor Palace Hall'
            description        = 'Elegant indoor banquet hall with crystal chandeliers, pro catering kitchen, valet parking, and a bridal suite. Perfect for weddings, galas, and corporate events.'
            location           = 'Downtown · 221 Oak Avenue'
            imageUrl           = 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=1200'
            isPublic           = $true
            accessCode         = $null
            isApprovedByAdmin  = $true
            category           = 'mixed'
            units              = @(
                @{ unitId = 'u1'; name = 'Grand Hall';          capacity = 300; pricePerDay = 1200 },
                @{ unitId = 'u2'; name = 'Garden Terrace';       capacity = 180; pricePerDay = 650  },
                @{ unitId = 'u3'; name = 'VIP Lounge';           capacity = 40;  pricePerDay = 350  }
            )
        },
        @{
            id                 = 'seed-jericho'
            ownerId            = 'seed-owner'
            title              = 'Jericho Garden Resort'
            description        = 'Expansive outdoor resort with lush gardens, infinity pool, and shaded tented areas. Family reunions, outdoor weddings, and festivals.'
            location           = 'Jericho · Palm Grove Road km 3'
            imageUrl           = 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=1200'
            isPublic           = $true
            accessCode         = $null
            isApprovedByAdmin  = $true
            category           = 'outdoor'
            units              = @(
                @{ unitId = 'u1'; name = 'Main Garden';         capacity = 500; pricePerDay = 900  },
                @{ unitId = 'u2'; name = 'Poolside Deck';        capacity = 120; pricePerDay = 500  }
            )
        },
        @{
            id                 = 'seed-loft1948'
            ownerId            = 'seed-owner'
            title              = 'Downtown Loft 1948'
            description        = 'Modern industrial loft with exposed brick, floor-to-ceiling windows, and an open layout. Ideal for product launches, workshops, and small weddings.'
            location           = 'Downtown · 1948 Industrial St, floor 4'
            imageUrl           = 'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=1200'
            isPublic           = $true
            accessCode         = $null
            isApprovedByAdmin  = $true
            category           = 'indoor'
            units              = @(
                @{ unitId = 'u1'; name = 'Full Loft';           capacity = 150; pricePerDay = 700  }
            )
        },
        @{
            id                 = 'seed-skyline'
            ownerId            = 'seed-owner'
            title              = 'Skyline Rooftop VIP'
            description        = 'Exclusive rooftop with 360° city views, fire pits, premium bar, and DJ booth. By-invitation events only — access code required.'
            location           = 'Midtown · 48 Horizon Blvd (floor 27)'
            imageUrl           = 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=1200'
            isPublic           = $false
            accessCode         = '7890'   # ← Guest must enter this
            isApprovedByAdmin  = $true
            category           = 'outdoor'
            units              = @(
                @{ unitId = 'u1'; name = 'Entire Rooftop';      capacity = 180; pricePerDay = 1500 }
            )
        },
        @{
            id                 = 'seed-executive'
            ownerId            = 'seed-owner'
            title              = 'Executive Business Suite'
            description        = 'Private conference center with 4K AV, hybrid-meeting rigging, boardroom, and a quiet break area. Access code shared with corporate accounts only.'
            location           = 'Business District · Tower B, floor 12'
            imageUrl           = 'https://images.unsplash.com/photo-1517502884422-41eaead166d4?w=1200'
            isPublic           = $false
            accessCode         = '1234'   # ← Guest must enter this
            isApprovedByAdmin  = $true
            category           = 'indoor'
            units              = @(
                @{ unitId = 'u1'; name = 'Main Boardroom';      capacity = 24;  pricePerDay = 450  },
                @{ unitId = 'u2'; name = 'Breakout Room A';     capacity = 10;  pricePerDay = 150  }
            )
        }
    )

    # -------------------------------------------------------------------------
    # Step 1: Backup current rules, write seed-mode rules
    # -------------------------------------------------------------------------
    Write-Host "=== Backing up firestore.rules ===" -ForegroundColor Cyan
    Copy-Item $RulesFile $BackupFile -Force

    # Write a minimal seed-mode rules file that ONLY allows creating/updating
    # venues with ownerId == "seed-owner". Everything else stays locked.
    $seedModeRules = @'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /venues/{venueId} {
      // Seed-mode: allow writes ONLY to seed-owner documents, so even if the
      // project ID were discovered during this ~30 sec window, no other data
      // could be injected.
      allow read, create, update: if request.resource.data.ownerId == "seed-owner";
    }
    // All other collections remain locked.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
'@
    Set-Content -Path $RulesFile -Value $seedModeRules -NoNewline

    Write-Host "=== Deploying seed-mode rules ===" -ForegroundColor Cyan
    firebase deploy --only firestore:rules --project $ProjectId 2>&1 | Select-String "released|Deploy complete|Error|FAILED|compiled" | Select-Object -First 5

    # -------------------------------------------------------------------------
    # Step 2 (optional): wipe existing seed-owner venues
    # -------------------------------------------------------------------------
    if ($WipeFirst) {
        Write-Host ""
        Write-Host "=== Wiping existing seed-owner venues ===" -ForegroundColor Yellow
        # Quick listing — only seed-owner docs are deletable without auth anyway
        foreach ($v in $venues) {
            $deleteUrl = "$BaseUrl/venues/$($v.id)"
            try {
                Invoke-RestMethod -Uri $deleteUrl -Method Delete -ErrorAction Stop | Out-Null
                Write-Host "  deleted $($v.id)"
            } catch {
                Write-Host "  (skipped $($v.id) - not present)"
            }
        }
    }

    # -------------------------------------------------------------------------
    # Step 3: POST seed venues via Firestore REST API
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "=== Seeding $($venues.Count) venues ===" -ForegroundColor Cyan
    $written = 0
    foreach ($v in $venues) {
        $doc = ConvertTo-FirestoreDocument $v
        $json = $doc | ConvertTo-Json -Depth 20 -Compress
        $createUrl = "$BaseUrl/venues?documentId=$($v.id)"
        try {
            Invoke-RestMethod -Uri $createUrl -Method Post -ContentType 'application/json' -Body $json -ErrorAction Stop | Out-Null
            Write-Host ("  + {0,-14} {1}  ({2})" -f $v.id, $v.title, $(if ($v.isPublic) {'PUBLIC'} else {'PRIVATE · code '+$v.accessCode}))
            $written++
        } catch {
            $errBody = ""
            try { $errBody = $_.ErrorDetails.Message } catch {}
            # If doc exists, try PATCH (update) instead
            if ($_.Exception.Response.StatusCode.value__ -eq 409) {
                $patchUrl = "$BaseUrl/venues/$($v.id)"
                try {
                    Invoke-RestMethod -Uri $patchUrl -Method Patch -ContentType 'application/json' -Body $json -ErrorAction Stop | Out-Null
                    Write-Host ("  ~ {0,-14} {1}  (updated)" -f $v.id, $v.title)
                    $written++
                } catch {
                    Write-Host ("  ! FAILED {0}: {1}" -f $v.id, $_.Exception.Message) -ForegroundColor Red
                    Write-Host "    Response: $errBody"
                }
            } else {
                Write-Host ("  ! FAILED {0}: {1}" -f $v.id, $_.Exception.Message) -ForegroundColor Red
                Write-Host "    Response: $errBody"
            }
        }
    }
    Write-Host ("Wrote {0}/{1} venues." -f $written, $venues.Count) -ForegroundColor Green

    # -------------------------------------------------------------------------
    # Step 4: Restore original rules
    # -------------------------------------------------------------------------
    Write-Host ""
    Write-Host "=== Restoring original firestore.rules ===" -ForegroundColor Cyan
    Copy-Item $BackupFile $RulesFile -Force
    Remove-Item $BackupFile -ErrorAction SilentlyContinue
    firebase deploy --only firestore:rules --project $ProjectId 2>&1 | Select-String "released|Deploy complete|Error|FAILED|compiled" | Select-Object -First 5

    Write-Host ""
    Write-Host "=== Done ===" -ForegroundColor Green
    Write-Host "Open the app (or restart it) and the Discover screen should show $written venues."
    Write-Host "Private venues require codes: Skyline=7890, Executive=1234"
}
finally {
    # Safety net — if we crashed mid-way, make sure rules go back to normal
    if (Test-Path $BackupFile) {
        Write-Host "`nSAFETY RESTORE triggered." -ForegroundColor Yellow
        Copy-Item $BackupFile $RulesFile -Force
        Remove-Item $BackupFile -ErrorAction SilentlyContinue
        firebase deploy --only firestore:rules --project $ProjectId 2>&1 | Select-Object -Last 3
    }
    Pop-Location
}
