using ShoppingApp.Silo.Telemetry;

namespace ShoppingApp.Silo.Extensions;

internal static class ServiceCollectionExtensions
{
    internal static void AddApplicationInsights(
        this IServiceCollection services, string applicationName)
    {
        services.AddApplicationInsightsTelemetry();
        services.AddSingleton<ITelemetryInitializer>(
            _ => new ApplicationMapNodeNameInitializer(applicationName));
    }
}
