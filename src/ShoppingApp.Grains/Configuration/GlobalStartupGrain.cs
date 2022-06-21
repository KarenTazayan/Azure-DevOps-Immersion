using JetBrains.Annotations;
using Orleans;
using Orleans.Runtime;
using ShoppingApp.Abstractions.Configuration;

namespace ShoppingApp.Grains.Configuration;

[UsedImplicitly]
public class GlobalStartupGrain : Grain, IGlobalStartupGrain
{
    private readonly IPersistentState<bool> _isProductStoreInitialized;

    public GlobalStartupGrain(
        [PersistentState(stateName: "GlobalStartup", storageName: PersistentStorageConfig.AzureSqlName)]
        IPersistentState<bool> state) => _isProductStoreInitialized = state;

    public Task<bool> IsProductStoreInitialized()
    {
        return Task.FromResult(_isProductStoreInitialized.State);
    }

    public async Task CompleteProductStoreInitialization()
    {
        _isProductStoreInitialized.State = true;
        await _isProductStoreInitialized.WriteStateAsync();
    }
}