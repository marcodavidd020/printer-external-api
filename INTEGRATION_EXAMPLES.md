# Ejemplos de Integración

Este documento muestra cómo integrar el servicio PrinterApiService desde diferentes lenguajes de programación.

---

## C# / .NET

### Ejemplo básico

```csharp
using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

public class PrinterClient
{
    private readonly HttpClient _client;
    private readonly string _baseUrl;

    public PrinterClient(string baseUrl = "http://localhost:5000")
    {
        _client = new HttpClient();
        _baseUrl = baseUrl;
    }

    // Verificar salud del servicio
    public async Task<bool> CheckHealthAsync()
    {
        try
        {
            var response = await _client.GetAsync($"{_baseUrl}/health");
            return response.IsSuccessStatusCode;
        }
        catch
        {
            return false;
        }
    }

    // Obtener lista de impresoras
    public async Task<string[]> GetPrintersAsync()
    {
        var response = await _client.GetAsync($"{_baseUrl}/printers");
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<PrintersResponse>();
        return result?.Printers ?? Array.Empty<string>();
    }

    // Imprimir PDF
    public async Task<string> PrintPdfAsync(string printerName, string pdfFilePath)
    {
        if (!File.Exists(pdfFilePath))
            throw new FileNotFoundException("PDF no encontrado", pdfFilePath);

        using var form = new MultipartFormDataContent();
        
        // Agregar nombre de impresora
        form.Add(new StringContent(printerName), "printerName");
        
        // Agregar archivo PDF
        var fileContent = new ByteArrayContent(await File.ReadAllBytesAsync(pdfFilePath));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
        form.Add(fileContent, "file", Path.GetFileName(pdfFilePath));

        var response = await _client.PostAsync($"{_baseUrl}/print", form);
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<PrintResponse>();
        return result?.Message ?? "OK";
    }

    private class PrintersResponse
    {
        public string[] Printers { get; set; }
        public int Count { get; set; }
    }

    private class PrintResponse
    {
        public string Message { get; set; }
        public bool Success { get; set; }
    }
}

// Uso:
var client = new PrinterClient();

// Verificar servicio
if (await client.CheckHealthAsync())
{
    Console.WriteLine("Servicio activo");
    
    // Listar impresoras
    var printers = await client.GetPrintersAsync();
    foreach (var printer in printers)
    {
        Console.WriteLine($"- {printer}");
    }
    
    // Imprimir
    var result = await client.PrintPdfAsync("HP LaserJet Pro", @"C:\documento.pdf");
    Console.WriteLine(result);
}
```

---

## Python

### Ejemplo con `requests`

```python
import requests
from typing import List, Optional
import os

class PrinterClient:
    def __init__(self, base_url: str = "http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def check_health(self) -> bool:
        """Verificar si el servicio está activo"""
        try:
            response = self.session.get(f"{self.base_url}/health", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def get_printers(self) -> List[str]:
        """Obtener lista de impresoras disponibles"""
        response = self.session.get(f"{self.base_url}/printers")
        response.raise_for_status()
        data = response.json()
        return data.get('printers', [])
    
    def print_pdf(self, printer_name: str, pdf_path: str) -> dict:
        """Imprimir un PDF en una impresora específica"""
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"PDF no encontrado: {pdf_path}")
        
        with open(pdf_path, 'rb') as pdf_file:
            files = {'file': (os.path.basename(pdf_path), pdf_file, 'application/pdf')}
            data = {'printerName': printer_name}
            
            response = self.session.post(
                f"{self.base_url}/print",
                files=files,
                data=data
            )
            response.raise_for_status()
            return response.json()

# Uso:
if __name__ == "__main__":
    client = PrinterClient()
    
    # Verificar servicio
    if client.check_health():
        print("✓ Servicio activo")
        
        # Listar impresoras
        printers = client.get_printers()
        print(f"\nImpresoras disponibles ({len(printers)}):")
        for printer in printers:
            print(f"  • {printer}")
        
        # Imprimir
        if printers:
            result = client.print_pdf(printers[0], "documento.pdf")
            print(f"\n✓ {result['message']}")
    else:
        print("✗ Servicio no disponible")
```

---

## JavaScript / Node.js

### Ejemplo con `axios` y `form-data`

