using Orleans;
using Orleans.Runtime;
using ShoppingApp.Abstractions;
using ShoppingApp.Abstractions.Configuration;

namespace ShoppingApp.SiloHost;

public sealed class SeedProductStoreTask : IStartupTask
{
    private readonly IGrainFactory _grainFactory;

    public SeedProductStoreTask(IGrainFactory grainFactory) =>
        _grainFactory = grainFactory;

    async Task IStartupTask.Execute(CancellationToken cancellationToken)
    {
        var globalStartupGrain = _grainFactory.GetGrain<IGlobalStartupGrain>(nameof(IGlobalStartupGrain));
        if (await globalStartupGrain.IsProductStoreInitialized()) return;

        var faker = new ProductDetails().GetBogusFaker();

        foreach (var product in faker.GenerateLazy(1000))
        {
            var productGrain = _grainFactory.GetGrain<IProductGrain>(product.Id);
            await productGrain.CreateOrUpdateProductAsync(product);
        }

        await globalStartupGrain.CompleteProductStoreInitialization();
    }
}