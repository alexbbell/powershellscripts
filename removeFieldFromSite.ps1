#Remove the specific field from SharePoint Site - lists, content types ...
$url = ''

Connect-PnPOnline -Url $url -Interactive

# ============================================================
# CONFIG
# ============================================================
$FieldInternalName = "ReportsToBUHeadValue"
$ListTitle         = "Personal Requisitions"   # set to $null to skip list cleanup
$DeleteFromSite    = $true                     # remove from Site Columns gallery
$TouchListCTs      = $true                     # also remove from ALL list content types
$UnsealTemporarily = $true                     # unseal/readOnly CTs to remove field link
# ============================================================

Write-Host "Starting cleanup for field '$FieldInternalName'..." -ForegroundColor Cyan

# Helper: try get the field at site scope
$siteField = Get-PnPField -Identity $FieldInternalName -ErrorAction SilentlyContinue
if (-not $siteField) {
  Write-Host "Note: site column '$FieldInternalName' not found at site collection scope (may still exist at list scope)." -ForegroundColor Yellow
}

# 1) Remove from a specific LIST (field)
if ($ListTitle) {
  $list = Get-PnPList -Identity $ListTitle -ErrorAction SilentlyContinue
  if ($list) {
    $listField = Get-PnPField -List $ListTitle -Identity $FieldInternalName -ErrorAction SilentlyContinue
    if ($listField) {
      Write-Host " - Removing field from list '$ListTitle'..."
      Remove-PnPField -List $ListTitle -Identity $FieldInternalName -Force -ErrorAction Stop
    } else {
      Write-Host " - Field not found in list '$ListTitle'."
    }
  } else {
    Write-Host " - List '$ListTitle' not found." -ForegroundColor Yellow
  }
}

# 2) Remove from ALL SITE CONTENT TYPES
Write-Host "Scanning site content types for field links..." -ForegroundColor Cyan
$cts = Get-PnPContentType -ErrorAction Stop
foreach ($ct in $cts) {
  try {
    # Load FieldLinks (lazy)
    Get-PnPProperty -ClientObject $ct -Property FieldLinks | Out-Null

    # Find matching field link by InternalName or by Id (if we have the site field)
    $match = $ct.FieldLinks | Where-Object {
      $_.Name -eq $FieldInternalName -or ($siteField -and $_.Id -eq $siteField.Id)
    }

    if ($match) {
      Write-Host " - Removing field from SITE CT: '$($ct.Name)' (Id: $($ct.StringId))"

      $sealedWas    = $ct.Sealed
      $readonlyWas  = $ct.ReadOnly

      if ($UnsealTemporarily -and ($ct.Sealed -or $ct.ReadOnly)) {
        Write-Host "   > Unsealing / making writable temporarily..."
        Set-PnPContentType -Identity $ct -Sealed:$false -ReadOnly:$false -ErrorAction Stop | Out-Null
      }

      # Remove field link (pass the CT object directly)
      Remove-PnPFieldFromContentType -Field $FieldInternalName -ContentType $ct -ErrorAction Stop

      # Restore sealed/readonly if we changed it
      if ($UnsealTemporarily -and ($sealedWas -or $readonlyWas)) {
        Write-Host "   > Restoring sealed/readOnly flags..."
        Set-PnPContentType -Identity $ct -Sealed:$sealedWas -ReadOnly:$readonlyWas | Out-Null
      }
    }
  }
  catch {
    Write-Host "   ! Skipped CT '$($ct.Name)': $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# 3) (Optional) Remove from ALL LIST CONTENT TYPES
if ($TouchListCTs) {
  Write-Host "Scanning ALL lists' content types..." -ForegroundColor Cyan
  $allLists = Get-PnPList
  foreach ($l in $allLists) {
    try {
      $lcts = Get-PnPContentType -List $l -ErrorAction SilentlyContinue
      foreach ($lct in $lcts) {
        # Load FieldLinks
        Get-PnPProperty -ClientObject $lct -Property FieldLinks | Out-Null
        $match = $lct.FieldLinks | Where-Object {
          $_.Name -eq $FieldInternalName -or ($siteField -and $_.Id -eq $siteField.Id)
        }
        if ($match) {
          Write-Host " - Removing field from LIST CT: '$($lct.Name)' on list '$($l.Title)'"
          $sealedWas   = $lct.Sealed
          $readonlyWas = $lct.ReadOnly

          if ($UnsealTemporarily -and ($lct.Sealed -or $lct.ReadOnly)) {
            Set-PnPContentType -List $l -Identity $lct -Sealed:$false -ReadOnly:$false | Out-Null
          }

          Remove-PnPFieldFromContentType -Field $FieldInternalName -ContentType $lct -ErrorAction Stop

          if ($UnsealTemporarily -and ($sealedWas -or $readonlyWas)) {
            Set-PnPContentType -List $l -Identity $lct -Sealed:$sealedWas -ReadOnly:$readonlyWas | Out-Null
          }
        }
      }
    } catch {
      Write-Host "   ! Skipped list '$($l.Title)': $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
}

# 4) Remove from SITE COLUMNS (gallery)
if ($DeleteFromSite) {
  $siteField = Get-PnPField -Identity $FieldInternalName -ErrorAction SilentlyContinue
  if ($siteField) {
    Write-Host "Removing field from Site Columns gallery..."
    Remove-PnPField -Identity $FieldInternalName -Force -ErrorAction Stop
  } else {
    Write-Host "Site column '$FieldInternalName' not found or already deleted."
  }
}

Write-Host "✅ Cleanup finished for '$FieldInternalName'." -ForegroundColor Green
