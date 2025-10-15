# Guía Rápida de Instalación

## Instalación Automática (Recomendado)

1. **Compilar el proyecto:**
   ```powershell
   dotnet publish -c Release -r win-x64 --self-contained true
   ```

2. **Instalar como servicio** (Ejecutar PowerShell como Administrador):
   ```powershell
   .\install-service.ps1
   ```

   O con opciones personalizadas:
   ```powershell
   .\install-service.ps1 -InstallPath "D:\MiServicio" -Port 8080
   ```

3. **Probar el servicio:**
   ```powershell
   .\test-service.ps1
   ```

## Instalación Manual

### 1. Compilar
```powershell
dotnet publish -c Release -r win-x64 --self-contained true
```

### 2. Copiar archivos
```powershell
$destino = "C:\Services\PrinterApiService"
New-Item -Path $destino -ItemType Directory -Force
Copy-Item "bin\Release\net9.0\win-x64\publish\*" -Destination $destino -Recurse
```

### 3. Instalar servicio
```powershell
sc.exe create PrinterApiService binPath= "C:\Services\PrinterApiService\PrinterApiService.exe" start= auto
sc.exe description PrinterApiService "Servicio REST API para imprimir PDFs"
Start-Service PrinterApiService
```

### 4. Verificar
```powershell
Get-Service PrinterApiService
Invoke-RestMethod -Uri "http://localhost:5000/health"
```

## Uso Rápido

### Listar impresoras:
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/printers"
```

### Imprimir PDF:
```powershell
$form = @{
    printerName = "Nombre de tu impresora"
    file = Get-Item -Path "C:\ruta\documento.pdf"
}
Invoke-RestMethod -Uri "http://localhost:5000/print" -Method Post -Form $form
```

## Desinstalación

```powershell
.\uninstall-service.ps1 -RemoveFiles
```

## Documentación Completa

Ver [README.md](README.md) para documentación completa.
