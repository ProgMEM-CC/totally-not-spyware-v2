Write-Host "Installing PuTTY (provides plink for auto-password SSH)..." -ForegroundColor Cyan
try {
  winget install -e --id PuTTY.PuTTY --silent --accept-package-agreements --accept-source-agreements
} catch {
  Write-Warning "winget failed. You can download PuTTY manually: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"
}
Write-Host "Done. Ensure 'plink' is in PATH. Re-run tns-agent-setup.ps1." -ForegroundColor Green

