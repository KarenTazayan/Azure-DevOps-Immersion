using IdentityModel.Client;
using ShoppingApp.Tests.Configuration;

namespace ShoppingApp.Tests;

public class TestBase
{
    private readonly HttpClient _identityServer4Client;

    protected TestBase()
    {
        var identityServer4 = TestIdentityServer4Builder.StartNew();
        _identityServer4Client = identityServer4.CreateClient();

        var discoveryResponse = _identityServer4Client.GetDiscoveryDocumentAsync().Result;

        TokenEndpoint = discoveryResponse.TokenEndpoint;

    }

    public string TokenEndpoint { get; set; }

    protected async Task<string> RequestClientCredentialsTokenAsync(string clientId, string clientSecret,
        string scope)
    {
        var response = await _identityServer4Client.RequestClientCredentialsTokenAsync(
            new ClientCredentialsTokenRequest()
            {
                Address = TokenEndpoint,
                Scope = scope,
                ClientId = clientId,
                ClientSecret = clientSecret
            });

        return response.AccessToken;
    }
}