using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;
using System.Reflection;
using ShoppingApp.Common;

namespace ShoppingApp.WebUI;

internal class TelemetryInitializer : ITelemetryInitializer
{
    private readonly string _roleName;

    public TelemetryInitializer()
    {
        _roleName = "ShoppingApp.WebUI";
    }

    public void Initialize(ITelemetry telemetry)
    {
        telemetry.Context.Cloud.RoleName = _roleName;
        // TODO: Make this dynamically assignable from environment variable.
        telemetry.Context.Cloud.RoleInstance = _roleName;

        var assembly = Assembly.GetExecutingAssembly();
        var version = AppInfo.RetrieveInformationalVersion(assembly);
        telemetry.Context.Component.Version = version;
    }
}