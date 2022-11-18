#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

ARG assemblyInformationalVersion=1.0.0

WORKDIR /work
COPY ["src", "."]
RUN dotnet restore "ShoppingApp.WebUI/ShoppingApp.WebUI.csproj"
WORKDIR "/work/ShoppingApp.WebUI"
RUN dotnet build "ShoppingApp.WebUI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ShoppingApp.WebUI.csproj" -c Release -o /app/publish /p:UseAppHost=false /p:InformationalVersion=$assemblyInformationalVersion

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ShoppingApp.WebUI.dll"]