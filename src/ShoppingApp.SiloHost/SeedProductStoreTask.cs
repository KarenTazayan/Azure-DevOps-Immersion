using Bogus;
using Orleans;
using Orleans.Runtime;
using ShoppingApp.Abstractions;

namespace ShoppingApp.SiloHost;

public sealed class SeedProductStoreTask : IStartupTask
{
    private readonly IGrainFactory _grainFactory;

    public SeedProductStoreTask(IGrainFactory grainFactory) =>
        _grainFactory = grainFactory;

    async Task IStartupTask.Execute(CancellationToken cancellationToken)
    {
        var faker = new ProductDetails().GetBogusFaker();

        foreach (var product in faker.GenerateLazy(50))
        {
            var productGrain = _grainFactory.GetGrain<IProductGrain>(product.Id);
            await productGrain.CreateOrUpdateProductAsync(product);
        }
    }
}

internal static class ProductDetailsExtensions
{
    internal static Faker<ProductDetails> GetBogusFaker(this ProductDetails productDetails) =>
        new Faker<ProductDetails>()
            .StrictMode(true)
            .RuleFor(p => p.Id, (f, p) => f.Random.Number(1, 100_000).ToString())
            .RuleFor(p => p.Name, (f, p) => f.Commerce.ProductName())
            .RuleFor(p => p.Description, (f, p) => f.Lorem.Sentence())
            .RuleFor(p => p.UnitPrice, (f, p) => decimal.Parse(f.Commerce.Price(max: 170)))
            .RuleFor(p => p.Quantity, (f, p) => f.Random.Number(0, 1_200))
            .RuleFor(p => p.ImageUrl, (f, p) => f.Image.PicsumUrl())
            .RuleFor(p => p.Category, (f, p) => f.PickRandom<ProductCategory>())
            .RuleFor(p => p.DetailsUrl, (f, p) => f.Internet.Url());

    internal static bool MatchesFilter(this ProductDetails product, string? filter)
    {
        if (filter is null or { Length: 0 })
        {
            return true;
        }

        if (product is not null)
        {
            return product.Name.Contains(filter, StringComparison.OrdinalIgnoreCase)
                   || product.Description.Contains(filter, StringComparison.OrdinalIgnoreCase);
        }

        return false;
    }
}