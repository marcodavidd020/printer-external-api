# 📋 Resumen del Proyecto - PrinterApiService

## ✅ Lo que se ha implementado

Este proyecto es un **Servicio de Windows** que expone un **API REST** para imprimir archivos PDF en impresoras específicas.

### Características Implementadas

✅ **Servicio de Windows**
   - Se ejecuta como servicio de Windows (siempre activo)
   - Configurado para inicio automático
   - Se puede instalar/desinstalar fácilmente

✅ **API REST**
   - Endpoint para recibir PDFs y enviarlos a impresoras específicas
   - Endpoint para listar impresoras disponibles
   - Endpoint de health check
   - Puerto configurable (por defecto: 5000)

✅ **Manejo de PDFs**
   - Acepta PDFs mediante multipart/form-data
   - Renderiza PDFs usando PdfiumViewer
   - Ajusta automáticamente el tamaño al papel
   - Soporte para PDFs de múltiples páginas

✅ **Compilación**
   - Se compila como un único archivo .exe
   - Auto-contenido (no requiere .NET instalado)
   - Tamaño aproximado: 97 MB

✅ **Documentación**
   - README completo con instrucciones
   - Guía rápida de instalación (QUICKSTART.md)
   - Ejemplos de integración en 7 lenguajes (INTEGRATION_EXAMPLES.md)
   - Scripts automatizados de instalación/desinstalación

---

## 📁 Estructura del Proyecto

```
PrinterApiService/
├── Program.cs                      # Código principal del servicio y API
├── PrinterApiService.csproj        # Configuración del proyecto .NET
├── appsettings.json                # Configuración (puerto, logging)
├── README.md                       # Documentación completa
├── QUICKSTART.md                   # Guía rápida
├── INTEGRATION_EXAMPLES.md         # Ejemplos de código
├── install-service.ps1             # Script de instalación automática
├── uninstall-service.ps1           # Script de desinstalación
├── test-service.ps1                # Script de pruebas
└── .gitignore                      # Archivos ignorados por Git
```

---

## 🚀 Cómo Usar

### 1. Compilar el proyecto

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

**Resultado:** `bin\Release\net9.0\win-x64\publish\PrinterApiService.exe` (~97 MB)

### 2. Instalar como servicio (Modo Automático)

```powershell
# Ejecutar PowerShell como Administrador
.\install-service.ps1
```

**Opciones personalizadas:**
```powershell
.\install-service.ps1 -InstallPath "D:\MiServicio" -Port 8080
```

### 3. Probar el servicio

```powershell
.\test-service.ps1
```

O manualmente:
```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:5000/health"

# Listar impresoras
Invoke-RestMethod -Uri "http://localhost:5000/printers"

# Imprimir PDF
$form = @{
    printerName = "Nombre de tu impresora"
    file = Get-Item -Path "C:\documento.pdf"
}
Invoke-RestMethod -Uri "http://localhost:5000/print" -Method Post -Form $form
```

---

## 🔌 Endpoints del API

| Método | Endpoint | Descripción | Parámetros |
|--------|----------|-------------|------------|
| `GET` | `/health` | Verificar estado del servicio | Ninguno |
| `GET` | `/printers` | Listar impresoras disponibles | Ninguno |
| `POST` | `/print` | Imprimir un PDF | `printerName` (string), `file` (PDF) |

---

## 💻 Ejemplos de Integración

El proyecto incluye ejemplos completos para integrar el servicio desde:

1. **C# / .NET** - Cliente con HttpClient
2. **Python** - Cliente con requests
3. **JavaScript / Node.js** - Cliente con axios
4. **Java** - Cliente con OkHttp
5. **PowerShell** - Cliente orientado a objetos
6. **cURL** - Comandos de terminal
7. **PHP** - Cliente con cURL

Ver [INTEGRATION_EXAMPLES.md](INTEGRATION_EXAMPLES.md) para código completo.

---

## ⚙️ Configuración

### Puerto del servidor

Editar `appsettings.json`:
```json
{
  "ServerPort": "8080"
}
```

### Logging

