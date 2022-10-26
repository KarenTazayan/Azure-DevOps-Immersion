#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["nuget.config", "."]
COPY ["src/ShoppingApp.WebUI/ShoppingApp.WebUI.csproj", "src/ShoppingApp.WebUI/"]
COPY ["src/ShoppingApp.Abstractions/ShoppingApp.Abstractions.csproj", "src/ShoppingApp.Abstractions/"]
RUN dotnet restore "src/ShoppingApp.WebUI/ShoppingApp.WebUI.csproj"
COPY . .
WORKDIR "/src/src/ShoppingApp.WebUI"
RUN dotnet build "ShoppingApp.WebUI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ShoppingApp.WebUI.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ShoppingApp.WebUI.dll"]