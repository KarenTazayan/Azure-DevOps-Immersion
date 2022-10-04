using Orleans;
using ShoppingApp.WebUI.Extensions;

namespace ShoppingApp.WebUI.Services;

public class BaseClusterService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    protected readonly IClusterClient Client;

    public BaseClusterService(
        IHttpContextAccessor httpContextAccessor, IClusterClient client) =>
        (_httpContextAccessor, Client) = (httpContextAccessor, client);

    protected T TryUseGrain<TGrainInterface, T>(
        Func<TGrainInterface, T> useGrain, Func<T> defaultValue)
        where TGrainInterface : IGrainWithStringKey =>
         TryUseGrain(
             useGrain,
             _httpContextAccessor.TryGetUserId(),
             defaultValue);

    protected T TryUseGrain<TGrainInterface, T>(
        Func<TGrainInterface, T> useGrain,
        string? key,
        Func<T> defaultValue)
        where TGrainInterface : IGrainWithStringKey =>
        key is { Length: > 0 } primaryKey
            ? useGrain.Invoke(Client.GetGrain<TGrainInterface>(primaryKey))
            : defaultValue.Invoke();
}
