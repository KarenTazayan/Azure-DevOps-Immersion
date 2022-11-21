namespace ShoppingApp.WebUI;

internal static class EnvironmentVariables
{
    public static string AzureStorageConnectionString =>
        "AZURE_STORAGE_CONNECTION_STRING";

    public static string InstrumentationKey =>
        "APPINSIGHTS_CONNECTION_STRING";

    public static string SignalRConnectionString =>
        "AZURE_SIGNALR_CONNECTION_STRING";
}