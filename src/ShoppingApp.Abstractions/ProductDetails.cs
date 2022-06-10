namespace ShoppingApp.Abstractions;

[Serializable, Immutable]
public sealed record ProductDetails
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public ProductCategory Category { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public string DetailsUrl { get; set; } = null!;
    public string ImageUrl { get; set; } = null!;

    [JsonIgnore]
    public decimal TotalPrice => Math.Round(Quantity * UnitPrice, 2);
}