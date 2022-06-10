using Orleans;
using ShoppingApp.Abstractions;

namespace ShoppingApp.WebUI.Services;

public sealed class InventoryService : BaseClusterService
{
    public InventoryService(
        IHttpContextAccessor httpContextAccessor, IClusterClient client) :
        base(httpContextAccessor, client)
    {
    }

    public async Task<HashSet<ProductDetails>> GetAllProductsAsync()
    {
        var getAllProductsTasks = Enum.GetValues<ProductCategory>()
            .Select(category =>
                Client.GetGrain<IInventoryGrain>(category.ToString()))
            .Select(grain => grain.GetAllProductsAsync())
            .ToList();

        var allProducts = await Task.WhenAll(getAllProductsTasks);

        return new HashSet<ProductDetails>(allProducts.SelectMany(products => products));
    }
}
