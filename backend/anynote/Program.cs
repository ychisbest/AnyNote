using anynote;
using anynote.Hubs;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

Directory.CreateDirectory("/data");

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddResponseCompression(c =>
    {
        c.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(new[] { "application/json" });
        c.Providers.Add(new BrotliCompressionProvider(new BrotliCompressionProviderOptions() { Level = System.IO.Compression.CompressionLevel.Optimal }));
        c.Providers.Add(new GzipCompressionProvider(
        new GzipCompressionProviderOptions()
        {
            Level = System.IO.Compression.CompressionLevel.Optimal
        }
        ));
    }
);

// 添加环境变量到配置中
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
┌──────────────────────────────────────────────────────────────────┐
│  █████╗ ███╗   ██╗██╗   ██╗███╗   ██╗ ██████╗ ████████╗███████╗  │
│ ██╔══██╗████╗  ██║╚██╗ ██╔╝████╗  ██║██╔═══██╗╚══██╔══╝██╔════╝  │
│ ███████║██╔██╗ ██║ ╚████╔╝ ██╔██╗ ██║██║   ██║   ██║   █████╗    │
│ ██╔══██║██║╚██╗██║  ╚██╔╝  ██║╚██╗██║██║   ██║   ██║   ██╔══╝    │
│ ██║  ██║██║ ╚████║   ██║   ██║ ╚████║╚██████╔╝   ██║   ███████╗  │
│ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝  │
└──────────────────────────────────────────────────────────────────┘

                                                               

{(!string.IsNullOrEmpty(Secret.value)? $"* your secret is {Secret.value}": "* You haven't set a secret")}

");
app.Run();
