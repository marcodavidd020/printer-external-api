# Script de instalación del servicio PrinterApiService
# Ejecutar como Administrador

param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "C:\Services\PrinterApiService",
    
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "PrinterApiService",
    
    [Parameter(Mandatory=$false)]
    [string]$DisplayName = "Printer API Service",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5000
)

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Este script debe ejecutarse como Administrador"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalador de PrinterApiService" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Crear directorio de instalación
Write-Host "[1/6] Creando directorio de instalación: $InstallPath" -ForegroundColor Yellow
if (-not (Test-Path $InstallPath)) {
    New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    Write-Host "      OK Directorio creado" -ForegroundColor Green
} else {
    Write-Host "      INFO Directorio ya existe" -ForegroundColor Blue
}

# 2. Copiar archivos
Write-Host "[2/6] Copiando archivos ejecutables" -ForegroundColor Yellow
$publishPath = "bin\Release\net9.0\win-x64\publish"
if (-not (Test-Path $publishPath)) {
    Write-Error "No se encontró la carpeta de publicación. Ejecute: dotnet publish -c Release -r win-x64 --self-contained true"
    exit 1
}

Copy-Item -Path "$publishPath\*" -Destination $InstallPath -Recurse -Force
Write-Host "      OK Archivos copiados" -ForegroundColor Green

# 3. Actualizar configuración del puerto
Write-Host "[3/6] Configurando puerto: $Port" -ForegroundColor Yellow
$appsettingsPath = Join-Path $InstallPath "appsettings.json"
if (Test-Path $appsettingsPath) {
    $appsettings = Get-Content $appsettingsPath | ConvertFrom-Json
    $appsettings.ServerPort = $Port.ToString()
    $appsettings | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
    Write-Host "      OK Puerto configurado" -ForegroundColor Green
}

# 4. Verificar si el servicio ya existe
Write-Host "[4/6] Verificando servicio existente" -ForegroundColor Yellow
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "      INFO Servicio ya existe. Deteniendo..." -ForegroundColor Blue
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    Write-Host "      INFO Eliminando servicio anterior..." -ForegroundColor Blue
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 2
}

# 5. Crear e instalar el servicio
Write-Host "[5/6] Instalando servicio de Windows" -ForegroundColor Yellow
$binaryPath = Join-Path $InstallPath "PrinterApiService.exe"
$result = sc.exe create $ServiceName binPath= $binaryPath start= auto DisplayName= $DisplayName

if ($LASTEXITCODE -eq 0) {
    Write-Host "      OK Servicio instalado" -ForegroundColor Green
    
    # Configurar descripción del servicio
    sc.exe description $ServiceName "Servicio REST API para imprimir archivos PDF en impresoras específicas" | Out-Null
    
    # Configurar recuperación del servicio en caso de fallo
    sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null
} else {
    Write-Error "Error al crear el servicio"
    exit 1
}

# 6. Iniciar el servicio
Write-Host "[6/6] Iniciando servicio" -ForegroundColor Yellow
Start-Service -Name $ServiceName
Start-Sleep -Seconds 3

# Verificar estado
$service = Get-Service -Name $ServiceName
if ($service.Status -eq 'Running') {
    Write-Host "      OK Servicio iniciado correctamente" -ForegroundColor Green
} else {
    Write-Warning "El servicio no está en ejecución. Estado: $($service.Status)"
}

# 7. Configurar regla de firewall (opcional)
Write-Host ""
Write-Host "Desea crear una regla de firewall para el puerto $Port? (S/N)" -ForegroundColor Cyan
$createFirewall = Read-Host
if ($createFirewall -eq 'S' -or $createFirewall -eq 's') {
    Write-Host "Creando regla de firewall..." -ForegroundColor Yellow
    
    # Eliminar regla existente si existe
    Remove-NetFirewallRule -DisplayName "Printer API Service" -ErrorAction SilentlyContinue
    
    # Crear nueva regla
    New-NetFirewallRule -DisplayName "Printer API Service" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow -Profile Any | Out-Null
    Write-Host "      OK Regla de firewall creada" -ForegroundColor Green
}

# Resumen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Instalación completada exitosamente" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Detalles del servicio:" -ForegroundColor White
Write-Host "  Nombre: $ServiceName" -ForegroundColor Gray
Write-Host "  Ubicación: $InstallPath" -ForegroundColor Gray
Write-Host "  Puerto: $Port" -ForegroundColor Gray
Write-Host "  Estado: $($service.Status)" -ForegroundColor Gray
Write-Host ""
Write-Host "Endpoints disponibles:" -ForegroundColor White
Write-Host "  Health Check:       http://localhost:$Port/health" -ForegroundColor Gray
Write-Host "  Listar impresoras:  http://localhost:$Port/printers" -ForegroundColor Gray
Write-Host "  Imprimir PDF:       http://localhost:$Port/print (POST)" -ForegroundColor Gray
Write-Host ""
Write-Host "Para probar el servicio ejecute:" -ForegroundColor Yellow
Write-Host "  Invoke-RestMethod -Uri http://localhost:$Port/health" -ForegroundColor Cyan
Write-Host ""
