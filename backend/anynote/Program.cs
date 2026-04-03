using anynote;
using anynote.Compression;
using anynote.Hubs;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;

Directory.CreateDirectory("/data");

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddResponseCompression(c =>
{
    c.EnableForHttps = true;
    c.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[] { "application/json" });
    c.Providers.Clear();
    c.Providers.Add<ZstdCompressionProvider>();
    c.Providers.Add<BrotliCompressionProvider>();
    c.Providers.Add<GzipCompressionProvider>();
});
builder.Services.Configure<ZstdCompressionProviderOptions>(options =>
{
    options.Level = 6;
});
builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = System.IO.Compression.CompressionLevel.Fastest;
});
builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = System.IO.Compression.CompressionLevel.Fastest;
});

// Add environment variables to configuration.
builder.Configuration.AddEnvironmentVariables();
builder.Services.AddLogging();
builder.Services.AddSignalR();

builder.Services.AddDbContext<NoteDbContext>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

new NoteDbContext().Database.Migrate();

var app = builder.Build();

Secret.value = app.Configuration["secret"];

app.UseResponseCompression();

app.UseStaticFiles();

app.UseSwagger();

app.UseSwaggerUI();

app.UseCors(option => option.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.MapHub<NoteHub>("/notehub");

Console.WriteLine($@"
============================================================
 AnyNote
============================================================

{(!string.IsNullOrEmpty(Secret.value) ? $"* your secret is {Secret.value}" : "* You haven't set a secret")}

");
app.Run();
