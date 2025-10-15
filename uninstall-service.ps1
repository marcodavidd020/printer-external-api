# Script de desinstalación del servicio PrinterApiService
# Ejecutar como Administrador

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "PrinterApiService",
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "C:\Services\PrinterApiService"
)

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Este script debe ejecutarse como Administrador"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Desinstalador de PrinterApiService" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar si el servicio existe
Write-Host "[1/4] Verificando servicio" -ForegroundColor Yellow
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Warning "El servicio '$ServiceName' no existe"
} else {
    Write-Host "      ✓ Servicio encontrado" -ForegroundColor Green
    
    # 2. Detener el servicio
    Write-Host "[2/4] Deteniendo servicio" -ForegroundColor Yellow
    if ($service.Status -eq 'Running') {
        Stop-Service -Name $ServiceName -Force
        Start-Sleep -Seconds 3
        Write-Host "      ✓ Servicio detenido" -ForegroundColor Green
    } else {
        Write-Host "      ℹ El servicio ya estaba detenido" -ForegroundColor Blue
    }
    
    # 3. Eliminar el servicio
    Write-Host "[3/4] Eliminando servicio" -ForegroundColor Yellow
    $result = sc.exe delete $ServiceName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      ✓ Servicio eliminado" -ForegroundColor Green
    } else {
        Write-Error "Error al eliminar el servicio"
    }
}

# 4. Eliminar regla de firewall
Write-Host "[4/4] Eliminando regla de firewall" -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "Printer API Service" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Remove-NetFirewallRule -DisplayName "Printer API Service" -ErrorAction SilentlyContinue
    Write-Host "      ✓ Regla de firewall eliminada" -ForegroundColor Green
} else {
    Write-Host "      ℹ No se encontró regla de firewall" -ForegroundColor Blue
}

# Opcional: Eliminar archivos
if ($RemoveFiles) {
    Write-Host ""
    Write-Host "Eliminando archivos de instalación" -ForegroundColor Yellow
    if (Test-Path $InstallPath) {
        Write-Host "¿Está seguro que desea eliminar '$InstallPath'? (S/N)" -ForegroundColor Red
        $confirm = Read-Host
        if ($confirm -eq 'S' -or $confirm -eq 's') {
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-Host "      ✓ Archivos eliminados" -ForegroundColor Green
        } else {
            Write-Host "      ℹ Operación cancelada" -ForegroundColor Blue
        }
    } else {
        Write-Host "      ℹ El directorio no existe" -ForegroundColor Blue
    }
}

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Desinstalación completada" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
if (-not $RemoveFiles) {
    Write-Host "Nota: Los archivos en '$InstallPath' no fueron eliminados." -ForegroundColor Yellow
    Write-Host "Para eliminarlos también, ejecute con el parámetro -RemoveFiles" -ForegroundColor Yellow
    Write-Host "Ejemplo: .\uninstall-service.ps1 -RemoveFiles" -ForegroundColor Cyan
}
Write-Host ""
