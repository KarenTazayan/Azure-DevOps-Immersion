﻿using Orleans;
namespace ShoppingApp.Abstractions;

public interface IInventoryGrain : IGrainWithStringKey
{    
    Task<HashSet<ProductDetails>> GetAllProductsAsync();
    
    Task AddOrUpdateProductAsync(ProductDetails productDetails);
    
    Task RemoveProductAsync(string productId);
}
