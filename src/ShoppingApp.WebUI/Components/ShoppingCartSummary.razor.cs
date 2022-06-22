using Microsoft.AspNetCore.Components;
using ShoppingApp.Abstractions;

namespace ShoppingApp.WebUI.Components;

public partial class ShoppingCartSummary
{
    private string TotalCost => Items?.Sum(x => x.TotalPrice).ToString("C2") ?? "$0.00";

    [Parameter, EditorRequired]
    public HashSet<CartItem>? Items { get; set; }
}