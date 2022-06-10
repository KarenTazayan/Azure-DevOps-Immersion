using System.IdentityModel.Tokens.Jwt;
using Xunit;

namespace ShoppingApp.Tests;

public class TokenVerificationTests : TestBase
{
    [Theory]
    [InlineData("WebClient", "Secret", "Api1")]
    public async Task VerifyThatAccessTokenCanBeRetrievedFromTheEndpoint(string clientId,
        string clientSecret, string scope)
    {
        // Arrange
        var accessToken = await RequestClientCredentialsTokenAsync(clientId, clientSecret, scope);

        // Act
        // Assert
        Assert.True(!string.IsNullOrWhiteSpace(accessToken));
    }

    [Theory]
    [InlineData("WebClient", "BadSecret", "Api1")]
    public async Task WithAnInvalidCredentialsAccessTokenCanNotBeRetrievedFromTheEndpoint(string clientId,
        string clientSecret, string scope)
    {
        // Arrange
        var accessToken = await RequestClientCredentialsTokenAsync(clientId, clientSecret, scope);

        // Act
        // Assert
        Assert.True(accessToken == null);
    }

    [Theory]
    [InlineData("WebClient", "Secret", "Api1")]
    public async Task VerifyThatAccessTokenHasTheValidIssuer(string clientId,
        string clientSecret, string scope)
    {
        // Arrange
        var accessToken = await RequestClientCredentialsTokenAsync(clientId, clientSecret, scope);

        // Act

        var jwtTokenHandler = new JwtSecurityTokenHandler();
        var decodedToken = jwtTokenHandler.ReadJwtToken(accessToken);

        // Assert
        Assert.True(decodedToken.Issuer.Equals("http://localhost:5001"));
    }
}
