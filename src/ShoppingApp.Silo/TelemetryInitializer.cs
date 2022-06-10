namespace ShoppingApp.Silo;

internal class TelemetryInitializer : ITelemetryInitializer
{
    private readonly string _roleName;

    public TelemetryInitializer()
    {
        _roleName = "ShoppingApp.Silo";
    }

    public void Initialize(ITelemetry telemetry)
    {
        telemetry.Context.Cloud.RoleName = _roleName;
        // TODO: Make this dynamically assignable from environment variable.
        telemetry.Context.Cloud.RoleInstance = _roleName;
    }
}