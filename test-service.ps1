# Script de prueba del servicio PrinterApiService

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "http://localhost:5000",
    
    [Parameter(Mandatory=$false)]
    [string]$PrinterName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PdfFile = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Prueba de PrinterApiService" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "[Test 1/3] Health Check" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ServerUrl/health" -Method Get -TimeoutSec 5
    Write-Host "      ✓ Servicio activo" -ForegroundColor Green
    Write-Host "      Estado: $($response.status)" -ForegroundColor Gray
    Write-Host "      Timestamp: $($response.timestamp)" -ForegroundColor Gray
} catch {
    Write-Error "El servicio no responde. ¿Está iniciado?"
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Listar impresoras
Write-Host "[Test 2/3] Listar impresoras disponibles" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$ServerUrl/printers" -Method Get
    Write-Host "      ✓ Impresoras encontradas: $($response.count)" -ForegroundColor Green
    Write-Host ""
    Write-Host "      Impresoras disponibles:" -ForegroundColor White
    foreach ($printer in $response.printers) {
        Write-Host "        • $printer" -ForegroundColor Cyan
    }
    
    # Si no se especificó impresora, usar la primera
    if ([string]::IsNullOrEmpty($PrinterName) -and $response.printers.Count -gt 0) {
        $PrinterName = $response.printers[0]
        Write-Host ""
        Write-Host "      ℹ Usando impresora: $PrinterName" -ForegroundColor Blue
    }
} catch {
    Write-Error "Error al obtener las impresoras"
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Imprimir PDF (opcional)
if (-not [string]::IsNullOrEmpty($PdfFile) -and -not [string]::IsNullOrEmpty($PrinterName)) {
    Write-Host "[Test 3/3] Imprimir PDF" -ForegroundColor Yellow
    
    if (-not (Test-Path $PdfFile)) {
        Write-Error "El archivo PDF no existe: $PdfFile"
        exit 1
    }
    
    Write-Host "      Archivo: $PdfFile" -ForegroundColor Gray
    Write-Host "      Impresora: $PrinterName" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $form = @{
            printerName = $PrinterName
            file = Get-Item -Path $PdfFile
        }
        
        $response = Invoke-RestMethod -Uri "$ServerUrl/print" -Method Post -Form $form
        Write-Host "      ✓ PDF enviado a imprimir" -ForegroundColor Green
        Write-Host "      Respuesta: $($response.message)" -ForegroundColor Gray
    } catch {
        Write-Error "Error al imprimir el PDF"
        Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "      Detalles: $responseBody" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[Test 3/3] Imprimir PDF - OMITIDO" -ForegroundColor Blue
    Write-Host "      ℹ Para probar la impresión, ejecute:" -ForegroundColor Yellow
    Write-Host "        .\test-service.ps1 -PdfFile 'C:\ruta\archivo.pdf' -PrinterName '$PrinterName'" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pruebas completadas" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ejemplos de uso
Write-Host "Ejemplos de uso desde código:" -ForegroundColor White
Write-Host ""
Write-Host "PowerShell:" -ForegroundColor Yellow
Write-Host @"
`$form = @{
    printerName = '$PrinterName'
    file = Get-Item -Path 'C:\archivo.pdf'
}
Invoke-RestMethod -Uri '$ServerUrl/print' -Method Post -Form `$form
"@ -ForegroundColor Gray

Write-Host ""
Write-Host "cURL:" -ForegroundColor Yellow
Write-Host @"
curl -X POST $ServerUrl/print \
  -F "printerName=$PrinterName" \
  -F "file=@C:\archivo.pdf"
"@ -ForegroundColor Gray

Write-Host ""
Write-Host "Python:" -ForegroundColor Yellow
Write-Host @"
import requests
url = '$ServerUrl/print'
files = {'file': open('documento.pdf', 'rb')}
data = {'printerName': '$PrinterName'}
response = requests.post(url, files=files, data=data)
print(response.json())
"@ -ForegroundColor Gray

Write-Host ""
