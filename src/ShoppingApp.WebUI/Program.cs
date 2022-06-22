using Microsoft.ApplicationInsights.Extensibility;
using MudBlazor.Services;
using ShoppingApp.WebUI;
using ShoppingApp.WebUI.Cluster;
using ShoppingApp.WebUI.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

builder.Services.AddMudServices();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ShoppingCartService>();
builder.Services.AddScoped<InventoryService>();
builder.Services.AddScoped<ProductService>();
builder.Services.AddScoped<ComponentStateChangedObserver>();
builder.Services.AddScoped<ToastService>();
builder.Services.AddLocalStorageServices();

// Application Insights.
builder.Services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();
builder.Services.AddApplicationInsightsTelemetry(GlobalConfig.InstrumentationKey);

// Configure Microsoft Orleans Client
builder.Services.AddScoped(_ =>
{
    var client = new Client().Build();
    client.Connect().Wait();
    return client;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this
    // for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();