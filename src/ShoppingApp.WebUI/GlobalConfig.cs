namespace ShoppingApp.WebUI;

public static class GlobalConfig
{
    public static string AzureStorageConnection => Resolver.AzureStorageConnectionString;

    public static string InstrumentationKey => Resolver.InstrKey;

    private static class Resolver
    {
        public static string AzureStorageConnectionString =>
            Environment.GetEnvironmentVariable(EnvironmentVariables.AzureStorageConnectionString) ??
            string.Empty;

        public static string InstrKey =>
            Environment.GetEnvironmentVariable(EnvironmentVariables.InstrumentationKey) ??
            string.Empty;
    }
}