```javascript
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

class PrinterClient {
    constructor(baseUrl = 'http://localhost:5000') {
        this.baseUrl = baseUrl;
        this.client = axios.create({ baseURL: baseUrl });
    }

    // Verificar salud del servicio
    async checkHealth() {
        try {
            const response = await this.client.get('/health');
            return response.status === 200;
        } catch {
            return false;
        }
    }

    // Obtener lista de impresoras
    async getPrinters() {
        const response = await this.client.get('/printers');
        return response.data.printers || [];
    }

    // Imprimir PDF
    async printPdf(printerName, pdfFilePath) {
        if (!fs.existsSync(pdfFilePath)) {
            throw new Error(`PDF no encontrado: ${pdfFilePath}`);
        }

        const form = new FormData();
        form.append('printerName', printerName);
        form.append('file', fs.createReadStream(pdfFilePath), {
            filename: path.basename(pdfFilePath),
            contentType: 'application/pdf'
        });

        const response = await this.client.post('/print', form, {
            headers: form.getHeaders()
        });

        return response.data;
    }
}

// Uso:
(async () => {
    const client = new PrinterClient();

    // Verificar servicio
    if (await client.checkHealth()) {
        console.log('✓ Servicio activo');

        // Listar impresoras
        const printers = await client.getPrinters();
        console.log(`\nImpresoras disponibles (${printers.length}):`);
        printers.forEach(p => console.log(`  • ${p}`));

        // Imprimir
        if (printers.length > 0) {
            const result = await client.printPdf(printers[0], 'documento.pdf');
            console.log(`\n✓ ${result.message}`);
        }
    } else {
        console.log('✗ Servicio no disponible');
    }
})();
```

---

## Java

### Ejemplo con `OkHttp`

```java
import okhttp3.*;
import com.google.gson.Gson;
import java.io.File;
import java.io.IOException;
import java.util.List;

public class PrinterClient {
    private final OkHttpClient client;
    private final String baseUrl;
    private final Gson gson;

    public PrinterClient(String baseUrl) {
        this.baseUrl = baseUrl;
        this.client = new OkHttpClient();
        this.gson = new Gson();
    }

    // Verificar salud del servicio
    public boolean checkHealth() {
        Request request = new Request.Builder()
            .url(baseUrl + "/health")
            .build();

        try (Response response = client.newCall(request).execute()) {
            return response.isSuccessful();
        } catch (IOException e) {
            return false;
        }
    }

    // Obtener lista de impresoras
    public List<String> getPrinters() throws IOException {
        Request request = new Request.Builder()
            .url(baseUrl + "/printers")
            .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Error: " + response);
            }

            String json = response.body().string();
            PrintersResponse data = gson.fromJson(json, PrintersResponse.class);
            return data.printers;
        }
    }

    // Imprimir PDF
    public String printPdf(String printerName, String pdfFilePath) throws IOException {
        File pdfFile = new File(pdfFilePath);
        if (!pdfFile.exists()) {
            throw new IOException("PDF no encontrado: " + pdfFilePath);
        }

        RequestBody requestBody = new MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("printerName", printerName)
            .addFormDataPart("file", pdfFile.getName(),
                RequestBody.create(pdfFile, MediaType.parse("application/pdf")))
            .build();

        Request request = new Request.Builder()
            .url(baseUrl + "/print")
            .post(requestBody)
            .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Error: " + response);
            }

            String json = response.body().string();
            PrintResponse data = gson.fromJson(json, PrintResponse.class);
            return data.message;
        }
    }

    // Clases para deserialización
    private static class PrintersResponse {
        List<String> printers;
        int count;
    }

    private static class PrintResponse {
        String message;
        boolean success;
    }

    // Uso:
    public static void main(String[] args) throws IOException {
        PrinterClient client = new PrinterClient("http://localhost:5000");

        // Verificar servicio
        if (client.checkHealth()) {
            System.out.println("✓ Servicio activo");

            // Listar impresoras
            List<String> printers = client.getPrinters();
            System.out.println("\nImpresoras disponibles (" + printers.size() + "):");
            printers.forEach(p -> System.out.println("  • " + p));

            // Imprimir
            if (!printers.isEmpty()) {
                String result = client.printPdf(printers.get(0), "documento.pdf");
                System.out.println("\n✓ " + result);
            }
        } else {
            System.out.println("✗ Servicio no disponible");
        }
    }
}
```

---

## PowerShell (Avanzado)

### Cliente completo con manejo de errores

