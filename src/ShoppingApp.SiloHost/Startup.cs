using Microsoft.ApplicationInsights.Extensibility;
using System.Reflection;
using ShoppingApp.Common;

namespace ShoppingApp.SiloHost;

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Application Insights.
        services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();
        services.AddApplicationInsightsTelemetry(options =>
        {
            options.ConnectionString = GlobalConfig.AppInsightsConnectionString;
        });
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.Run(async context =>
        {
            var assembly = Assembly.GetExecutingAssembly();
            var version = AppInfo.RetrieveInformationalVersion(assembly);
            await context.Response.WriteAsync($"App version: [ {version} ]. Status: Running...");
        });
    }
}