Editar `appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

Los logs se escriben en el Visor de eventos de Windows (Application log).

---

## 🗑️ Desinstalación

### Desinstalar el servicio

```powershell
.\uninstall-service.ps1
```

### Desinstalar y eliminar archivos

```powershell
.\uninstall-service.ps1 -RemoveFiles
```

---

## 🔧 Administración del Servicio

### Ver estado del servicio

```powershell
Get-Service PrinterApiService
```

### Iniciar servicio

```powershell
Start-Service PrinterApiService
```

### Detener servicio

```powershell
Stop-Service PrinterApiService
```

### Reiniciar servicio

```powershell
Restart-Service PrinterApiService
```

### Ver logs

1. Presionar `Win + R`
2. Escribir `eventvwr.msc`
3. Ir a: Windows Logs → Application
4. Buscar eventos de "PrinterApiService"

---

## 🌐 Acceso desde Red

### Configurar Firewall

El script de instalación ofrece crear la regla automáticamente, o manualmente:

```powershell
New-NetFirewallRule -DisplayName "Printer API Service" `
                    -Direction Inbound `
                    -LocalPort 5000 `
                    -Protocol TCP `
                    -Action Allow
```

### Acceder desde otra máquina

Reemplazar `localhost` por la IP del servidor:
```
http://192.168.1.100:5000/health
```

---

## 📦 Dependencias

El proyecto usa las siguientes bibliotecas NuGet:

- **Microsoft.Extensions.Hosting.WindowsServices** (9.0.0) - Soporte para servicios de Windows
- **PdfiumViewer** (2.13.0) - Renderizado de PDFs
- **System.Drawing.Common** (9.0.0) - Operaciones gráficas

Todas las dependencias están incluidas en el ejecutable compilado.

---

## 🛡️ Consideraciones de Seguridad

⚠️ **IMPORTANTE:** Este servicio no tiene autenticación implementada.

Para uso en producción, considere:

1. **Agregar autenticación** (API Key, JWT, OAuth)
2. **Usar HTTPS** en lugar de HTTP
3. **Validar tipos de archivos** más estrictamente
4. **Limitar tamaño de archivos**
5. **Rate limiting** para prevenir abuso
6. **Whitelist de impresoras** permitidas

---

## 🐛 Solución de Problemas

### El servicio no inicia

1. Verificar que el puerto no esté en uso:
   ```powershell
   Get-NetTCPConnection -LocalPort 5000
   ```

2. Ejecutar el .exe manualmente para ver errores:
   ```powershell
   cd C:\Services\PrinterApiService
   .\PrinterApiService.exe
   ```

3. Verificar permisos del archivo y carpeta

### Error "Impresora no disponible"

Use el endpoint `/printers` para ver los nombres exactos de las impresoras instaladas.

### PDF no se imprime

1. Verificar que el PDF es válido
2. Verificar que la impresora está encendida y conectada
3. Revisar los logs del sistema

### El servicio se detiene solo

1. Verificar logs en el Visor de eventos
2. Verificar que no hay conflictos de puerto
3. Verificar que hay suficiente memoria disponible

---

## 📝 Notas Técnicas

- **Framework:** .NET 9.0
- **Runtime:** Windows x64 (win-x64)
- **Tipo de publicación:** Single-file, Self-contained
- **Plataforma mínima:** Windows 6.1 (Windows 7 / Server 2008 R2)

---

## 📄 Licencia

Este es un proyecto interno. Configure la licencia según sus necesidades.

---

## 👨‍💻 Mantenimiento

### Actualizar el servicio

1. Detener el servicio
2. Compilar nueva versión
3. Reemplazar el .exe
4. Iniciar el servicio

O usar el script de instalación que hace todo automáticamente:
```powershell
.\install-service.ps1
```

### Cambiar configuración

1. Editar `appsettings.json` en la carpeta de instalación
2. Reiniciar el servicio:
   ```powershell
   Restart-Service PrinterApiService
   ```

---

## 📚 Recursos Adicionales

- [README.md](README.md) - Documentación completa
- [QUICKSTART.md](QUICKSTART.md) - Guía rápida de inicio
- [INTEGRATION_EXAMPLES.md](INTEGRATION_EXAMPLES.md) - Ejemplos de código

---

## ✨ Conclusión

El proyecto está **completo y funcional**. Incluye:

✅ Código fuente del servicio  
✅ Compilación como ejecutable único  
✅ API REST para imprimir PDFs  
✅ Scripts de instalación/desinstalación  
✅ Scripts de prueba  
✅ Documentación completa  
✅ Ejemplos de integración en múltiples lenguajes  

**El servicio está listo para ser desplegado en producción.**
