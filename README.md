# PrinterApiService - Servicio de Impresión de PDFs

Servicio de Windows que expone un API REST para imprimir archivos PDF en impresoras específicas.

## Características

✅ Se ejecuta como servicio de Windows (siempre activo)
✅ API REST para recibir PDFs y enviarlos a imprimir
✅ Especificar impresora de destino
✅ Compilado como un único archivo .exe
✅ Auto-contenido (no requiere .NET instalado)

## Compilación

Para compilar el servicio:

```powershell
dotnet publish -c Release -r win-x64 --self-contained true
```

Los archivos se generarán en:
```
bin\Release\net9.0\win-x64\publish\
```

**Nota:** El servicio incluye archivos nativos (pdfium.dll) necesarios para renderizar PDFs, por lo que se compila como múltiples archivos en lugar de un único ejecutable.

## Instalación como Servicio de Windows

### 1. Copiar el ejecutable
Copie `PrinterApiService.exe` a una carpeta permanente, por ejemplo:
```
C:\Services\PrinterApiService\
```

### 2. Instalar el servicio
Abra PowerShell como **Administrador** y ejecute:

```powershell
# Navegar a la carpeta del ejecutable
cd C:\Services\PrinterApiService

# Crear el servicio
sc.exe create PrinterApiService binPath= "C:\Services\PrinterApiService\PrinterApiService.exe" start= auto

# O usar New-Service (PowerShell nativo)
New-Service -Name "PrinterApiService" -BinaryPathName "C:\Services\PrinterApiService\PrinterApiService.exe" -DisplayName "Printer API Service" -Description "Servicio para imprimir PDFs mediante API REST" -StartupType Automatic
```

### 3. Iniciar el servicio
```powershell
Start-Service PrinterApiService
```

### 4. Verificar el estado
```powershell
Get-Service PrinterApiService
```

## Configuración

### Puerto del servidor
Edite el archivo `appsettings.json` para cambiar el puerto (por defecto 5000):

```json
{
  "ServerPort": "8080"
}
```

**Importante:** Coloque el archivo `appsettings.json` en la misma carpeta que el .exe

## Uso del API

### 1. Verificar que el servicio está activo
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/health"
```

Respuesta:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-15T..."
}
```

### 2. Listar impresoras disponibles
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/printers"
```

Respuesta:
```json
{
  "printers": [
    "Microsoft Print to PDF",
    "HP LaserJet Pro",
    "Canon Printer"
  ],
  "count": 3
}
```

### 3. Imprimir un PDF

#### Usando PowerShell:
```powershell
$pdfPath = "C:\documentos\archivo.pdf"
$printerName = "HP LaserJet Pro"

$form = @{
    printerName = $printerName
    file = Get-Item -Path $pdfPath
}

Invoke-RestMethod -Uri "http://localhost:5000/print" -Method Post -Form $form
```

#### Usando cURL:
```bash
curl -X POST http://localhost:5000/print \
  -F "printerName=HP LaserJet Pro" \
  -F "file=@C:\documentos\archivo.pdf"
```

#### Usando C#:
```csharp
using var client = new HttpClient();
using var form = new MultipartFormDataContent();

form.Add(new StringContent("HP LaserJet Pro"), "printerName");

var fileContent = new ByteArrayContent(File.ReadAllBytes(@"C:\documentos\archivo.pdf"));
fileContent.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
form.Add(fileContent, "file", "archivo.pdf");

var response = await client.PostAsync("http://localhost:5000/print", form);
var result = await response.Content.ReadAsStringAsync();
```

#### Usando Python:
```python
import requests

url = "http://localhost:5000/print"
files = {'file': open('documento.pdf', 'rb')}
data = {'printerName': 'HP LaserJet Pro'}

response = requests.post(url, files=files, data=data)
print(response.json())
```

## Desinstalación

Para desinstalar el servicio:

```powershell
# Detener el servicio
Stop-Service PrinterApiService

# Eliminar el servicio
sc.exe delete PrinterApiService
```

## Solución de Problemas

### Ver logs del servicio
Los logs se pueden ver en el Visor de eventos de Windows:
- Presione `Win + R` y escriba `eventvwr.msc`
- Navegue a: Windows Logs → Application
- Busque eventos de origen "PrinterApiService"

### El servicio no inicia
1. Verifique que el puerto 5000 no esté en uso
2. Ejecute el .exe manualmente para ver errores: `.\PrinterApiService.exe`
3. Verifique los permisos del archivo

### Error "Impresora no disponible"
Use el endpoint `/printers` para ver las impresoras instaladas y sus nombres exactos.

## Firewall

Si necesita acceder al servicio desde otra máquina en la red, agregue una regla de firewall:

```powershell
New-NetFirewallRule -DisplayName "Printer API Service" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

## Requisitos

- Windows 6.1 o superior (Windows 7/Server 2008 R2+)
- .NET 9.0 Runtime (incluido en el .exe auto-contenido)

## Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Verificar estado del servicio |
| GET | `/printers` | Listar impresoras disponibles |
| POST | `/print` | Imprimir un PDF |

## Parámetros de `/print`

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `printerName` | string | Sí | Nombre exacto de la impresora |
| `file` | file | Sí | Archivo PDF a imprimir |
# printer-external-api
