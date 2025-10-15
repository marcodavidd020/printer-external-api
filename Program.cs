using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Drawing.Printing;
using System.Drawing;
using System.IO;
using System.Collections.Generic;
using PdfiumViewer;

var builder = WebApplication.CreateBuilder(args);

// Permite que el servicio se ejecute como Windows Service
builder.Host.UseWindowsService();

// Configurar el puerto desde appsettings o usar 5000 por defecto
var port = builder.Configuration["ServerPort"] ?? "5000";

// Agregar servicios de logging
builder.Services.AddLogging();

var app = builder.Build();

var logger = app.Services.GetRequiredService<ILogger<Program>>();

// Endpoint principal para imprimir PDFs
app.MapPost("/print", async (HttpContext context) =>
{
    try
    {
        // Leer el PDF desde el cuerpo de la solicitud
        if (!context.Request.HasFormContentType)
            return Results.BadRequest("El contenido debe ser multipart/form-data");

        var form = await context.Request.ReadFormAsync();
        
        // Obtener el nombre de la impresora (obligatorio)
        var printerName = form["printerName"].ToString();
        if (string.IsNullOrEmpty(printerName))
            return Results.BadRequest("El parámetro 'printerName' es obligatorio");

        // Obtener el archivo PDF
        var pdfFile = form.Files["file"];
        if (pdfFile == null || pdfFile.Length == 0)
            return Results.BadRequest("No se proporcionó ningún archivo PDF");

        // Validar que sea un PDF
        if (!pdfFile.ContentType.Contains("pdf") && !pdfFile.FileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            return Results.BadRequest("El archivo debe ser un PDF");

        logger.LogInformation("Recibiendo PDF para imprimir en: {PrinterName}", printerName);

        // Guardar el PDF temporalmente
        var tempFilePath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.pdf");
        using (var stream = new FileStream(tempFilePath, FileMode.Create))
        {
            await pdfFile.CopyToAsync(stream);
        }

        // Imprimir el PDF
        PrintHelper.PrintPdfToSpecificPrinter(printerName, tempFilePath, logger);

        // Eliminar el archivo temporal
        File.Delete(tempFilePath);

        logger.LogInformation("PDF impreso exitosamente en: {PrinterName}", printerName);
        return Results.Ok(new { 
            message = $"PDF enviado a la impresora: {printerName}",
            success = true
        });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error al procesar la solicitud de impresión");
        return Results.Problem($"Error al imprimir: {ex.Message}");
    }
});

// Endpoint para listar impresoras disponibles
app.MapGet("/printers", () =>
{
    try
    {
        var printers = PrintHelper.GetAvailablePrinters();
        return Results.Ok(new { printers, count = printers.Count });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error al obtener la lista de impresoras");
        return Results.Problem($"Error al obtener impresoras: {ex.Message}");
    }
});

// Endpoint de salud
app.MapGet("/health", () => Results.Ok(new { 
    status = "healthy", 
    timestamp = DateTime.UtcNow 
}));

logger.LogInformation("Servicio de impresión iniciando en puerto {Port}", port);

app.Run($"http://0.0.0.0:{port}");

public static class PrintHelper
{
    public static void PrintPdfToSpecificPrinter(string printerName, string pdfFilePath, ILogger logger)
    {
        if (!File.Exists(pdfFilePath))
            throw new FileNotFoundException("El archivo PDF no existe", pdfFilePath);

        // Verificar que la impresora existe
        var availablePrinters = GetAvailablePrinters();
        if (!availablePrinters.Contains(printerName))
            throw new Exception($"La impresora '{printerName}' no está disponible. Impresoras disponibles: {string.Join(", ", availablePrinters)}");

        using (var document = PdfDocument.Load(pdfFilePath))
        {
            var printDoc = new PrintDocument();
            printDoc.PrinterSettings.PrinterName = printerName;
            printDoc.DocumentName = Path.GetFileName(pdfFilePath);

            if (!printDoc.PrinterSettings.IsValid)
                throw new Exception($"La impresora '{printerName}' no es válida");

            var currentPage = 0;

            printDoc.PrintPage += (sender, e) =>
            {
                try
                {
                    if (currentPage < document.PageCount)
                    {
                        // Renderizar la página del PDF
                        using (var image = document.Render(currentPage, 300, 300, true))
                        {
                            // Calcular el escalado para ajustar al papel
                            var pageWidth = e.PageBounds.Width;
                            var pageHeight = e.PageBounds.Height;
                            var imageAspect = (float)image.Width / image.Height;
                            var pageAspect = (float)pageWidth / pageHeight;

                            int width, height;
                            if (imageAspect > pageAspect)
                            {
                                width = pageWidth;
                                height = (int)(pageWidth / imageAspect);
                            }
                            else
                            {
                                height = pageHeight;
                                width = (int)(pageHeight * imageAspect);
                            }

                            var x = (pageWidth - width) / 2;
                            var y = (pageHeight - height) / 2;

                            e.Graphics.DrawImage(image, x, y, width, height);
                        }

                        currentPage++;
                        e.HasMorePages = currentPage < document.PageCount;
                    }
                    else
                    {
                        e.HasMorePages = false;
                    }
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Error al renderizar la página {Page}", currentPage);
                    throw;
                }
            };

            logger.LogInformation("Iniciando impresión de {PageCount} páginas", document.PageCount);
            printDoc.Print();
        }
    }

    public static List<string> GetAvailablePrinters()
    {
        var printers = new List<string>();
        foreach (string printer in PrinterSettings.InstalledPrinters)
        {
            printers.Add(printer);
        }
        return printers;
    }
}