```powershell
class PrinterClient {
    [string]$BaseUrl
    
    PrinterClient([string]$baseUrl = "http://localhost:5000") {
        $this.BaseUrl = $baseUrl
    }
    
    [bool] CheckHealth() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/health" -Method Get -TimeoutSec 5
            return $true
        }
        catch {
            return $false
        }
    }
    
    [array] GetPrinters() {
        try {
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/printers" -Method Get
            return $response.printers
        }
        catch {
            Write-Error "Error al obtener impresoras: $_"
            return @()
        }
    }
    
    [object] PrintPdf([string]$printerName, [string]$pdfPath) {
        if (-not (Test-Path $pdfPath)) {
            throw "PDF no encontrado: $pdfPath"
        }
        
        try {
            $form = @{
                printerName = $printerName
                file = Get-Item -Path $pdfPath
            }
            
            $response = Invoke-RestMethod -Uri "$($this.BaseUrl)/print" -Method Post -Form $form
            return $response
        }
        catch {
            Write-Error "Error al imprimir: $_"
            throw
        }
    }
}

# Uso:
$client = [PrinterClient]::new()

if ($client.CheckHealth()) {
    Write-Host "✓ Servicio activo" -ForegroundColor Green
    
    $printers = $client.GetPrinters()
    Write-Host "`nImpresoras disponibles ($($printers.Count)):" -ForegroundColor Cyan
    $printers | ForEach-Object { Write-Host "  • $_" }
    
    if ($printers.Count -gt 0) {
        $result = $client.PrintPdf($printers[0], "C:\documento.pdf")
        Write-Host "`n✓ $($result.message)" -ForegroundColor Green
    }
}
else {
    Write-Host "✗ Servicio no disponible" -ForegroundColor Red
}
```

---

## cURL (Línea de comandos)

### Ejemplos básicos

```bash
# Health check
curl http://localhost:5000/health

# Listar impresoras
curl http://localhost:5000/printers

# Imprimir PDF
curl -X POST http://localhost:5000/print \
  -F "printerName=HP LaserJet Pro" \
  -F "file=@/ruta/documento.pdf"
```

### PowerShell con cURL

```powershell
# Health check
curl.exe http://localhost:5000/health

# Listar impresoras
curl.exe http://localhost:5000/printers

# Imprimir PDF
curl.exe -X POST http://localhost:5000/print `
  -F "printerName=HP LaserJet Pro" `
  -F "file=@C:\ruta\documento.pdf"
```

---

## PHP

### Ejemplo con cURL

```php
<?php

class PrinterClient {
    private $baseUrl;
    
    public function __construct($baseUrl = 'http://localhost:5000') {
        $this->baseUrl = $baseUrl;
    }
    
    public function checkHealth() {
        $ch = curl_init($this->baseUrl . '/health');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        return $httpCode === 200;
    }
    
    public function getPrinters() {
        $ch = curl_init($this->baseUrl . '/printers');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        curl_close($ch);
        
        $data = json_decode($response, true);
        return $data['printers'] ?? [];
    }
    
    public function printPdf($printerName, $pdfPath) {
        if (!file_exists($pdfPath)) {
            throw new Exception("PDF no encontrado: $pdfPath");
        }
        
        $ch = curl_init($this->baseUrl . '/print');
        
        $postData = [
            'printerName' => $printerName,
            'file' => new CURLFile($pdfPath, 'application/pdf', basename($pdfPath))
        ];
        
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        if ($httpCode !== 200) {
            throw new Exception("Error al imprimir: HTTP $httpCode");
        }
        
        return json_decode($response, true);
    }
}

// Uso:
$client = new PrinterClient();

if ($client->checkHealth()) {
    echo "✓ Servicio activo\n";
    
    $printers = $client->getPrinters();
    echo "\nImpresoras disponibles (" . count($printers) . "):\n";
    foreach ($printers as $printer) {
        echo "  • $printer\n";
    }
    
    if (count($printers) > 0) {
        $result = $client->printPdf($printers[0], 'documento.pdf');
        echo "\n✓ " . $result['message'] . "\n";
    }
} else {
    echo "✗ Servicio no disponible\n";
}
```

---

## Notas Importantes

1. **Seguridad**: El servicio no tiene autenticación. Para producción, considere agregar autenticación (API Key, OAuth, etc.)

2. **Red**: Si necesita acceder desde otra máquina, configure el firewall apropiadamente

3. **Tamaño de archivos**: Para archivos PDF muy grandes, puede ser necesario ajustar límites de tamaño en la configuración

4. **Timeout**: Para PDFs con muchas páginas, considere aumentar el timeout de las peticiones HTTP

5. **Manejo de errores**: Siempre implemente manejo de errores apropiado en sus integraciones
