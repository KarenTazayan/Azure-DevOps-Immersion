using Microsoft.ApplicationInsights.Extensibility;

namespace ShoppingApp.SiloHost;

public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Application Insights.
        services.AddSingleton<ITelemetryInitializer, TelemetryInitializer>();
        services.AddApplicationInsightsTelemetry(GlobalConfig.InstrumentationKey);
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        app.Run(async context =>
        {
            await context.Response.WriteAsync("Running...");
        });
    }
}