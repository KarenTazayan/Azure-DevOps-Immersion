using Orleans;
using Orleans.Configuration;
// ReSharper disable once RedundantUsingDirective
using Orleans.Hosting;
using ShoppingApp.Abstractions;

namespace ShoppingApp.WebUI.Cluster;

public class Client
{
    public IClusterClient Build()
    {
        var builder = new ClientBuilder()
#if DEBUG
            .UseLocalhostClustering()
#else
            .UseAzureStorageClustering(options =>
            {
                options.ConfigureTableServiceClient(GlobalConfig.AzureStorageConnection);
            })
#endif
            .Configure<ClusterOptions>(options =>
            {
                options.ClusterId = "ShoppingApp";
                options.ServiceId = "ShoppingAppService";
            })
            .ConfigureApplicationParts(parts =>
                parts.AddApplicationPart(typeof(IProductGrain).Assembly).WithReferences())
            .ConfigureServices(services => {});

        return builder.Build();
    }
}