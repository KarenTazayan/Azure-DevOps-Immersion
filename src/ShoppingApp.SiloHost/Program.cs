using Orleans.Configuration;
using Orleans.Hosting;
using ShoppingApp.SiloHost;
using System.Net;

var builder = Host.CreateDefaultBuilder(args);

builder.UseOrleans((context, siloBuilder) =>
{
    if (context.HostingEnvironment.IsDevelopment())
    {
        siloBuilder.UseLocalhostClustering()
            .AddMemoryGrainStorage("ShoppingApp")
            .AddStartupTask<SeedProductStoreTask>();
    }
    else
    {
        var endpointAddress =
            IPAddress.Parse(context.Configuration["WEBSITE_PRIVATE_IP"]);
        var strPorts =
            context.Configuration["WEBSITE_PRIVATE_PORTS"].Split(',');
        if (strPorts.Length < 2)
            throw new Exception("Insufficient private ports configured.");
        var (siloPort, gatewayPort) =
            (int.Parse(strPorts[0]), int.Parse(strPorts[1]));
        var connectionString = context.Configuration["AZURE_STORAGE_CONNECTION_STRING"];

        siloBuilder.Configure<ClusterMembershipOptions>(options =>
        {
            //options.NumVotesForDeathDeclaration = 1;
            //options.TableRefreshTimeout = TimeSpan.FromSeconds(5);
            //options.DeathVoteExpirationTimeout = TimeSpan.FromSeconds(5);
            //options.IAmAliveTablePublishTimeout = TimeSpan.FromSeconds(3);
        })
            .Configure<SiloOptions>(options => options.SiloName = endpointAddress.ToString())
            .Configure<EndpointOptions>(options =>
            {
                options.AdvertisedIPAddress = endpointAddress;
                options.SiloPort = siloPort;
                options.GatewayPort = gatewayPort;
                options.SiloListeningEndpoint = new IPEndPoint(IPAddress.Any, siloPort);
                options.GatewayListeningEndpoint = new IPEndPoint(IPAddress.Any, gatewayPort);
            })
            .Configure<ClusterOptions>(options =>
            {
                options.ClusterId = "ShoppingApp";
                options.ServiceId = "ShoppingAppService";
            })
            .UseAzureStorageClustering(options => options.ConfigureTableServiceClient(connectionString))
            .AddAzureTableGrainStorage("ShoppingApp",
                options => options.ConfigureTableServiceClient(connectionString));
    }
});

builder.ConfigureWebHostDefaults(webBuilder => webBuilder.UseStartup<Startup>());
await builder.Build().RunAsync();
