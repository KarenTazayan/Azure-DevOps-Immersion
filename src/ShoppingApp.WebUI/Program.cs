using Microsoft.ApplicationInsights.Extensibility;
using MudBlazor.Services;
using ShoppingApp.WebUI;
using ShoppingApp.WebUI.Cluster;
using ShoppingApp.WebUI.Extensions;
using ShoppingApp.WebUI.Services;

var builder = WebApplication.CreateBuilder(args);

// Workshop case: 05_Azure-Pipelines-CD-Advanced

// Scalability on Azure Container Apps for Blazor based WebUI.
/*if (!builder.Environment.IsDevelopment())
{
    var azureBlobStorageFobWebUiUri = GlobalConfig.AzureBlobStorageFobWebUiUri;
    var azureKeyVaultFobWebUiUri = GlobalConfig.AzureKeyVaultFobWebUiUri;

    builder.UseCentralizedKeys(azureBlobStorageFobWebUiUri, azureKeyVaultFobWebUiUri);

    builder.Services.AddSignalR().AddAzureSignalR(options =>
    {
        options.ConnectionString = GlobalConfig.AzureSignalRConnection;
        options.ServerStickyMode =
            Microsoft.Azure.SignalR.ServerStickyMode.Required;
    });
}*/

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
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = GlobalConfig.AppInsightsConnectionString;
});

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