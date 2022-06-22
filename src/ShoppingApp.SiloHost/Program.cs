using Orleans.Configuration;
using Orleans.Hosting;
using ShoppingApp.Grains;
using ShoppingApp.SiloHost;
using ShoppingApp.SiloHost.MicrosoftSqlServer;
using System.Net;

var builder = Host.CreateDefaultBuilder(args);

builder.UseOrleans((context, siloBuilder) =>
{
    if (context.HostingEnvironment.IsDevelopment())
    {
        siloBuilder.UseLocalhostClustering()
            .AddMemoryGrainStorage(PersistentStorageConfig.AzureSqlName)
            .AddMemoryGrainStorage(PersistentStorageConfig.AzureStorageName);
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

        var azureSqlConnectionString = context.Configuration["AZURE_SQL_CONNECTION_STRING"];
        var connectionString = context.Configuration["AZURE_STORAGE_CONNECTION_STRING"];

        var sqlDatabaseInitializer = new SqlDatabaseInitializer(azureSqlConnectionString);
        sqlDatabaseInitializer.Run();

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
            .AddAzureTableGrainStorage(PersistentStorageConfig.AzureStorageName,
                options => options.ConfigureTableServiceClient(connectionString))
            .AddAdoNetGrainStorage(PersistentStorageConfig.AzureSqlName, options =>
        {
            options.Invariant = "System.Data.SqlClient";
            options.ConnectionString = azureSqlConnectionString;
            options.UseJsonFormat = true;
        });
    }

    siloBuilder.AddStartupTask<SeedProductStoreTask>();
});

builder.ConfigureWebHostDefaults(webBuilder => webBuilder.UseStartup<Startup>());
await builder.Build().RunAsync();